# Changes from Squirrel

Derived project: **LiangYi / 两仪 — EcholME**.

Baseline: Squirrel [`769ae426f33f500266101a88f694aab0d158e680`](https://github.com/rime/squirrel/tree/769ae426f33f500266101a88f694aab0d158e680).

This is a modification record for the derived project. It does not replace upstream copyright notices, [LICENSE.txt](LICENSE.txt), or the upstream [CHANGELOG.md](CHANGELOG.md). Changes belong to their recorded Git authors; imported work retains its original attribution.

## 2026-10-11 — Round 0 foundation

Status: **code/build/install delivered; runtime acceptance blocked**.

The approved plan was committed as `041b643`, then the pinned Squirrel history was imported in `8b507af`. Round 0 changes establish an independent project rather than change the inherited Chinese composition semantics.

Scope of this increment:

- Preserve the complete approved delivery plan, status record, decision register, and project working instructions.
- Identify the product as EcholME / 两仪 with a macOS 14 deployment target.
- Separate bundle/input-source identity, IMK connection, notifications, user storage, and log storage from Squirrel.
- Disable the inherited runtime update channel. Do not route EcholME users to a Squirrel appcast or advertise automatic updates.
- Add a reviewed development build/install/diagnostic path that observes the user's no-deletion rule and stops at an existing installation destination.
- Record baseline/dependency/resource provenance and GPL distribution requirements.
- Establish capability and acceptance records that distinguish source review, build, registration, actual input, and host-context behavior.
- Preserve the original upstream README in `docs/upstream/README.squirrel.md` while providing bilingual project documentation.
- Add a repository-identity guard to the three inherited GitHub workflows so package/release automation does not execute in the derived repository. No new cloud CI result is implied; local checks remain separately recorded.

Final source builds and signs on the recorded arm64 environment; the app is installed and registered but disabled. The installed metadata correction and all PASS/BLOCKED/NOT_RUN results are recorded in VERIFICATION.md. Both default input-mode states are false to avoid automatic enablement at registration.

The initial runtime acceptance boundary was `BLOCKED_NO_DELETION_POLICY`: the pinned librime dictionary compiler can remove generated table/prism files during deployment. Round 0 must not deploy schemas, launch the input method, enable/select it, or run actual-input tests until the user has explicitly resolved that narrow conflict. Do not rewrite the engine or use a hidden deletion workaround. Building, first-install copying, registration-only CLI handling, and read-only input-source inspection remain separate activities subject to their own script audit.

Not part of Round 0:

- English composition, bilingual translation candidates, or translated-text submission.
- Context-driven mode switching or a new mode HUD.
- Cloud translation calls, credentials, provider settings, or a network service process.
- A new candidate UI framework or replacement of Squirrel's input engine.
- Push, public release, notarization, or external binary distribution.

See [FOUNDATION.md](docs/round0/FOUNDATION.md) for the design decisions and [VERIFICATION.md](docs/round0/VERIFICATION.md) for the actual evidence ledger. Only verified results should be presented as passing in delivery notes.

## 2026-10-11 — Round 0 runtime follow-up

The user authorized normal librime generated-file/database maintenance only in LiangYi data/log roots. The first actual launch exposed percent-encoded URL paths; the process was stopped and incident files retained. Decoded filesystem strings now reach librime and directory checks, and `--build` explicitly sets its own shared-data source. The fixed build passed startup/deployment, idle reload and 30 standalone real-engine synthetic checks. A GPL-3.0-only C probe was added without new dependencies; it is not bundled in the app. The static verifier no longer reports a stale policy blocker.

The initial installed bundle is unchanged, unfixed and disabled. Manual replacement and actual IMK host checks remain pending under the no-deletion/existing-target rule. See [runtime acceptance](docs/round0/RUNTIME_ACCEPTANCE.md) and [manual steps](docs/round0/MANUAL_ACCEPTANCE.md). No Round 1, push or distribution occurred.

## 2026-10-11 — Round 1 state, commit and example panel

The preceding Round 0 entries preserve their original delivery-time state.
The user later removed the old bundle; the fixed Round 0 was installed and
closed out in `92fb453`, with disclosed host/visual limitations.

Round 1 adds session/focus/revision snapshots, an ASCII token composer, a shared
key policy, one guarded commit coordinator and an Objective-C selector/exception
adapter. Existing Squirrel InputController, ApplicationDelegate, Main, bridge,
Panel/View and Xcode project are modified to integrate them. Panel/View now
render horizontal primary/subtitle columns without a second UI dependency.
Option+Return submits only a ready, displayed, verified whole-candidate example.
Engine reset/quit and focus changes invalidate old tasks; raw/translated commit
clears the old engine composition before inserting.

Added Swift/ObjC tests and reviewed Python/C check entry points cover state,
layout, host exceptions and the pinned real engine. Authored fixtures have ten
entries per direction; they are source-owned deterministic examples, not a new
third-party dictionary. No dependency, provider, network call or captured host
text was added. The development bundle version is 0.0.2. Upstream copyright,
GPL and dependency/data notices remain preserved.

See [Round 1 delivery](docs/round1/DELIVERY.md) for final artifacts, verification
and limits. Installed Round 1 input acceptance is pending; the current installed
package remains the fixed Round 0. Complete corresponding-source preparation
remains an external-distribution gate. No Round 2, push or release occurred.
