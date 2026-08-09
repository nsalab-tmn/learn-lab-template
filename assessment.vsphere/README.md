# `assessment.vsphere/` — pyATS/SSH marking scheme for the vSphere lab target

The assessment side of the vSphere pilot target (lab-template#22). Structurally identical to the
root [`assessment.docker/`](../assessment.docker/README.md) — same pyATS engine, same `Assessment.from_dir`
files (`testbed.yaml` / `ms.yaml` / `parameters.yaml`), same gradeable shape (SSH in as `learner`,
write `done` to `~/answer.txt`). The **only** difference from the Docker target is the SSH port
(`22` here vs `2222` on the linuxserver container).

The `%ENV{...}` values (`lab_ip`, `ssh_user`, `ssh_password`) come from `compute/vsphere/`'s outputs
via `tf-dynamic-params.json` — the target-invariant contract that lets one marking scheme grade any
target. See the root README for the engine semantics and the deploy→assess key contract.
