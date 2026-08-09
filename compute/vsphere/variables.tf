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

# vCenter inventory — ALL values supplied at deploy via ambient TF_VAR_VSPHERE_* (learn-infra
# wiring, infra#76); ZERO DCIX literals here per lab-compute-and-variants#120. The names are
# UPPERCASE to match the TF_VAR_VSPHERE_* contract exactly (TF_VAR_ is case-sensitive). The
# locked pilot values (not committed) are DCIX / DCIX-CLUSTER1 / dcix-* datastore / VLAN_2310 /
# template-ubuntu-24, deployed into the LEARN-TEST folder.
variable "VSPHERE_DATACENTER" {
  type = string
}
variable "VSPHERE_CLUSTER" {
  type = string
}
variable "VSPHERE_DATASTORE" {
  type = string
}
variable "VSPHERE_NETWORK" {
  type = string
}
variable "VSPHERE_TEMPLATE" {
  type = string
}
variable "VSPHERE_FOLDER" {
  type    = string
  default = "LEARN-TEST" # the dedicated pilot folder; override via TF_VAR_VSPHERE_FOLDER
}
