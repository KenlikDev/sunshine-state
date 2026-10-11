# Development Workflow

## Branches
- `main`: reviewed release-quality history only.
- `develop`: integration branch, managed by the repository owner.
- `codex/<task-name>`: isolated implementation or documentation work.

Do not make direct changes to `main`. Keep changes focused and submit a pull request for review. The repository owner controls merges into `main` and `develop`.

## Pull request requirements
- State the user-visible or technical change.
- Link the relevant milestone or issue.
- Describe tests run and their results.
- Include screenshots or recordings for visual changes when useful.
- Document known limitations and any asset/license changes.
- Do not claim tests passed unless they were actually run.

## Commit style
Use concise imperative messages, for example:
- `docs: define MVP acceptance criteria`
- `feat: add third-person movement controller`
- `test: cover mission reward idempotency`

## Definition of done
- Acceptance criteria satisfied.
- Relevant tests added or updated.
- No unrelated formatting or generated-file churn.
- Documentation updated.
- No secrets or unlicensed assets added.
- CI passes, or failures are explicitly reported and understood.
- Review completed before merge.

## Language
Repository code, identifiers, comments, and documentation are written in English. Player-facing localization is handled separately through translation resources.
