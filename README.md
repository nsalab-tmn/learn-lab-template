# learn-lab-template

This repo serves two purposes:

1. **Reference template** for authoring a Learn material repo — a `learn-metadata.json` at the
   repo root, with content pulled in by JSON `$ref` links, ingested by **learn-core**.
2. **The platform's end-to-end test content** (learn-core#102 / KB
   [`conventions/e2e-scenarios.md`](https://github.com/nsalab-tmn/learn-knowledge-base/blob/main/conventions/e2e-scenarios.md)).
   **Local (Docker) deployment is the first-priority target** — it is what the offline
   `docker compose` stack provisions and grades, and what the e2e suite exercises. The Azure target
   is kept as a **reference example** (see [Targets](#targets)).

## Layout

```
learn-metadata.json     the root material — a hands-on lab (the gradeable e2e lab)
testProject.md          the lab task (rendered as the material's `text`)
assets/                 images etc. uploaded to object storage
deploy.docker/          LOCAL Docker target — sshd container (kreuzwerker/docker). PRIMARY.
assessment.docker/      LOCAL pyATS marking scheme — testbed.yaml / ms.yaml / parameters.yaml
deploy/                 Azure target — reference example (see Targets)
assessment/             legacy Azure-REST marking scheme — reference example only
e2e/                    one material of EVERY materialType (for the full-stack e2e)
```

### `e2e/` — all-types content

So a single ingest exercises every `materialType`:

| Path | materialType |
|---|---|
| *(repo root)* | `lab` — the dual-target Docker lab (graded 10/10 by the e2e) |
| `e2e/lecture` | `lecture` |
| `e2e/test` | `test` — self-test quiz covering all four `answerType`s |
| `e2e/exam` | `test-exam` |
| `e2e/lab-exam` | `lab-exam` — reuses the root lab's Docker playbooks |
| `e2e/course` | `course` — composes lecture + quiz + the root lab |
| `e2e/path` | `learning-path` — lecture + quiz → certificate |

## `learn-metadata.json` format

A material is a JSON object. `$ref` values are resolved by core against GitHub/HTTP/relative URIs
(a `$ref` to a **directory** becomes a `{path: url}` file-dict; for GitHub, move the branch into a
`?ref=<branch>` query param).

| Field | Meaning |
|---|---|
| `title` | Human-readable name (unique per `materialType`). |
| `materialType` | One of `lab`, `lab-exam`, `test`, `test-exam`, `lecture`, `course`, `learning-path`. |
| `shortName` | Short id, `[a-z_]`, ≤ ~10 chars. |
| `description` | Short summary. |
| `text` | Markdown body (lab task / lecture) — `$ref` a `.md` file. |
| `deploy` | *(lab)* Terraform playbook folder for learn-lab-deploy. Either a single `{"$ref": "./folder"}` (single-target) **or** a per-target map `{ "docker": {"$ref": "./deploy.docker"}, "azure": {"$ref": "./deploy"} }` (multi-target — core selects one by `LEARN_CORE_LAB_TARGET`, learn-core#155). |
| `assessment` | *(lab)* pyATS assessment **folder** (`testbed.yaml`/`ms.yaml`/`parameters.yaml`) — same single-`$ref`-or-per-target-map shape as `deploy`. |
| `credentialsSchema` | *(lab)* fields shown in the learner's Credentials panel. Each key → `{ title, source }` (or `{ title, value }`). **`source`** must match a Terraform **output** name (a `tf-dynamic-params.json` key) — e.g. `lab_host`, `ssh_user`, `ssh_password` from `deploy.docker/outputs.tf`. |
| `answerSchema` | *(lab)* JSON Schema for the learner's answer fields (`title`, `placeholder` per property). |
| `assets` | Files (`$ref` a folder) uploaded to object storage and referenced from `text`. |
| `questions` | *(test / test-exam)* the questions — see below. |
| `passingScore` | *(test / test-exam)* pass threshold, 0–100 (default 75). |
| `materials` | *(course / learning-path)* ordered `$ref`s to child materials' `learn-metadata.json`. |
| `duration` | ISO-8601 duration, e.g. `PT1H`. |
| `difficulty` | 1–10. |
| `tags` | Catalog tags. |
| `skills` | Skill-domain map (surfaced per aspect; authoring is optional). |

> **Removed:** the old top-level `markingScheme` `$ref` (an Azure-management-REST shape) is gone —
> assessment is a **folder** (`assessment/…`), graded by learn-assessment's pyATS engine
> (learn-core#155/#156).

### `questions` (test / test-exam)

Each question: `questionId`, `question`, `answerType` ∈ `singleChoice | multiChoice | textInput |
matching`, `answers[]` (`answerId`, `answer`, `correct?`, `match?` for text/matching, `comment?`),
and `options[]` (`id`, `option`, `match`) for `matching`.

## Targets

Per the KB
[multi-target-data-plane decision](https://github.com/nsalab-tmn/learn-knowledge-base/blob/main/decisions/multi-target-data-plane.md),
a lab's target is a property of the material, selected by `LEARN_CORE_LAB_TARGET`; the worker stays
target-agnostic. **Per-target playbooks must expose an identical output contract** (the same
`tf-dynamic-params.json` key names) so one marking scheme grades the lab on any target.

- **`deploy.docker/` + `assessment.docker/` — local (Docker), PRIMARY.** An sshd container on the
  `learn-labs` network; outputs `lab_host`/`lab_ip`/`ssh_user`/`ssh_password`/`ssh_port`; graded over
  SSH by pyATS. This is what runs and is graded offline and in the e2e.
- **`deploy/` + `assessment/` — Azure, reference example only.** ⚠️ Not aligned to the local output
  contract: `deploy/outputs.tf` emits `learn_rg`/`learn_user`/`learn_password` and `assessment/` is a
  legacy Azure-REST scheme — so the Azure side of the root material's dual-target map is **not
  gradable as-is**. It is retained to show the Azure playbook shape; making it a real second target
  requires aligning its outputs to `lab_host`/`ssh_user`/`ssh_password` and porting the marking scheme
  to the pyATS folder model.
