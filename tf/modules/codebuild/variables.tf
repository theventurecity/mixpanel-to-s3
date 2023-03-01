variable "project_name" {
  type = string
}

variable "role_arn" {
  type = string
}

variable "buildspec" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "target_directory" {
  type = string
}

variable "default_tags" {
  type = map(string)
}


variable "privileged_mode" {
  type    = string
  default = false
}

variable "build_timeout" {
  type    = number
  default = 10
}

variable "container_type" {
  type    = string
  default = "BUILD_GENERAL1_SMALL"
}

variable "image" {
  type    = string
  default = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
}

variable "ecs_metadata_ip" {
  type    = string
  default = "169.254.170.2"
}

variable "subnet_ids" {
  type    = list(string)
}

variable "vpc_id" {
  type    = string
}

variable "env" {
  type    = string
}
