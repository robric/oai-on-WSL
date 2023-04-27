#
# provider variables: region, names, OAI ami
#
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
  description = "OAI-ready-to-use Ubuntu jammy image with minikube, OAI images, helm and charts"
  default = "ami-0fb0fac0077bfb65c"
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

variable "oai_deployment_file" {
  description = "Local script to deploy OAI"
  default = "deploy-single-node.sh"
}