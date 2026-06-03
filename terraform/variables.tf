# variables.tf - Variables d'entree pour la configuration Terraform

variable "region" {
  description = "Region AWS"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "ID de l'AMI (Ubuntu). A adapter selon la region."
  type        = string
  default     = "ami-0c55b159cbfafe1f0"
}

variable "instance_type" {
  description = "Type d'instance (eligible au free tier)"
  type        = string
  default     = "t2.micro"
}
