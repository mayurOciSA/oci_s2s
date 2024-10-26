# common variables for both OCI environment and on-prem simulation

variable "tenancy_ocid" {
  description = "Your Tenancy OCID"
  type        = string
}

variable "compartment_ocid" {
  description = "OCI compartment where resources are to be created & maintained, for both on-prem simulation and OCI"
  type        = string
}

variable "instance_shape" {
  default     = "VM.Standard.A1.Flex"
  description = "Shape for instances, same for both on-prem simulation and OCI"
  type        = string
}

variable "instance_ocpus" {
  default     = 3
  description = "OCPU count for instances, same for both: VTAP source nodes, VTAP sink nodes"
  type        = number
}

variable "instance_memory_in_gbs" {
  default     = 12
  description = "RAM size for instances, same for all: VTAP source nodes, VTAP sink nodes"
  type        = number
}

variable "ssh_public_key" {
  description = "Contents of SSH public key file. Used to login to instance with corresponding private key. Will be used for all VMs on-prem and OCI"
  type        = string
}

variable "ssh_private_key_local_path" {
  description = "Local Path of SSH private key file. Will be used for all VMs on-prem and OCI. Required for automation for setup LibreSwan and FRR on CPE VM of omprem simulation."
  type        = string
}


# OCI related 
variable "oci_region" {
  description = "OCI region where you Site to Site IPSec, CPE(logical) and DRG reside. Full name like us-ashburn-1. Can be same as on_prem_simulation_region"
  type        = string
  default = "us-phoenix-1"
}
variable "oci_vcn_cidr_block" {
  type    = string
  default = "12.0.0.0/24"
}
variable "oci_subnet_cidr" {
  type    = string
  default = "12.0.0.0/25"
}

#OCI related but specifically for ipsec and CPE
variable "onprem_bgp_asn" {
  default = "65001"
}

variable "bgp_onprem_router_id" {
  type    = string
  default = "11.11.11.100"
}
## First Tunnel
variable "bgp_onprem_tunnel_a_ip" {
  type    = string
  default = "11.11.11.101"
}
variable "bgp_oci_tunnel_a_ip" {
  type    = string
  default = "11.11.11.102"
}
variable "psk_tunnel_a" {
  type    = string
  default = "20992099"
}

## Second Tunnel
variable "bgp_onprem_tunnel_b_ip" {
  type    = string
  default = "11.11.11.105"
}
variable "bgp_oci_tunnel_b_ip" {
  type    = string
  default = "11.11.11.106"
}
variable "psk_tunnel_b" {
  type    = string
  default = "30993099"
}

# On-prem simulation related
variable "on_prem_simulation_region" {
  description = "OCI region for on-prem simulation where CPE resides. Full name like us-ashburn-1, can be same as oci-region"
  type        = string
  default = "us-sanjose-1"
}
variable "onprem_vcn_cidr_block" {
  type    = string
  default = "10.0.0.0/24"
}
variable "onprem_subnet_cidr" {
  type    = string
  default = "10.0.0.0/25"
}
variable "onprem_instance_user" {
  description = "Oracle Linux user for onprem instances, including Libreswan+FRR CPE"
  default     = "opc"
}

