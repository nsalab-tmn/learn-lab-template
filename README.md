# learn-lab-template

This repo serves two purposes:

1. **Reference template** for authoring a Learn material repo — a `learn-metadata.json` at the
   repo root, with content pulled in by JSON `$ref` links, ingested by **learn-core**.
2. **The platform's end-to-end test content** (learn-core#102 / KB
   [`conventions/e2e-scenarios.md`](https://github.com/nsalab-tmn/learn-knowledge-base/blob/main/conventions/e2e-scenarios.md)).
   **Local (Docker) is the default compute kind** — it is what the offline
   `docker compose` stack provisions and grades, and what the e2e suite exercises. The Azure kind
   is a **reference example** of a second compute adapter (see [Compute kinds](#compute-kinds)).

## Layout

```
learn-metadata.json     the root material — a hands-on lab (the gradeable e2e lab)
testProject.md          the lab task (rendered as the material's default `text`)
assets/                 images etc. uploaded to object storage
deploy.docker/          `docker` (≡ `local`) compute kind — sshd container (kreuzwerker/docker). DEFAULT.
assessment.docker/      pyATS marking scheme — testbed.yaml / ms.yaml / parameters.yaml
deploy/                 `azure` compute kind — a real Ubuntu VM (azurerm); same output contract as docker.
assessment/             legacy Azure-REST marking scheme (marking-scheme.json) — placeholder.
variants/               content variants — one folder per variant (v0/, v1/), each holding a task.md.
e2e/                    one material of EVERY materialType (for the full-stack e2e)
```

Folder names are a convention, not magic: each compute kind's Terraform and marking scheme live in
their own folder, and `learn-metadata.json`'s `deploy`/`assessment` maps (keyed by compute kind) are
the source of truth for which folder is which. See [Compute kinds](#compute-kinds).

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
| `deploy` | *(lab)* Terraform playbook folder for learn-lab-deploy. Either a single `{"$ref": "./folder"}` **or** a per-**compute-kind** map `{ "docker": {"$ref": "./deploy.docker"}, "azure": {"$ref": "./deploy"} }` — core selects one by **`LEARN_CORE_LAB_COMPUTE`** (default `local`; back-compat alias `LEARN_CORE_LAB_TARGET`). Map keys are compute kinds: `docker`/`local`, `azure`, `aws`, `openstack`, `vcd` (`docker`≡`local`). See [Compute kinds](#compute-kinds). |
| `assessment` | *(lab)* pyATS assessment **folder** (`testbed.yaml`/`ms.yaml`/`parameters.yaml`) — same single-`$ref`-or-per-compute-kind-map shape as `deploy`. |
| `variants` | *(lab / lab-exam)* Optional list of content variants — one material → N variants. Each entry: `shortName`, `text` (`$ref` to that variant's task `.md`), `assessment` (`$ref` to that variant's marking-scheme folder), and optional `params` (extra Terraform `-var`s, e.g. `{ "variant_seed": "1" }`). Absent ⇒ the material's own `text`/`assessment` are the single implicit variant. Core assigns one per deployment: `lab-exam` → random, else index 0. See [Compute kinds](#compute-kinds). |
| `credentialsSchema` | *(lab)* fields shown in the learner's Credentials panel. Each key → `{ title, source }` (or `{ title, value }`). **`source`** must match a Terraform **output** name (a `tf-dynamic-params.json` key) — e.g. `lab_host`, `ssh_user`, `ssh_password` from `deploy.docker/outputs.tf`. Because every compute kind exposes the same output names, one `credentialsSchema` works across kinds. |
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

## Compute kinds

A lab runs on a pluggable **compute kind** — a Terraform **provider family**, not a specific cloud
("kinds, not clouds"). The kind is a **deployment-time selection**, not material content: core picks
the active kind with **`LEARN_CORE_LAB_COMPUTE`** (env; default `local`; back-compat alias
`LEARN_CORE_LAB_TARGET`), resolves the matching folder from the material's `deploy`/`assessment` maps,
and persists it on the UserMaterial so assess/destroy reuse it. Seed kinds: **`local`** (docker; the
default, always available), **`azure`**, **`aws`**, **`openstack`**, **`vcd`** — extensible.
**`docker`≡`local`.**

> Full authoring contract: KB
> [`conventions/lab-compute-and-variants.md`](https://github.com/nsalab-tmn/learn-knowledge-base/blob/main/conventions/lab-compute-and-variants.md)
> (supersedes the earlier
> [multi-target-data-plane decision](https://github.com/nsalab-tmn/learn-knowledge-base/blob/main/decisions/multi-target-data-plane.md)).

### The compute interface

So kinds are interchangeable, **every kind's Terraform must implement the same contract** — this is
why the docker and azure playbooks accept the same vars and output the same names:

- **Consume** the same input `-var`s learn-lab-deploy passes: `instance_id` (userMaterialId),
  `tp_name` (materialId), `tp_learn_env`, `tp_learn_user`, plus any variant `params`.
- **Expose** the same Terraform **output** names — the `tf-dynamic-params.json` keys that
  `credentialsSchema[*].source` maps to (here `lab_host`/`ssh_user`/`ssh_password`) — so one marking
  scheme grades the lab on any kind and switching kind is transparent to the learner.

The two kinds shipped in this repo:

- **`deploy.docker/` + `assessment.docker/` — `docker` (≡ `local`), DEFAULT.** An sshd container on the
  `learn-labs` network; outputs `lab_host`/`lab_ip`/`ssh_user`/`ssh_password`/`ssh_port`; graded over
  SSH by pyATS. This is what runs and is graded offline and in the e2e.
- **`deploy/` — `azure`.** A real Ubuntu VM (`azurerm`). Its `outputs.tf` emits the **same**
  `lab_host`/`ssh_user`/`ssh_password`/`variant_seed` names as the docker kind, so the compute
  interface holds and the kind is a drop-in swap. (Its sibling `assessment/` is still a legacy
  Azure-REST `marking-scheme.json` placeholder — pyATS grading lives in `assessment.docker/`, which the
  variants reference.)

### Variants

Orthogonal to *where* a lab runs is *what* content a learner gets: a material carries its **variants
in-schema** (one material → N variants) instead of shipping a separate material per variation. Authoring
flow in this repo:

1. Add a `variants/<shortName>/task.md` per variant — this repo ships `v0/` and `v1/`.
2. List each in the `variants` array with its `shortName`, `text` `$ref`, `assessment` `$ref`, and
   optional `params` (extra Terraform `-var`s — here `variant_seed`, which the docker and azure
   Terraform read to differentiate the lab, e.g. via a container/VM env var).
3. Core assigns a variant per deployment: `lab-exam` → random, else index 0.

The two axes **compose**: a deployment = *(variant `i`, compute kind `k`)* → run `deploy[k]`'s
Terraform with the base vars **+** `variants[i].params`, graded against `variants[i].assessment`.
