terraform {
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
# The worker never sets this in code; it is inherited by the terraform subprocess.
provider "docker" {}

# The shared lab network created by learn-infra (name pinned as a cross-repo contract).
# learn-assessment is attached to it, so it can reach the lab by name / IP.
data "docker_network" "labs" {
  name = "learn-labs"
}

resource "random_password" "ssh" {
  length  = 16
  special = false
}

resource "docker_image" "sshd" {
  # Digest-pinned (the multi-arch image-index digest of linuxserver/openssh-server) so the
  # lab provisions air-gapped: with the image pre-pulled onto the host, keep_locally stops
  # terraform re-checking the registry on apply. Bundle this exact digest for the offline run.
  name         = "lscr.io/linuxserver/openssh-server@sha256:96b9a4d3b5106746d08d43a6911650d4d21f7d5c7f2ac9660e792bdb5e63157c"
  keep_locally = true
}

resource "docker_container" "lab" {
  name  = "lab-${var.instance_id}"
  image = docker_image.sshd.image_id

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
