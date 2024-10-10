
data "oci_core_cpe_device_shapes" "oci-ipsec-cpe-device-shapes" {
}

data "oci_core_cpe_device_shape" "oci-ipsec-cpe-device-shape" {
  # TODO index 0 is for LibreSwan, Filter by regex? Libre*?
  cpe_device_shape_id = data.oci_core_cpe_device_shapes.oci-ipsec-cpe-device-shapes.cpe_device_shapes[0].cpe_device_shape_id
}

// Create IPSEC CPE for OCI VCN
resource "oci_core_cpe" "oci-ipsec-cpe" {
  compartment_id      = var.compartment_ocid
  display_name        = "oci-ipsec-cpe"
  ip_address          = oci_core_instance.onprem-vcn-libreswan-instance.public_ip
  cpe_device_shape_id = data.oci_core_cpe_device_shape.oci-ipsec-cpe-device-shape.id
}
// Cretae IPSEC connection for OCI VCN
resource "oci_core_ipsec" "oci-ipsec-connection" {
  compartment_id = var.compartment_ocid
  cpe_id         = oci_core_cpe.oci-ipsec-cpe.id
  drg_id         = oci_core_drg.oci-vcn-drg.id
  static_routes  = [var.onprem_vcn_cidr_block]

  cpe_local_identifier      = oci_core_instance.onprem-vcn-libreswan-instance.public_ip
  cpe_local_identifier_type = "IP_ADDRESS"
  display_name              = "oci-ipsec-connection"
}

//Grab data for IPSEC connection for OCI VCN tunnels
data "oci_core_ipsec_connections" "oci-ipsec-connections" {
  compartment_id = var.compartment_ocid
  cpe_id         = oci_core_cpe.oci-ipsec-cpe.id
  drg_id         = oci_core_drg.oci-vcn-drg.id
}

data "oci_core_ipsec_connection_tunnels" "oci-ipsec-connection-tunnels" {
  ipsec_id = oci_core_ipsec.oci-ipsec-connection.id
}

data "oci_core_ipsec_connection_tunnel" "oci-ipsec-connection-tunnel-a" {
  ipsec_id  = oci_core_ipsec.oci-ipsec-connection.id
  tunnel_id = data.oci_core_ipsec_connection_tunnels.oci-ipsec-connection-tunnels.ip_sec_connection_tunnels[0].id
}

data "oci_core_ipsec_connection_tunnel" "oci-ipsec-connection-tunnel-b" {
  ipsec_id  = oci_core_ipsec.oci-ipsec-connection.id
  tunnel_id = data.oci_core_ipsec_connection_tunnels.oci-ipsec-connection-tunnels.ip_sec_connection_tunnels[1].id
}

// Create IPSEC connection management for OCI VCN tunnel a
resource "oci_core_ipsec_connection_tunnel_management" "oci-ipsec-connection-tunnel-management-a" {
  ipsec_id   = oci_core_ipsec.oci-ipsec-connection.id
  tunnel_id  = data.oci_core_ipsec_connection_tunnels.oci-ipsec-connection-tunnels.ip_sec_connection_tunnels[0].id
  depends_on = [data.oci_core_ipsec_connections.oci-ipsec-connections]

  bgp_session_info {
    customer_bgp_asn      = var.onprem_bgp_asn
    customer_interface_ip = "${var.bgp_onprem_tunnel_a_ip}/30"
    oracle_interface_ip   = "${var.bgp_oci_tunnel_a_ip}/30"
  }

  display_name  = "oci-ipsec-tunnel-a"
  routing       = "BGP"
  shared_secret = var.psk_tunnel_a
  ike_version   = "V2"
}

// Create IPSEC connection management for OCI VCN tunnel b
resource "oci_core_ipsec_connection_tunnel_management" "oci-ipsec-connection-tunnel-management-b" {
  ipsec_id   = oci_core_ipsec.oci-ipsec-connection.id
  tunnel_id  = data.oci_core_ipsec_connection_tunnels.oci-ipsec-connection-tunnels.ip_sec_connection_tunnels[1].id
  depends_on = [data.oci_core_ipsec_connections.oci-ipsec-connections]

  bgp_session_info {
    customer_bgp_asn      = var.onprem_bgp_asn
    customer_interface_ip = "${var.bgp_onprem_tunnel_b_ip}/30"
    oracle_interface_ip   = "${var.bgp_oci_tunnel_b_ip}/30"
  }

  display_name  = "oci-ipsec-tunnel-b"
  routing       = "BGP"
  shared_secret = var.psk_tunnel_b
  ike_version   = "V2"
}

resource "oci_core_drg_attachment_management" "oci-vcn-drg-ipsec-attachment-tunnel-a" {
  attachment_type    = "IPSEC_TUNNEL"
  compartment_id     = var.compartment_ocid
  network_id         = data.oci_core_ipsec_connection_tunnels.oci-ipsec-connection-tunnels.ip_sec_connection_tunnels.0.id
  drg_id             = oci_core_drg.oci-vcn-drg.id
  display_name       = "oci-vcn-drg-ipsec-attachment-tunnel-a"
  drg_route_table_id = oci_core_drg_route_table.oci-vcn-drg-route-table.id
}

resource "oci_core_drg_attachment_management" "oci-vcn-drg-ipsec-attachment-tunnel-b" {
  attachment_type    = "IPSEC_TUNNEL"
  compartment_id     = var.compartment_ocid
  network_id         = data.oci_core_ipsec_connection_tunnels.oci-ipsec-connection-tunnels.ip_sec_connection_tunnels.1.id
  drg_id             = oci_core_drg.oci-vcn-drg.id
  display_name       = "oci-vcn-drg-ipsec-attachment-tunnel-b"
  drg_route_table_id = oci_core_drg_route_table.oci-vcn-drg-route-table.id
}

// Grab data for IPSEC tunnel routes for OCI VCN
data "oci_core_ipsec_connection_tunnel_routes" "oci-ipsec-connection-tunnel-a-routes" {
  ipsec_id   = oci_core_ipsec.oci-ipsec-connection.id
  tunnel_id  = data.oci_core_ipsec_connection_tunnels.oci-ipsec-connection-tunnels.ip_sec_connection_tunnels.0.id
  advertiser = "CUSTOMER"
}

data "oci_core_ipsec_connection_tunnel_routes" "oci-ipsec-connection-tunnel-b-routes" {
  ipsec_id   = oci_core_ipsec.oci-ipsec-connection.id
  tunnel_id  = data.oci_core_ipsec_connection_tunnels.oci-ipsec-connection-tunnels.ip_sec_connection_tunnels.1.id
  advertiser = "CUSTOMER"
}


resource "oci_logging_log_group" "ipsec_log_group" {
  compartment_id = var.compartment_ocid
  display_name   = "ipsec_log_group"
}

resource "oci_logging_log" "vpn_log" {
  display_name = "vpn_log"
  log_group_id = oci_logging_log_group.ipsec_log_group.id
  log_type     = "SERVICE"
  configuration {
    source {
      category    = "read"
      resource    = oci_core_ipsec.oci-ipsec-connection.id
      service     = "oci_c3_vpn"
      source_type = "OCISERVICE"
    }
  }
  is_enabled = false # TODO
  
}
