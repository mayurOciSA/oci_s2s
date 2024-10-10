# Create Libreswan Instance for OnPrem VCN
resource "oci_core_instance" "onprem-vcn-libreswan-instance" {
  provider = oci.on_prem_simulation

  availability_domain = data.oci_identity_availability_domain.ad_onprem.name
  compartment_id      = var.compartment_ocid
  display_name        = "onprem_cpe"
  shape               = var.instance_shape

  create_vnic_details {
    subnet_id                 = oci_core_subnet.onprem-vcn-subnet.id
    display_name              = "primary_vnic"
    assign_public_ip          = true
    assign_private_dns_record = true
    hostname_label            = "cpe"
    skip_source_dest_check    = true
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

resource "null_resource" "execute-ansible-playbook" {
  depends_on = [local_file.ansible-vars-generate]

  // Ansible integration
  provisioner "remote-exec" {
    inline = ["echo About to run Ansible on LIBRESWAN and waiting!"]

    connection {
      host        = oci_core_instance.onprem-vcn-libreswan-instance.public_ip
      type        = "ssh"
      user        = var.onprem_instance_user
      private_key = file("${var.ssh_private_key_local_path}")
    }
  }

  provisioner "local-exec" {
    command = "sleep 30; ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.onprem_instance_user} -i '${oci_core_instance.onprem-vcn-libreswan-instance.public_ip},' --private-key ${var.ssh_private_key_local_path} ./ansible/libreswan.frr.ansible.try.yml"
  }
}

// Gets a list of VNIC attachments on the instance
data "oci_core_vnic_attachments" "onprem-vcn-libreswan-instance-vnics" {
  provider = oci.on_prem_simulation

  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domain.ad_onprem.name
  instance_id         = oci_core_instance.onprem-vcn-libreswan-instance.id
}

// Gets the OCID of the first (default) VNIC
data "oci_core_vnic" "onprem-vcn-libreswan-instance-vnic" {
  provider = oci.on_prem_simulation
  vnic_id = data.oci_core_vnic_attachments.onprem-vcn-libreswan-instance-vnics.vnic_attachments[0]["vnic_id"]
}

// List Private IPs
data "oci_core_private_ips" "onprem-vcn-libreswan-instance-private-ip-datasource" {
  provider = oci.on_prem_simulation
  vnic_id = data.oci_core_vnic.onprem-vcn-instance-vnic.id
}


data "oci_core_images" "oracle_linux_images_onprem" {
  provider                 = oci.on_prem_simulation
  compartment_id           = var.tenancy_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "9" # Dnt Change OL9 has Python 9 required by Ansible version 2.17.4
  shape                    = var.instance_shape #"VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"

}

# Grab AD data for OCI VCN
data "oci_identity_availability_domain" "ad_onprem" {
  provider       = oci.on_prem_simulation
  compartment_id = var.tenancy_ocid
  ad_number      = 1
}
