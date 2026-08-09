# `variants/v1/assessment.vsphere/` — vSphere marking scheme for variant v1

The vSphere-target assessment for **v1**. Same gradeable shape as its Docker sibling
[`../assessment.docker/`](../assessment.docker/README.md) — asserts the learner wrote **`bravo`**
to `~/answer.txt` (matching [`../task.md`](../task.md)) — with the only difference being the
`testbed.yaml` SSH port (`22` here vs `2222` on the linuxserver container).

It is the `vsphere` half of variant v1's **per-kind assessment map**
(`{local: …/assessment.docker, vsphere: …/assessment.vsphere}`): once learn-core resolves the
variant `assessmentPath` per compute kind (learn-core#212), a v1 lab deployed to vSphere grades
against this scheme instead of the Docker one. See the root
[`assessment.vsphere/README.md`](../../../assessment.vsphere/README.md) for the engine semantics.
