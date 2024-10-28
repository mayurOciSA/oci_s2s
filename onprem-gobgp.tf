# Create compute instance acting as bgp speaker of gobgp
resource "oci_core_instance" "onprem-vcn-gobgp" {
  provider = oci.on_prem_simulation

  availability_domain = data.oci_identity_availability_domain.ad_onprem.name
  compartment_id      = var.compartment_ocid
  display_name        = "onprem-gobgp-instance"
  shape               = var.instance_shape

  create_vnic_details {
    subnet_id                 = oci_core_subnet.onprem-vcn-subnet.id
    display_name              = "Primaryvnic"
    assign_public_ip          = true
    assign_private_dns_record = true
    hostname_label            = "onprem-gobgp"
    skip_source_dest_check    = true # Must be true, for this node to act as CPE/FRR Router
  }
  shape_config {
    memory_in_gbs             = var.instance_memory_in_gbs
    ocpus                     = var.instance_ocpus
  }
  
  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.oracle_linux_images_onprem.images[0].id
  }
  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }
}

# Gets a list of VNIC attachments on the instance
data "oci_core_vnic_attachments" "onprem-vcn-gobgp-vnics" {
  provider = oci.on_prem_simulation

  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domain.ad_onprem.name
  instance_id         = oci_core_instance.onprem-vcn-gobgp.id
}

# Gets the OCID of the first (default) VNIC
data "oci_core_vnic" "onprem-vcn-gobgp-vnic" {
  provider = oci.on_prem_simulation
  vnic_id = data.oci_core_vnic_attachments.onprem-vcn-gobgp-vnics.vnic_attachments[0]["vnic_id"]
}

// List Private IPs
data "oci_core_private_ips" "onprem-vcn-gobgp-ip-datasource" {
  provider = oci.on_prem_simulation
  vnic_id = data.oci_core_vnic.onprem-vcn-gobgp-vnic.id
}

# Export Terraform variable values for gobgp ansible playbook
resource "local_file" "ansible-vars-gobgp" {
  content  = <<-DOC
    # Ansible vars file containing variable values from Terraform.
    cpe_or_nva_pvt_ip: ${oci_core_instance.onprem-vcn-libreswan-instance.private_ip}
    cpe_bgp_asn: ${var.onprem_bgp_asn}

    DOC
  filename = "./gobgp/vars.yml"
}

resource "null_resource" "ansible-gobgp-playbook" {
  depends_on = [local_file.ansible-vars-gobgp]

  // Ansible integration
  provisioner "remote-exec" {
    inline = ["echo About to run Ansible on gobgp! Waiting!"]

    connection {
      host        = oci_core_instance.onprem-vcn-libreswan-instance.public_ip
      type        = "ssh"
      user        = var.onprem_instance_user
      private_key = file("${var.ssh_private_key_local_path}")
    }
  }

  provisioner "local-exec" {
    command = "sleep 30; ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.onprem_instance_user} -i '${oci_core_instance.onprem-vcn-gobgp.public_ip},' --private-key ${var.ssh_private_key_local_path} ./gobgp/gobgp.ansible.yml"
  }
}