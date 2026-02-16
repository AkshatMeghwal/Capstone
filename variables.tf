variable "private_key_path" {



  type    = string



  default = "./Neeharika_Terraform.pem"



}







variable "key_name" {



  type        = string



  description = "EC2 key pair name (must exist in AWS unless created via aws_key_pair)"



  default     = "Neeharika_Terraform"



}







variable "region" {



  type        = string



  description = "AWS region"



  default     = "eu-west-1"



}







variable "network_address_space" {



  description = "VPC CIDR"



  default     = "10.1.0.0/16"



}







variable "instance_count" {



  default = 2



}







variable "subnet_count" {



  default = 2



}







variable "instance_username" {



  default = "ec2-user"



}




