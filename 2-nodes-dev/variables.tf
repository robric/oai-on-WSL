#
# provider variables: region, names, OAI ami
# Make sure to modify generic tag name to avoid overlaps (use for vpc/subnet)
#

variable "vpc_tag_name" {
  description = "Generic VPC Tag Name used for vpc, subnet, igw"
  default = "rr-oai-dev-2-nodes"
}
variable "provider_region" {
 description = "Provider region"
 default = "us-east-1"
}
variable "server_instance_type" {
  description = "Server instance type"
  default = "t2.xlarge"
}
variable "server1_tag_name" {
  description = "Server tag name"
  default = "oai-2-nodes-5GC"
}
variable "server2_tag_name" {
  description = "Server tag name"
  default = "oai-2-nodes-RAN"
}
variable "ami_id" {
  description = "OAI-ready-to-use Ubuntu focal with minikube, oai charts+images and cRPD"
  default = "ami-04a6b9d026dee5f44"
}
#
# Credentials for ssh access to EC2 instances
#
variable "private_key_file" {
  description = "Private key file location for ssh access"
  default = "~/.ssh/rr-key-2023-2.pem"
}
variable "key_name" {
  description = "EC2 Key name"
  default = "rr-key-2023-2"
}

#
# Script for OAI deployment
#
