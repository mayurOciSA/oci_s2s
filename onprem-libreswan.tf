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

resource "null_resource" "ansible-cpe-playbook" {
  depends_on = [local_file.ansible-vars-cpe]

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

# Export Terraform variable values to an ./ansible/vars.yml file
resource "local_file" "ansible-vars-cpe" {
  content  = <<-DOC
    # Ansible vars file containing variable values from Terraform.

    # headends have public IPs
    cpe_public_ipv4: ${oci_core_instance.onprem-vcn-libreswan-instance.public_ip}
    oracle_headend_tun_a: ${data.oci_core_ipsec_connection_tunnels.oci-ipsec-connection-tunnels.ip_sec_connection_tunnels[0].vpn_ip}
    oracle_headend_tun_b: ${data.oci_core_ipsec_connection_tunnels.oci-ipsec-connection-tunnels.ip_sec_connection_tunnels[1].vpn_ip}

    cpe_local_private_ip: ${oci_core_instance.onprem-vcn-libreswan-instance.private_ip}

    psk_tun_a: ${var.psk_tunnel_a}
    psk_tun_b: ${var.psk_tunnel_b}

    vti_a: "vti0"
    vti_b: "vti1" 

    # all vti-s have are /30 adddress
    vti_a_local_ip: ${var.bgp_onprem_tunnel_a_ip}
    bgp_router_id: ${var.bgp_onprem_router_id} # TODO is bgp router-id arbitrary? 
    vti_a_remote_ip: ${var.bgp_oci_tunnel_a_ip}

    vti_b_local_ip: ${var.bgp_onprem_tunnel_b_ip}
    vti_b_remote_ip: ${var.bgp_oci_tunnel_b_ip}

    bgp_asn_local: ${var.onprem_bgp_asn}
    bgp_asn_remote: 31898  # Oracle's ASN, DNT dare to change
    cpe_onprem_vcn_cidr: ${var.onprem_vcn_cidr_block}

    remote_oci_vcn_cidr: ${var.oci_vcn_cidr_block} # TODO why is it unused? as BGP will advertise anyways?
    gobgp_bgp_speaker_ip: ${oci_core_instance.onprem-vcn-gobgp.private_ip}
    
    DOC
  filename = "./ansible/vars.yml"
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
