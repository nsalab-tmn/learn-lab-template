variable "instance_id" {
  type    = string
  default = "user01_1111" # = userMaterialId
}

variable "tp_name" {
  type    = string
  default = "smpl_lab" # = materialId
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
