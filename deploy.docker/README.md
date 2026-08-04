# `deploy.docker/` — local (Docker) lab target

A Terraform playbook that provisions this lab as a **Docker container** instead of an Azure
VM, so the whole Learn stack can run and grade a lab **offline** on `docker compose`. It is the
material-side piece of the local lab target — see the design in
[learn-lab-deploy#38](https://github.com/nsalab-tmn/learn-lab-deploy/issues/38) and the KB
decision [multi-target-data-plane](https://github.com/nsalab-tmn/learn-knowledge-base/blob/main/decisions/multi-target-data-plane.md).

## What it creates

An `sshd` container (`linuxserver/openssh-server`) with a generated password, attached to the
shared **`learn-labs`** network, and outputs how to reach it. `learn-lab-deploy` runs this with
no code change — it shells `terraform` on whatever the playbook declares.

## The contract it honours

| Requirement | Here |
|---|---|
| Provider `kreuzwerker/docker` **`~> 3.0`** | matches the set mirrored in the `learn-lab-deploy` image (air-gapped `init`) |
| Reach the Docker daemon | `provider "docker"` reads `DOCKER_HOST` from the env — the scoped socket-proxy wired by `learn-infra` (never the raw host socket) |
| Attach to **`learn-labs`** | `networks_advanced { name = data.docker_network.labs.name }` — the network `learn-assessment` is also on |
| Assessment-reachable address | outputs `lab_ip` (its `learn-labs` IP) and `lab_host` (Docker DNS name) — **never `localhost`** |
| Terraform vars from the worker | declares `instance_id` / `tp_name` / `tp_learn_env` / `tp_learn_user` |

Outputs: `lab_host`, `lab_ip`, `ssh_port` (2222), `ssh_user`, `ssh_password` — these are the
`tf-dynamic-params.json` keys the marking scheme and `learn-metadata.json` `credentialsSchema`
reference. Keep the names **identical across targets** so one marking scheme grades any target.

## Using it as a material's `deploy/`

`learn-core` ingests a single `deploy/` folder (the `learn-metadata.json` `"deploy"` `$ref`).
For an **offline, single-target material** (Milestone A), point `deploy` at this playbook (or
copy these files into `deploy/`); keep the Azure `deploy/` for the cloud target. Carrying
**both** targets in one material under a per-target map is **Milestone B** (needs the core
ingestion + `LEARN_CORE_LAB_TARGET` selection changes gated on the KB decision).

## Status / caveats

- **Validated** with `terraform validate` against the real `kreuzwerker/docker` v3 + `random`
  provider schemas (`terraform init && terraform validate` — succeeds).
- **Not yet run end-to-end** — that needs the compose stack (`learn-infra`) up and a matching
  assessment marking scheme.
- **Assessment side is still TODO.** The current `assessment/marking-scheme.json` uses the
  Azure-management-REST (`jmespath`/`allresource`) model, which does **not** apply to a Docker
  lab. `learn-assessment@master` grades over **SSH via pyATS**, so a local marking scheme must
  connect to `%ENV{lab_ip}` on port **2222** with `ssh_user`/`ssh_password`. Authoring that is
  assessment-domain work — tracked in this repo's issue #1.
- **Fully offline** requires the `sshd` image present on the host (pre-pull once); the
  socket-proxy allows the daemon to pull on first use.
