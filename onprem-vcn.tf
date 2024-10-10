# Create simualted on-prem data center using isolated OCI cloud VCN
resource "oci_core_vcn" "onprem-vcn" {
  provider       = oci.on_prem_simulation
  cidr_blocks    = [var.onprem_vcn_cidr_block]
  dns_label      = "onpremvcn"
  compartment_id = var.compartment_ocid
  display_name   = "onprem-vcn"
}

# Create public subnet for onprem VCN, this will contain LibreSwan CPE
resource "oci_core_subnet" "onprem-vcn-subnet" {
  provider          = oci.on_prem_simulation
  cidr_block        = var.onprem_subnet_cidr
  display_name      = "onprem-vcn-subnet"
  dns_label         = "onpremvcnsubnet"
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.onprem-vcn.id
  security_list_ids = [oci_core_vcn.onprem-vcn.default_security_list_id]
  route_table_id    = oci_core_vcn.onprem-vcn.default_route_table_id
  dhcp_options_id   = oci_core_vcn.onprem-vcn.default_dhcp_options_id
}

# Add rule to security list for public subnet for onprem VCN
resource "oci_core_default_security_list" "onprem-vcn-subnet-security-list" {
  provider = oci.on_prem_simulation

  compartment_id             = var.compartment_ocid
  manage_default_resource_id = oci_core_vcn.onprem-vcn.default_security_list_id

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  ingress_security_rules {
    protocol = "all"
    source   = "0.0.0.0/0"
  }
}

# Grab default route table data for IGW Route rules for VCN
data "oci_core_vcn" "onprem-default-route-table-id" {
  provider = oci.on_prem_simulation

  vcn_id = oci_core_vcn.onprem-vcn.id
}

# Create IGW for onprem VCN
resource "oci_core_internet_gateway" "onprem-internet-gateway" {
  provider = oci.on_prem_simulation

  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.onprem-vcn.id
  display_name   = "onprem-igw"
}

// Create IGW and Private route rules for onprem VCN
resource "oci_core_default_route_table" "onprem-default-route-table" {
  provider = oci.on_prem_simulation

  depends_on                 = [oci_core_instance.onprem-vcn-libreswan-instance]
  compartment_id             = var.compartment_ocid
  manage_default_resource_id = data.oci_core_vcn.onprem-default-route-table-id.default_route_table_id

  route_rules {
    network_entity_id = oci_core_internet_gateway.onprem-internet-gateway.id
    destination       = "0.0.0.0/0"
  }

  route_rules {
    network_entity_id = data.oci_core_private_ips.onprem-vcn-libreswan-instance-vnic-private-ip-id.private_ips[0]["id"]
    destination       = var.oci_vcn_cidr_block
  }
}

data "oci_core_private_ips" "onprem-vcn-libreswan-instance-vnic-private-ip-id" {
  provider = oci.on_prem_simulation

  ip_address = oci_core_instance.onprem-vcn-libreswan-instance.private_ip
  subnet_id  = oci_core_subnet.onprem-vcn-subnet.id
}
