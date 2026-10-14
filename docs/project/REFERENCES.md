# Open-source references and learning record

Recorded: 2026-10-14, America/New_York.

This record acknowledges the projects considered while planning LiangYi /
两仪 (EcholME). A reference is not automatically a dependency or permission to
copy code. Directly imported material is tracked separately in [UPSTREAM.md](../../UPSTREAM.md),
[THIRD_PARTY_NOTICES.md](../../THIRD_PARTY_NOTICES.md) and the locked inventories.

## Adopted implementation baseline

| Project | Role in EcholME | Reuse and learning |
| --- | --- | --- |
| [Squirrel / 鼠须管](https://github.com/rime/squirrel) | Direct frontend derivative; imported revision `769ae426f33f500266101a88f694aab0d158e680`, with upstream history. | Reuse the native InputMethodKit host, lifecycle, Rime integration and candidate Panel/View. Adapt independent identity/storage, guarded commit state, language controls and horizontal primary/subtitle columns. Keep upstream attribution and GPL text. Changes are recorded in [CHANGES_FROM_UPSTREAM.md](../../CHANGES_FROM_UPSTREAM.md). |
| [librime](https://github.com/rime/librime) | Runtime Chinese engine; pinned baseline `33e78140250125871856cdc5b42ddc6a5fcd3cd4` / v1.17.0. | Reuse mature pinyin composition, candidates, dictionary deployment and session APIs. Keep frontend state, translation and host writes separate from engine ownership. Engine validation does not establish real IMK behavior. BSD-3-Clause and recursive dependency materials remain independently tracked. |

## Comparison and learning references

The topics below are learning targets supported by the linked upstream
documentation, not claims that all their features have been ported or tested.
No code or standalone components from these alternative projects were imported
in the current Squirrel-derived delivery.

| Project | Why it was considered | Applicable learning and boundary |
| --- | --- | --- |
| [Metasequoia / 水杉 — Windows](https://github.com/metasequoiaime/msime-windows) | The user supplied this project as the initial product reference. Its upstream describes a Windows TSF product with separate server, GUI/settings and installer areas. | Study the bilingual-candidate experience, separation of typing from asynchronous services, configuration boundaries, compatibility fixtures and diagnostics. Translate principles into IMK contracts; Windows TSF implementation is not a macOS host. Repository licensing is GPL-3.0; any future copied material needs exact revision and per-file provenance. |
| [Metasequoia / 水杉 — macOS](https://github.com/metasequoiaime/msime/blob/develop/platforms/macos/README.md) | A native-platform comparison for input-source identity, lifecycle, candidate appearance and shared runtime boundaries. | Study separate input-method/settings identities, mode representation, copied runtime views and commit context, host integration and installation troubleshooting. The historical [MSIME-Apple link](https://github.com/metasequoiaime/MSIME-Apple) currently resolves to the consolidated `metasequoiaime/msime` repository; this alias was checked through GitHub on 2026-10-14. No claim is made that its current architecture matches an earlier planning snapshot. |
| [McBopomofo / 小麦注音](https://github.com/openvanilla/McBopomofo) | Compared as the source of native macOS components for an alternative independent-host route. | Its [architecture documentation](https://github.com/openvanilla/McBopomofo/wiki/%E7%A8%8B%E5%BC%8F%E6%9E%B6%E6%A7%8B) is useful for state/key/handler separation, Swift UI with C++ engine bridging, punctuation and user overrides. MIT repository license is distinct from a component/data audit. CandidateUI and InputSourceHelper remain references; EcholME currently reuses Squirrel's panel. |
| [Fcitx5 macOS](https://github.com/fcitx/fcitx5-macos) | Compared as a framework/engine/plugin-oriented macOS route. | Its [README](https://github.com/fcitx/fcitx5-macos/blob/master/README.md) provides a reference for framework boundaries, plugin management and a non-Xcode build structure. These are comparison topics, not a reason to add its dependency/toolchain stack to the selected Squirrel route. Repository GPL-3.0 identification is not an audit of every plugin. |

The current repository identities and high-level license labels for librime,
Metasequoia, McBopomofo and Fcitx5 were checked through GitHub on the recorded
date. The Squirrel grant and imported provenance are retained locally. Moving
upstream READMEs may change; future copying must pin the exact source and retain
the required notices instead of relying on this comparison table.

## Data provenance and future adoption

The offline subtitle dictionary comes from a pinned MDBG CC-CEDICT export,
under CC-BY-SA-4.0. It is data rather than an alternative input-method host;
[the data notice](../../data/lexicon/NOTICE.txt) and [manifest](../../data/lexicon/manifest.json)
record attribution, transformations, counts and hashes. Existing Rime schemas,
essay scores and conversion resources keep their separate provenance.

Before adopting material from a comparison project, record the repository,
commit, source paths, purpose, modifications, license and notice requirements.
Define the host/thread/lifecycle contract and run the relevant regressions.
Add dependencies only with the user's approval. An upstream demo, source review
or another project's test result is not an EcholME acceptance result.
