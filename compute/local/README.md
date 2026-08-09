# `compute/local/` — local (Docker) lab target

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

## Using it as a material's compute kind

`learn-core` ingests provisioning folders under the `compute` authoring key, keyed by **compute
kind**: `"compute": { "local": { "$ref": "./compute/local" }, "azure": { "$ref": "./compute/azure" } }`
(`local`≡`docker`, `local` required). Core resolves the active kind by `LEARN_CORE_LAB_COMPUTE`
and stores the `deploymentPath` `{kind: path}` map (learn-core#196); the legacy single `deploy`
authoring key is now **rejected with a 400**. This folder is the `local` kind; the Azure kind
lives in [`../azure/`](../azure/).

## Status / caveats

- **Validated** with `terraform validate` against the real `kreuzwerker/docker` v3 + `random`
  provider schemas (`terraform init && terraform validate` — succeeds).
- **Not yet run end-to-end** — that needs the compose stack (`learn-infra`) up and a matching
  assessment marking scheme.
- **Assessment side** is drafted in [`../../assessment.docker/`](../../assessment.docker/README.md)
  (pyATS/SSH marking scheme for the current `learn-assessment` engine) — in review with the
  assessment agent. The repo's legacy `assessment/marking-scheme.json` (Azure-management-REST)
  does not apply to a Docker lab.
- **Fully offline** requires the `sshd` image present on the host (pre-pull once); the
  socket-proxy allows the daemon to pull on first use.
