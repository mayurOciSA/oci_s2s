# OCI Site to Site IPSec VPN with LibreSwan & BGP for route advertisements with Free Range Routing(FRR)

## Prerequisites
1. Install Terraform
2. Install Ansible
3. Access to Oracle CLoud Infastructure

## Design
Please note onprem is simulated within same or another OCI region.
<kbd><img src="images/ocis2s.drawio.png?raw=true" width="1250" /></kbd>


## How to Deploy

1. Download or clone the repo to your local machine
  ```sh
  git clone -b "ipsec+bgp" git@github.com:mayurOciSA/oci_s2s.git
  ```
1. Copy local.example.tfvar as local.tfvars, and update local.tfvars with values as suitable to your environment. Please go through variables.tf. Include any configuration variable as per your needs in local.tfvars .
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

## Limitation
1. This is just for POC. Please finetune for production usecase.