# `compute/vsphere/` — on-prem vSphere lab target (pilot)

Provisions this lab as a **Linux VM on vCenter** (the `vsphere` compute kind), so the platform can
run and grade a lab on on-prem VMware. Material-side piece of the vSphere pilot — see the charter
`vsphere-onprem-lab-pilot` and the adapter in [learn-lab-deploy#58](https://github.com/nsalab-tmn/learn-lab-deploy/issues/58).

## What it creates

Clones `VSPHERE_TEMPLATE` into the `VSPHERE_FOLDER` (default `LEARN-TEST`) on the given datacenter/
cluster/datastore/network, and cloud-inits a `learner` user with a generated password + password
SSH. It outputs how to reach it. `learn-lab-deploy` runs this with no code change — it shells
`terraform` on whatever the playbook declares.

## Nothing vCenter-specific is hardcoded

Per [lab-compute-and-variants#120](https://github.com/nsalab-tmn/learn-knowledge-base/blob/main/conventions/lab-compute-and-variants.md), **all** instance specifics are Terraform variables fed from
ambient `TF_VAR_VSPHERE_*` (wired by `learn-infra`, infra#76) — this playbook carries **zero** DCIX
literals and stays portable to any vCenter.

| Auth (ambient provider env, passthrough) | Inventory (`TF_VAR_VSPHERE_*` variables) |
|---|---|
| `VSPHERE_SERVER` | `VSPHERE_DATACENTER` |
| `VSPHERE_USER` | `VSPHERE_CLUSTER` (resource pool for the clone) |
| `VSPHERE_PASSWORD` | `VSPHERE_DATASTORE` |
| `VSPHERE_ALLOW_UNVERIFIED_SSL` | `VSPHERE_NETWORK` |
| | `VSPHERE_TEMPLATE` |
| | `VSPHERE_FOLDER` (default `LEARN-TEST`) |

Variable names are **uppercase** to match the `TF_VAR_VSPHERE_*` contract exactly (`TF_VAR_` is
case-sensitive).

## Outputs (the target-invariant contract)

`lab_host`, `lab_ip`, `ssh_port` (22), `ssh_user`, `ssh_password` — the same
`tf-dynamic-params.json` keys the other targets emit, so [`../../assessment.vsphere/`](../../assessment.vsphere/README.md)
grades over SSH exactly like the Docker target (just port 22, not 2222). Keep the names identical
across targets.

## Status / caveats

- **`terraform validate` green** against the `hashicorp/vsphere` v2 schema.
- **SSH provisioning is cloud-init over guestinfo** — assumes `template-ubuntu-24` has cloud-init +
  VMware Tools. If it does not, the first `deploy -> SSH-grade` acceptance run surfaces it
  (fail-forward: rebuild an Ubuntu template with cloud-init + Tools, then re-run — pre-authorized
  by kb/infra). The live vCenter run is proven by the infra harness, not from this checkout.
