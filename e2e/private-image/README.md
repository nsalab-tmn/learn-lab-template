# `e2e/private-image/` — private GHCR image lab (placeholder credentials fixture)

The fixture for the credentials-span live proof,
[learn-lab-deploy#90](https://github.com/nsalab-tmn/learn-lab-deploy/issues/90)
([learn-lab-template#28](https://github.com/nsalab-tmn/learn-lab-template/issues/28)). It is the
root sample lab's `local` kind, with one change: the container image is a **private** image on
`ghcr.io`, pulled with credentials the instance supplies. The credentials never enter content.

The contract is KB
[`conventions/deployment-interfaces.md`](https://github.com/nsalab-tmn/learn-knowledge-base/blob/main/conventions/deployment-interfaces.md)
rule 8, and the worker side is learn-lab-deploy `docs/credentials-span.md` §4.

## Files

| Path | Role |
|---|---|
| `learn-metadata.json` | a `lab` material, `local` kind only; declares `"placeholders": ["GHCR_PULL_USER", "GHCR_PULL_TOKEN"]` (core registry names, learn-core#299) |
| `compute/local/` | the Terraform playbook: the root `compute/local/` plus `registry_auth` and a private image |
| `task.md` | the learner task (the same as the root lab's) |
| `assessment.docker/` | a copy of the root lab's [`assessment.docker/`](../../assessment.docker/README.md), byte-identical. The fixture keeps its own copy because a `$ref` that leaves the material's folder does not survive GitHub ingest (learn-core#308, learn-lab-deploy#90). |

## How the placeholders are wired

- `compute/local/variables.tf` declares `LEARN_SECRET_GHCR_PULL_USER` and
  `LEARN_SECRET_GHCR_PULL_TOKEN`: `type = string`, `sensitive = true`, `ephemeral = true`, no
  default. Ephemeral variables need Terraform ≥ 1.10 (`required_version` in `main.tf`).
- They are used only in `provider "docker" { registry_auth { address = "ghcr.io" … } }`.
  Terraform refuses an ephemeral value anywhere that persists, so the values cannot reach state,
  the plan or an output.
- `data "docker_registry_image"` reads the image manifest from `ghcr.io` with those credentials
  on every plan, so each deploy authenticates to the registry even when the image is cached.
- No `*.tfvars` file ships, and no output names a placeholder. `outputs.tf` is byte-identical to
  the root `compute/local/outputs.tf` (`lab_host`, `lab_ip`, `ssh_port`, `ssh_user`,
  `ssh_password`), so `assessment.docker/` and the `credentialsSchema` work unchanged.

## What the operator sets

### 1. The private image (non-secret)

The image must behave like `linuxserver/openssh-server`: the `USER_NAME` / `USER_PASSWORD` /
`PASSWORD_ACCESS` env, sshd on port 2222, and the learner's home at `/config`. The simplest image
is a private copy of the one the root lab pins:

```shell
docker pull lscr.io/linuxserver/openssh-server@sha256:96b9a4d3b5106746d08d43a6911650d4d21f7d5c7f2ac9660e792bdb5e63157c
docker tag  lscr.io/linuxserver/openssh-server@sha256:96b9a4d3b5106746d08d43a6911650d4d21f7d5c7f2ac9660e792bdb5e63157c ghcr.io/<org>/<private-image>:<tag>
docker push ghcr.io/<org>/<private-image>:<tag>   # keep the package's visibility private
```

The playbook reads the reference from the variable `ghcr_private_image`. Its default,
`ghcr.io/<org>/<private-image>:<tag>`, is a placeholder that fails the plan with a named
validation error until it is replaced. Set it in one of two ways:

- **At the worker:** `TF_VAR_ghcr_private_image=ghcr.io/<org>/<private-image>:<tag>`. It is not
  in a reserved namespace, so it passes through to the job's Terraform, and nothing is
  committed.
- **In content:** replace the `default` on the branch the proof ingests. The value is not a
  secret.

### 2. The credentials (secret, out of band)

A GitHub token with only the `read:packages` scope, from an account that can read the package.
It is configured on the instance, never in this repo:

| Where | Setting | Value |
|---|---|---|
| lab-deploy worker | `LAB_DEPLOY_SECRET_GHCR_PULL_USER` | the token owner's GitHub login |
| lab-deploy worker | `LAB_DEPLOY_SECRET_GHCR_PULL_TOKEN` | the token, from the instance's secret store |
| lab-deploy worker | `LAB_DEPLOY_PLACEHOLDER_ALLOW_GHCR_PULL_USER`, `…_TOKEN` | this material's id, or `github:nsalab-tmn/learn-lab-template` |
| core | `LEARN_CORE_IMPLEMENTED_PLACEHOLDERS` | `GHCR_PULL_USER,GHCR_PULL_TOKEN` |
| core | `LEARN_CORE_PLACEHOLDER_ALLOW_GHCR_PULL_USER`, `…_TOKEN` | the same entries as the worker's lists |

The worker hands the job `TF_VAR_LEARN_SECRET_GHCR_PULL_*`. Before `terraform init` its
preflight checks this playbook (P0–P4) and the worker's configuration (P5 trust, P1 configured).

### 3. Ingest and run

Ingest `e2e/private-image/learn-metadata.json`. The lab is offered only when both placeholders
are configured and trusted for it. To show the pull itself as well as the registry read, remove
the image from the Docker host (`docker image rm ghcr.io/<org>/<private-image>:<tag>`) before the
first deploy. Destroy leaves the image cached (`keep_locally = true`), because concurrent instances
share it.

## Validation done

- `terraform init && terraform validate` passes (Terraform 1.16.6, kreuzwerker/docker 3.9.0,
  hashicorp/random 3.9.1). `terraform fmt -check` is clean.
- `terraform plan` with the placeholder default fails on the `ghcr_private_image` validation.
- learn-lab-deploy's preflight (`lab_deploy/preflight.py`, origin/master) passes. A worker
  without a trust list fails P5, and a worker without the secrets fails P1.
