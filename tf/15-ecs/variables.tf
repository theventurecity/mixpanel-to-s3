variable "env" {
  type = string
}

variable "app" {
  type = string
}

variable "service" {
  type = string
}

variable "crew" {
  type = string
}

variable "region" {
  type = string
}

variable "region_certificate" {
  type = string
}

variable "account_ids" {
  type = map(string)
}

variable "profiles" {
  type = map(string)
}

variable "account_type" {
  type = string
}

variable "branch" {
  type = map(string)
}