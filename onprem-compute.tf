# Create compute instance for onprem VCN
resource "oci_core_instance" "onprem-vcn-instance" {
  provider = oci.on_prem_simulation

  availability_domain = data.oci_identity_availability_domain.ad_onprem.name
  compartment_id      = var.compartment_ocid
  display_name        = "onprem-vcn-instance"
  shape               = var.instance_shape

  create_vnic_details {
    subnet_id                 = oci_core_subnet.onprem-vcn-subnet.id
    display_name              = "Primaryvnic"
    assign_public_ip          = true
    assign_private_dns_record = true
    hostname_label            = "onprem-vcn-subnet-vnic"
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
data "oci_core_vnic_attachments" "onprem-vcn-instance-vnics" {
  provider = oci.on_prem_simulation

  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domain.ad_onprem.name
  instance_id         = oci_core_instance.onprem-vcn-instance.id
}

# Gets the OCID of the first (default) VNIC
data "oci_core_vnic" "onprem-vcn-instance-vnic" {
  provider = oci.on_prem_simulation

  vnic_id = data.oci_core_vnic_attachments.onprem-vcn-instance-vnics.vnic_attachments[0]["vnic_id"]
}

// List Private IPs
data "oci_core_private_ips" "onprem-vcn-private-ip-datasource" {
  provider = oci.on_prem_simulation

  vnic_id = data.oci_core_vnic.onprem-vcn-instance-vnic.id
}
