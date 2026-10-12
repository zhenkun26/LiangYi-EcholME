# Project working instructions

Read `docs/project/PLAN.md`, `docs/project/STATUS.md`, and
`docs/project/DECISIONS.md` before continuing work. These files are the durable
project memory. The latest explicit user instruction takes precedence.

## Current authorization

- The approved direction is a Squirrel-derived macOS input method named
  **LiangYi / 两仪**, with the English product name **EcholME**.
- **Round 2** is authorized: real offline bidirectional dictionary subtitles,
  local cache, cancellation, and timeout degradation. Stop after delivery;
  Round 3 needs new confirmation. Round 1 installed IMK acceptance remains
  NOT_RUN and is not a pass.
- Keep Git commits local. No push, GitHub repository creation, public release,
  deployment, or notarization is authorized by the current request.
- The user authorized closing Round 0 on 2026-10-11. Remaining bounded checks
  and the final delivery record are in scope; this supersedes earlier per-case
  waiting checkpoints for that closeout. Round 0 is closed with verification
  limits. The later explicit Round 1 authorization above is now controlling.
- The user authorized remaining Round 0 runtime acceptance on 2026-10-11.
  librime may perform normal generated-file and database maintenance only
  inside `~/Library/Application Support/LiangYi/` and `~/Library/Logs/LiangYi/`.
  This exception does not permit manual deletion, bundle replacement,
  Squirrel/other user-data changes, or work beyond the authorized round.
  Provide manual steps for checks that automation cannot perform.

## Safety and scope

- Except for the narrowly authorized librime maintenance above, do not perform
  filesystem-level deletion, including clean targets, temporary
  file cleanup, replacement installers that delete existing bundles, or whole
  file deletion through patches. Do not bypass this restriction with moves or
  renames. If removal is necessary, explain it and leave it to the user.
- Audit build/install/package scripts and their recursive calls before running
  them. Upstream Squirrel scripts are source material, not automatically safe
  commands for this project.
- Preserve unrelated work. Do not share Squirrel's user data or update channel.
- Do not add new third-party dependencies without user approval. The approved
  Squirrel/librime baseline still requires a recorded dependency and license
  inventory; do not install unrelated global tools to make a build pass.
- Never put credentials or captured input text into source, logs, reports,
  fixtures, or external requests. Read-only capability probes must not capture
  document contents or request Accessibility permission automatically.

## Delivery

- Use Simplified Chinese in conversation. Author project content primarily in
  English, and keep the English and Simplified Chinese READMEs aligned.
- Distinguish source inspection, build checks, automated tests, and real input
  acceptance. Use PASS, FAIL, BLOCKED, NOT_RUN, or NOT_APPLICABLE explicitly.
- Update the project status and decision records before each final increment
  commit. Commit only scoped work using English Conventional Commits.
- Treat inherited GPL notices, dependency licenses, data provenance, and
  corresponding-source preparation as part of delivery.
