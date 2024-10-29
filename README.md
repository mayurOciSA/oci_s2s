# OCI Site to Site VPN with *LibreSwan* for IPSec & BGP for route advertisements with *Free Range Routing(FRR)*

## Prerequisites
1. Install Terraform
2. Install Ansible
3. Access to Oracle CLoud Infastructure
4. Basic BGP and IPSec knowledge

## Design
Please note onprem is simulated within same or another OCI region, depends on how you configure it with TF input variables. 
<kbd><img src="images/ocis2s.drawio.png?raw=true" width="1250" /></kbd>

For configuration of LibreSwan and FRR, please refer to [libreswan.frr.ansible.yml](ansible/libreswan.frr.ansible.yml). 

## How to Deploy

1. Download or clone the repo to your local machine
  ```sh
  git clone -b "ipsec+bgp" git@github.com:mayurOciSA/oci_s2s.git
  ```
1. Copy `local.example.tfvar` as local.tfvars, and update `local.tfvars` with values as suitable to your environment. The contain variable which do not have any default values and hence their values must be provided by you. Please go through [variables.tf](variables.tf). to include any additional and optional configuration variables as per your needs in local.tfvars.
2. Run Terraform
  ```sh
  terraform init
  terraform plan
  terraform apply --var-file=local.tfvars --auto-approve
  ```
3. To tear down the setup
  ```sh
  terraform destroy --var-file=local.tfvars --auto-approve
  ```

## TF Output and Testing  
After running this TF, you will have setup as shown in the above diagram.
And output on your shell similar to below that has bunch of IP addresses.

```sh
oci-ipsec-connection-tunnel-a = "129.XX.XX.XX"
oci-ipsec-connection-tunnel-b = "152.XX.XX.XX"
oci-vcn-drg-id = "ocid1.drg.oc1.us-sanjose-1........."
oci-vcn-id = "ocid1.vcn.oc1.us-sanjose-1..........."
oci-vcn-instance-private-ip = "12.0.0.34"
oci-vcn-instance-public-ip = "165.1.XX.XX"
onprem-vcn-id = "ocid1.vcn.oc1.phx.........."
onprem-vcn-instance-private-ip = "10.0.0.55"
onprem-vcn-instance-public-ip = "129.XX.XX.XX"
onprem-vcn-libreswan-instance-private-ip = "10.0.0.69"
onprem-vcn-libreswan-instance-public-ip = "129.146.XX.XX"
```

### Testing
1. SSH into the box with ip `onprem-vcn-libreswan-instance-public-ip` and try to ping ip `oci-vcn-instance-private-ip`
and try reverse too!
2. Confirm your Site to Site IPSec connection on OCI side has received the onprem CIDR `onprem_vcn_cidr_block` as set in [variables.tf](variables.tf) or whatever value you overrided it with local.tfvars. 
3. Try adding new VCN say *vcn_new* and its attachment to DRG on OCI side. CIDR for *vcn_new* should appear on FRR/onprem side CPE/router.
Confirm it with following steps,
SSH into the CPE box with ip `onprem-vcn-libreswan-instance-public-ip`
```sh
sudo bash
vtysh
sh ip route
sh bgp sum
```

## Limitation
1. This is just for POC. Please finetune as per your requrenments for production usecase.
2. In real onprem setup when you add new network to onprem OR say in this onprem simulation if you add new CIDR to your VCN, FRR will need to updated with the static route with new CIDR and FRR being the next hop. 
3. Exactely opposite of above is also true. If you add new VCN to on OCI side, FRR will get its new CIDR but it can't/won't update the route tables of subnets of VCN simulating the onprem.
   