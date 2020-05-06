# AWS


## Prerequisites

### Terraform CLI

```bash
brew update
brew install terraform
```

### AWS Permissions
- AmazonEC2FullAccess
- AmazonRoute53FullAccess
- AmazonVPCFullAccess


## Deploying Infrastructure

First, you'll need to clone this repo. Then, need to perform the following steps:

1. `cd aws`
1. Create [`terraform.tfvars`](/README.md#var-file) file
1. Populate [credentials](/README.md#credentials) file or env variables
1. Run terraform apply:
  ```bash
  terraform init
  terraform plan -out=codeserver.tfplan
  terraform apply codeserver.tfplan
  ```

### Var File

Copy the stub content below into a file called `terraform.tfvars` and put it in the root of this project.
These vars will be used when you run `terraform apply`.
You should fill in the stub values with the correct content.

```hcl
env_name           = "test"
region             = "us-west-1"
hosted_zone        = "test.io"
acme_registration_email = "test@test.io"
```

### Credentials

Create a `credentials.yml` file with the following contents:

```
provider "aws" {
  access_key = "YOUR_AWS_ACCESS_KEY"
  secret_key = "YOUR_AWS_SECRET_KEY"
}
```

Alternatively, populate the following environment variables before running the `terraform plan`:

```
export AWS_ACCESS_KEY_ID="anaccesskey"
export AWS_SECRET_ACCESS_KEY="asecretkey"
```

### Variables

- env_name: **(required)** An arbitrary unique name for namespacing resources
- region: **(required)** Region you want to deploy your resources to
- hosted_zone: **(required)** Domain *already* managed by Route53. 
- acme_registration_email: **(required)** email address used for acme cert registration

### Outputs

- ssh_private_key: ssh private key if needing to log into code server
- code_server_password: Password to login to code server
- public_ip: public IP for dns address below
- dns_address: address that you can access code server instance

#### Getting code server password
```bash
  output --json | jq -r .code_server_password.value
  ```

## Tearing down environment

```bash
terraform destroy
```
