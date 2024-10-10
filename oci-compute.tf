resource "oci_core_instance" "oci-vcn-instance" {
  availability_domain = data.oci_identity_availability_domain.ad_oci.name
  compartment_id      = var.compartment_ocid
  display_name        = "oci-vcn-instance"
  shape               = var.instance_shape

  create_vnic_details {
    subnet_id                 = oci_core_subnet.oci-vcn-subnet.id
    display_name              = "primary_vnic"
    assign_public_ip          = true
    assign_private_dns_record = true
    hostname_label            = "vnic0"
  }
  
  shape_config {
    memory_in_gbs             = var.instance_memory_in_gbs
    ocpus                     = var.instance_ocpus
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.oracle_linux_images_oci.images[0].id
  }
  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }
}

// Gets a list of VNIC attachments on the instance
data "oci_core_vnic_attachments" "oci-vcn-instance-vnics" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domain.ad_oci.name
  instance_id         = oci_core_instance.oci-vcn-instance.id
}

// Gets the OCID of the first (default) VNIC
data "oci_core_vnic" "oci-vcn-instance-vnic" {
  vnic_id = data.oci_core_vnic_attachments.oci-vcn-instance-vnics.vnic_attachments[0]["vnic_id"]
}

// List Private IPs
data "oci_core_private_ips" "oci-vcn-private-ip-datasource" {
  vnic_id = data.oci_core_vnic.oci-vcn-instance-vnic.id
}

data "oci_core_images" "oracle_linux_images_oci" {
  compartment_id           = var.tenancy_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "9"
  shape                    = var.instance_shape #"VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# Grab AD data for OCI VCN
data "oci_identity_availability_domain" "ad_oci" {
  compartment_id = var.tenancy_ocid
  ad_number      = 1
}