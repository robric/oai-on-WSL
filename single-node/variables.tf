# provider variables
variable "provider_region" {
 description = "Provider region"
 default = "us-east-1"
}
variable "server_instance_type" {
  description = "Server instance type"
  default = "t2.xlarge"
}
variable "server_tag_name" {
  description = "Server tag name"
  default = "rr-oai-test-instance"
}
variable "ami_id" {
  description = "Canonical, Ubuntu, 22.04 LTS, amd64 jammy image build on 2023-03-25"
  default = "ami-042b6a0a42a65d9f5"
}
variable "private_key_file" {
  description = "Private key file location for ssh access"
  default = "~/.ssh/rr-key-2023-2.pem"
}
variable "key_name" {
  description = "EC2 Key name"
  default = "rr-key-2023-2"
}