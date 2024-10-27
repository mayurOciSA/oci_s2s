# Export Terraform variable values to an ./ansible/vars.yml file
resource "local_file" "ansible-vars-generate" {
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
    
    DOC
  filename = "./ansible/vars.yml"
}
