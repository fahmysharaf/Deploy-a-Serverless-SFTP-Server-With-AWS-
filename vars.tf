variable "name" {
  default     = "serverlessftp"
  description = "The name of the stack. Used to create unique resources."
}

variable "nlb-subnet-ids" {
  default     = ["subnet-abcd1234", "subnet-dcba4321"]
  description = "The ids of the subnets where the NLB will be created in."
  type        = list(string)
}

variable "region" {
  default     = "us-east-1"
  description = "The AWS region."
}

variable "subnet-ids" {
  default     = ["subnet-abcd1234", "subnet-dcba4321"]
  description = "The ids of the subnets where the VPC endpoint will be created in."
  type        = list(string)
}

variable "vpc-id" {
  default     = "vpc-abcd1234"
  description = "The id of the VPC to create the SFTP endpoint in."
}
