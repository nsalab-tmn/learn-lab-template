terraform {
  # ephemeral input variables (the LEARN_SECRET_* placeholders) need Terraform >= 1.10
  required_version = ">= 1.10"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0" # matches the provider set mirrored in the learn-lab-deploy image
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# Reads DOCKER_HOST from the environment — the scoped socket-proxy wired by learn-infra.
# registry_auth is the only place the placeholder credentials are used: Terraform allows an
# ephemeral value in a provider block, and nowhere that persists it.
provider "docker" {
  registry_auth {
    address  = "ghcr.io"
    username = var.LEARN_SECRET_GHCR_PULL_USER
    password = var.LEARN_SECRET_GHCR_PULL_TOKEN
  }
}

# The shared lab network created by learn-infra (name pinned as a cross-repo contract).
# learn-assessment is attached to it, so it can reach the lab by name / IP.
data "docker_network" "labs" {
  name = "learn-labs"
}

resource "random_password" "ssh" {
  length  = 16
  special = false
}

# Reads the image's manifest from ghcr.io with the registry_auth above on every plan, so each
# deploy authenticates to the registry even when the image is already cached on the host.
data "docker_registry_image" "lab" {
  name = var.ghcr_private_image
}

resource "docker_image" "lab" {
  name          = data.docker_registry_image.lab.name
  pull_triggers = [data.docker_registry_image.lab.sha256_digest]
  # Shared by concurrent instances of this lab on one host: leave it cached on destroy.
  keep_locally = true
}

resource "docker_container" "lab" {
  name  = "lab-${var.instance_id}"
  image = docker_image.lab.image_id

  env = [
    "USER_NAME=learner",
    "USER_PASSWORD=${random_password.ssh.result}",
    "PASSWORD_ACCESS=true",
    "VARIANT_SEED=${var.variant_seed}",
  ]

  # Attach to the shared lab network so learn-assessment can reach the container.
  networks_advanced {
    name = data.docker_network.labs.name
  }

  # Let an orphan-reaper find leaked labs by their instance id.
  labels {
    label = "learn.instance_id"
    value = var.instance_id
  }

  labels {
    label = "learn.variant_seed"
    value = var.variant_seed
  }
}
