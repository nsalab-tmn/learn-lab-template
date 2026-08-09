# learn-lab-deploy passes these -var flags to every playbook (declare the ones you use).
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
  default = "local-dev"
}

variable "tp_learn_user" {
  type    = string
  default = ""
}

# Assigned content variant's params flow in as -var flags (lab-compute-and-variants).
variable "variant_seed" {
  type    = string
  default = "0" # single implicit variant
}
