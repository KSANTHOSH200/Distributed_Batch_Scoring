variable "project_name"     { type = string  default = "batch-scorer" }
variable "aws_region"       { type = string  default = "us-east-1" }
variable "cluster_version"  { type = string  default = "1.30" }
variable "allowed_ips"      { type = list(string) default = ["0.0.0.0/0"] }
variable "image_tag"        { type = string  default = "latest" }