# e2e content set (all material types)

Test content for the full-stack e2e suite (learn-core#102 / KB `conventions/e2e-scenarios.md`).
One material per `materialType`, so a single ingest exercises every type:

| Path | materialType |
|---|---|
| `e2e/lecture` | lecture |
| `e2e/test` | test (self-test quiz; all four answerTypes) |
| `e2e/exam` | test-exam |
| `e2e/lab-exam` | lab-exam (reuses the repo-root dual-target Docker lab) |
| `e2e/course` | course (lecture + quiz + the root sample lab) |
| `e2e/path` | learning-path (lecture + quiz → certificate) |
| *(repo root `learn-metadata.json`)* | lab (the validated dual-target Docker lab) |

`course`/`path` reference leaves by `$ref` to their `learn-metadata.json`. The exact
material-`$ref` composition is **best-effort pending live ingestion** during the infra harness
build — if core's material-ref resolution wants a folder rather than the metadata file, it is a
one-line change per ref.
