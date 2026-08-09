variable "instance_id" {
  type = string
}

variable "tp_name" {
  type    = string
  default = ""
}

variable "tp_learn_env" {
  type    = string
  default = ""
}

variable "tp_learn_user" {
  type    = string
  default = ""
}

variable "variant_seed" {
  type    = string
  default = "0"
}

variable "location" {
  type    = string
  default = "uksouth"
}
