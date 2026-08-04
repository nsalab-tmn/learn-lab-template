# `assessment.docker/` — pyATS/SSH marking scheme for the local Docker lab

The assessment side of the local lab target, written for the **current `learn-assessment@master`
(pyATS) engine** — which connects to the *running* lab over SSH and audits it, rather than the
Azure-management-REST model in this repo's `assessment/marking-scheme.json` (that predates the
pyATS engine and does not apply to a Docker lab).

> **Status: reviewed by the assessment agent (LGTM for the engine, learn-lab-template#3).**
> Validated statically (below) but **not yet run against a live lab / pyATS**. Remaining gate is
> the ingestion path (core/infra), not the scheme itself.
>
> **Requires `learn-assessment` post-#48** — master exports the dynamic-param env vars *before*
> `load_testbed`, so `%ENV{...}` resolves at load time.

## Files (the exact names `Assessment.from_dir` loads)

| File | Role |
|---|---|
| `testbed.yaml` | pyATS topology — one `linux` device `lab`, SSH to `%ENV{lab_ip}:2222` with `%ENV{ssh_user}`/`%ENV{ssh_password}`. |
| `ms.yaml` | the marking scheme tree (`Criterions → subCriterions → aspects → steps → action_chain`). |
| `parameters.yaml` | static params (`skip_connections`, `skiptype` — both optional). |

The `%ENV{...}` values come from `deploy.docker/`'s outputs via `tf-dynamic-params.json`: the
worker exports each dynamic-param `value` as an env var (dashes→underscores), so `lab_ip`,
`ssh_user`, `ssh_password` are available to the testbed.

## What it grades (sample task)

Two aspects, 10 marks total — a template to adapt:
1. **SSH access (5)** — `verify_output` runs `whoami`, asserts `learner` is present (proves the
   lab is reachable and the credentials work).
2. **The task (5)** — `verify_output` runs `cat /home/learner/answer.txt`, asserts `done` is
   present.

**Sample task text** (for `testProject.md`): *"Connect to the lab over SSH and write the word
`done` into `/home/learner/answer.txt`."*

## Validation done

- All three files YAML-parse.
- The scheme passes the engine's own `validate_scheme` rules (replicated): device `lab` is in
  the testbed, `verify_output` is an implemented action, no `{param}` references are undefined,
  no two aspects share identical steps.

## Review outcome

- **Dynamic-param key names — confirmed match.** `deploy.docker/` emits `lab_ip`, `ssh_user`,
  `ssh_password` (underscored), which the engine exports verbatim as env vars — the testbed's
  `%ENV{...}` names line up. This key-name agreement is part of the deploy→assess contract
  (learn-lab-deploy#38); the envelope *shape* is separately schema-guarded.
- **Connection** — `os: linux` + unicon SSH to `linuxserver/openssh-server` (2222, password) is
  standard; added `arguments: {connection_timeout: 30, learn_hostname: true}` so unicon reliably
  learns the container prompt. Confirmed only by a live run.
- **Port** — hardcoded `2222` is the safe template default (avoids `%ENV` string→int coercion).
- **Aspect codes** made globally unique (`A.1.1`/`A.2.1`) — `MarkSummary` is a flat map keyed by
  aspect code.

## The one remaining gate — ingestion (core/infra, not the engine)

The engine already grades a **folder** fetched from `{materialId}/{assessmentPath}/`, and core
sends `assessmentPath` in the `learn-assess` message. So the work is on the **core** side: store
this `assessment.docker/` content in the assets bucket and pick the right `assessmentPath`
**per lab target** (`assessment.docker` for local, the legacy Azure `assessment/` for cloud) —
the symmetric partner of the per-target `deployPath`. The `learn-metadata.json` single-`$ref`
model is the retired Azure-REST shape and doesn't apply. Tracked toward a KB amendment + a core
issue; see learn-lab-deploy#38 and the multi-target-data-plane decision.
