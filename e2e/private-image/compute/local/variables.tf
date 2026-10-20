# learn-lab-deploy passes these -var flags to every playbook (declare the ones you use).
variable "instance_id" {
  type    = string
  default = "user01_1111" # = userMaterialId
}

variable "tp_name" {
  type    = string
  default = "e2e_priv" # = materialId
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

# The private GHCR image the lab runs. Not a secret: the operator replaces the placeholder
# default (see ../../README.md). The image must behave like linuxserver/openssh-server
# (USER_NAME / USER_PASSWORD / PASSWORD_ACCESS env, sshd on 2222), so the root lab's
# assessment.docker grades it unchanged.
variable "ghcr_private_image" {
  type        = string
  description = "Private image reference on ghcr.io, e.g. ghcr.io/<org>/<private-image>:<tag>."
  default     = "ghcr.io/<org>/<private-image>:<tag>"

  validation {
    condition     = startswith(var.ghcr_private_image, "ghcr.io/") && !strcontains(var.ghcr_private_image, "<")
    error_message = "ghcr_private_image must be a ghcr.io image reference; replace the ghcr.io/<org>/<private-image>:<tag> placeholder (see e2e/private-image/README.md)."
  }
}

# Placeholder credentials (KB deployment-interfaces rule 8; learn-lab-deploy
# docs/credentials-span.md §4). The instance supplies the values: the admin sets
# LAB_DEPLOY_SECRET_<NAME> at the worker, and this job's Terraform alone receives it as
# TF_VAR_LEARN_SECRET_<NAME>. Never give these a default and never assign them in a tfvars
# file; the worker preflight refuses both. They are used only in the docker provider's
# registry_auth for ghcr.io (main.tf).
variable "LEARN_SECRET_GHCR_PULL_USER" {
  type      = string
  sensitive = true
  ephemeral = true # Terraform >= 1.10: never written to state, plan, or a root output
}

variable "LEARN_SECRET_GHCR_PULL_TOKEN" {
  type      = string
  sensitive = true
  ephemeral = true # Terraform >= 1.10: never written to state, plan, or a root output
}
