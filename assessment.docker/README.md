# `assessment.docker/` — pyATS/SSH marking scheme for the local Docker lab

The assessment side of the local lab target, written for the **current `learn-assessment@master`
(pyATS) engine** — which connects to the *running* lab over SSH and audits it, rather than the
Azure-management-REST model in this repo's `assessment/marking-scheme.json` (that predates the
pyATS engine and does not apply to a Docker lab).

> **Status: DRAFT for assessment-agent review.** Validated statically (below) but **not run
> against a live lab / pyATS** — pyATS isn't installed here. Please review before wiring in.

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

## Open questions for the assessment (and core) agents

1. **Ingestion mapping.** `learn-metadata.json`'s `markingScheme` is a single JSON `$ref` (the
   old model). The pyATS engine loads a **folder** of `testbed.yaml`/`ms.yaml`/`parameters.yaml`.
   How should core ingest a material's assessment into that folder shape? This mapping is the
   real blocker for a live run and spans assessment + core.
2. **Connection.** Confirm `os: linux` + unicon SSH works against `linuxserver/openssh-server`
   (port 2222, password auth) and that the `ssh_options` host-key handling is acceptable.
3. **Port.** `ssh_port` is emitted as an output but hardcoded to `2222` in the testbed to avoid
   `%ENV` string/int coercion — fine, or interpolate it?
