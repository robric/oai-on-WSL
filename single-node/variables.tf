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