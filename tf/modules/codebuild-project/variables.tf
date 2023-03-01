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
  default = "BUILD_GENERAL1_LARGE"
}

variable "image" {
  type    = string
  default = "aws/codebuild/standard:5.0"
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

variable "app" {
  type    = string
}

variable "service" {
  type    = string
}

variable "region" {
  type    = string
}

variable "account_id" {
  type    = string
}

variable "env" {
  type    = string
}