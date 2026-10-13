# Changes from Squirrel

Derived project: **LiangYi / 两仪 — EcholME**.

Baseline: Squirrel [`769ae426f33f500266101a88f694aab0d158e680`](https://github.com/rime/squirrel/tree/769ae426f33f500266101a88f694aab0d158e680).

This is a modification record for the derived project. It does not replace upstream copyright notices, [LICENSE.txt](LICENSE.txt), or the upstream [CHANGELOG.md](CHANGELOG.md). Changes belong to their recorded Git authors; imported work retains its original attribution.

## 2026-10-13 — Round 3 temporary secure-input recovery

Version 0.0.8 separates the live Secure Event Input flag from AX secure-field
evidence. Release schedules a bounded metadata-only review; waiting input stays
literal with translations disabled. Request/focus identity rejects stale work,
and known secure fields retain protection. Off pauses capture. Synthetic policy,
capture and async regressions cover release, renewed protection, cancellation,
unavailable metadata and focus races. No dependency, cloud feature or runtime
permission prompt is added. The delivered 0.0.7 installation remains separate
from this repair; real IMK recovery requires acceptance on the repaired bundle.
See [Round 3 delivery](docs/round3/DELIVERY.md) for evidence and remaining limits.

## 2026-10-12 — Round 3 context, rules and mode controls

Add a bounded AX adapter, local Chinese/Latin-script classifier, deterministic
priority resolver, versioned request gate, validated preference store,
nonactivating mode HUD and basic native settings/About UI. IMK clients stay on
the UI thread. Ordinary input uses rules/defaults when context is absent.
Text analysis is Auto-only and never queries whole-field AXValue. Secure fields
and Secure Event Input bypass composition/translation; Off explicitly finishes
raw text before passthrough. Late preedit/focus results cannot change direction.
Legacy app_options/ascii_mode is replaced by the unified resolver; other schema
options remain available. No new third-party dependency or cloud backend is added.

Version 0.0.7 integrates these modules into the Squirrel controller/project.
Synthetic policy/capture/queue/store regressions and an offscreen settings
preview accompany the prior dictionary, commit and real-librime checks.
Installed acceptance remains a separate gate in [Round 3 delivery](docs/round3/DELIVERY.md).
GPL source headers, upstream history/notices and separate CC-CEDICT attribution
are retained. Public corresponding-source review and distribution are not done.

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

## 2026-10-11 — Round 1 Shift repair

The user authorized fixing two P1 review findings in the existing Round 1
branch. CompositionState/InputController now own both Shift gesture streams,
finalize raw input before left-tap mode changes, replay only a confirmed right
tap through the schema, retain its Caps Lock mask, and prevent a frontend
English buffer from replacing live engine-owned inline input. Focus, mode and
engine resets discard pending gestures; reentrant host changes block replay.
The development bundle version is 0.0.3.

New source-owned Swift regressions exercise the production router with pinned
librime and a synthetic host under the existing confined C probe lifecycle.
Core checks also cover both Shift paths and stale focus/cancellation. No new
dependency/data, captured input, external request or installation is added.
See the Round 1 delivery/status records for measured results and remaining
installed-IMK acceptance. Inherited licenses and notices remain preserved.

## 2026-10-12 — Round 2 offline dictionary

Production subtitles now come from a pinned CC-CEDICT index instead of the ten
hand-authored fixtures. The fixtures remain only for the state-machine tests.
Chinese candidates receive one English subtitle, and English tokens receive one
Chinese subtitle. Option+Return still commits that displayed subtitle only when
it covers the whole composition. A miss and a timeout are different states, and
a timeout is not cached as a miss. Primary input still commits when translation
is unavailable.

The dictionary data stays under CC-BY-SA-4.0. GPL notices on project source are
unchanged. No cloud client, context detector, or new code dependency was added.
The development bundle version is 0.0.4. Installed IMK acceptance and visible
panel latency remain unverified. See the Round 2 delivery record.

## 2026-10-12 — Primary-language switching repair

On top of the repeated-flags fix in `992d5ea` (0.0.5), version 0.0.6 preserves
known left/right Shift identity for anonymous modifier events and recovers
held state after a release omitted before a typed key. Ambiguous overlapping
events cannot manufacture mode changes. Input-source menu entries explicitly
select Chinese or English through guarded raw finalization; choosing the same
language leaves pending text intact. Activation uses the same language labels
as mode changes, and inactive controllers do not answer mode queries.

Production-router/engine tests cover these changes. The installed 0.0.4 app
remains untouched, and repaired physical-keyboard/menu acceptance is NOT_RUN.
No dependency, dictionary update, cloud call, context detector, or public
distribution was added. Existing GPL and data notices remain unchanged.
