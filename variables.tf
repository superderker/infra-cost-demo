variable "instance_type" {
  description = "EC2 instance type for the web servers"
  type        = string
  default     = "t3.micro"
}

variable "instance_count" {
  description = "Number of web servers"
  type        = number
  default     = 1
}

variable "volume_size" {
  description = "Root volume size in GB (gp3)"
  type        = number
  default     = 8
}
