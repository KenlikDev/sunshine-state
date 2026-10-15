# Build Manifest Schema

Each CI desktop artifact contains `build-manifest.json` at the artifact root. The manifest is generated only after the relevant export/runtime-smoke job steps complete and binds the package to the Git revision that was checked out.

## Schema version 1

- `schema_version`: integer schema version; currently `1`.
- `project_name` and `project_version`: product identity as configured for the prototype.
- `commit_sha`: full Git commit SHA built by the workflow. The CI step validates it against `GITHUB_SHA`.
- `workflow_run_id` and `workflow_run_attempt`: identifiers for the GitHub Actions run/attempt.
- `workflow_url`: link to the run that contains the build and smoke-test results.
- `engine_version`: pinned Godot version used for export.
- `platform_targets`: exported target(s) represented by the artifact. The combined desktop artifact contains Windows Desktop and Linux/X11; the Windows artifact contains Windows Desktop.
- `checks_performed`: export/runtime smoke checks completed within the corresponding artifact job.
- `generated_at_utc`: UTC timestamp recorded after those checks.

## Trust boundaries

A manifest records what the corresponding CI job reports; it is not a code signature, cryptographic attestation, or proof of an interactive clean-machine playthrough. Verify the artifact's workflow URL and commit SHA before testing. Do not change the manifest by hand and continue to treat the build as validated for only the checks recorded in its `checks_performed` field. CI artifacts expire according to the workflow retention policy; a later release should retain the exact manifest alongside any preserved build.
