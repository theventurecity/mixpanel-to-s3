//trigger pipeline

variable "region" {
  type = string
}

variable "region_certificate" {
  type = string
}

variable "crew" {
  type = string
}

variable "app" {
  type = string
}

variable "service" {
  type = string
}

variable "env" {
  type = string
}

variable "account_ids" {
  type = map(string)
}

variable "profiles" {
  type = map(string)
}

variable "branch" {
  type = map(string)
}
