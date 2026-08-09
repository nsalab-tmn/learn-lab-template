# `variants/v1/assessment.docker/` — marking scheme for variant v1

Per-variant assessment for **v1** of the sample local Docker lab. Identical in structure to the
root [`assessment.docker/`](../../../assessment.docker/README.md) (same `testbed.yaml` /
`parameters.yaml`, same pyATS engine); the **only** difference is the task aspect (`A.2.1`),
which asserts the learner wrote **`bravo`** to `~/answer.txt` — matching [`../task.md`](../task.md).

v0's sibling asserts `alpha`, so the two variants grade against different marking schemes
(lab-template#18): the same answer passes one variant and fails the other. See the root README
for the engine semantics, the `%ENV{...}` deploy→assess key contract, and validation notes.
