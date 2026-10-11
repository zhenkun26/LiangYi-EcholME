# Upstream provenance

Recorded: 2026-10-11, America/New_York.

LiangYi / 两仪 (EcholME) is a derived macOS input method based on [Squirrel](https://github.com/rime/squirrel). It is not an official Squirrel release. Upstream copyright notices, authorship, and license text remain applicable to their respective work.

## Imported source baseline

| Item | Recorded value |
| --- | --- |
| Upstream repository | `https://github.com/rime/squirrel.git` |
| Imported Squirrel revision | `769ae426f33f500266101a88f694aab0d158e680` |
| Upstream commit subject | `fix(ui): clear stale paging hit-test paths (#1183)` |
| Local approved-plan commit | `041b643` |
| Local baseline-import commit | `8b507afeada55075b5d863debbaca1e6991ab807` |
| Import method | Git merge retaining the upstream history and the prior planning commit. |
| Product route | Squirrel-derived Swift/InputMethodKit frontend with librime. |
| Inherited frontend license | GNU General Public License version 3; [LICENSE.txt](LICENSE.txt). |

The imported README identifies the license as “GPL v3.” This record does not expand the grant to “or any later version” or relabel inherited code with a permissive license. The original README is preserved at [docs/upstream/README.squirrel.md](docs/upstream/README.squirrel.md), and the original source remains inspectable at the pinned revision even where project-facing documentation is updated.

## Inherited submodule references

These values are recorded from the imported Git tree. A Gitlink proves the recorded source reference, not that its content has been downloaded, built, audited recursively, or included in a binary.

| Component | Repository | Pinned reference | Round 0 role |
| --- | --- | --- | --- |
| librime | `https://github.com/rime/librime.git` | `33e78140250125871856cdc5b42ddc6a5fcd3cd4` / v1.17.0 baseline | Chinese input engine and C API. |
| Sparkle | `https://github.com/sparkle-project/Sparkle` | `41847a58cdef7506b257591fcca6f9495df591d4` / 2.6.2 baseline | Historical reference only; excluded from preparation, compilation, linking, and the Round 0 bundle. |
| plum | `https://github.com/rime/plum.git` | `b1be1969f914cc005add4090631b855db00c2591` | Inherited package-management reference; not authorization to execute its installer or fetch unpinned schemas. |

The selected artifact/header/notice sources are recorded in [dependencies.lock.json](dependencies.lock.json). The baseline schema is `luna_pinyin_simp`, with fixed prelude, luna-pinyin, stroke, and essay resources recorded per file in [data/schema-manifest.json](data/schema-manifest.json). Optional Rime plugins and additional model downloads are excluded from the Round 0 application assembly. Do not treat these locks as a complete corresponding-source closure: exact notice copies, artifact contents, transitive source, and reproducible source delivery still require verification.

## Product separation

The Round 0 design selects:

- Bundle/input-method identity root: `io.github.zhenkun26.inputmethod.EcholME`.
- User installation target: `~/Library/Input Methods/EcholME.app`.
- User Rime data: `~/Library/Application Support/LiangYi/Rime/`.
- Logs: `~/Library/Logs/LiangYi/`.
- Input-mode IDs: `io.github.zhenkun26.inputmethod.EcholME.Hans` and `.Hant`; IMK connection: `EcholME_Connection`.
- Independent preference domain and distributed notifications under `io.github.zhenkun26.inputmethod.EcholME.*`.
- No inherited Squirrel update feed or runtime automatic updater.

Source implementation and runtime coexistence are separate checks. See [Round 0 foundation](docs/round0/FOUNDATION.md) and [verification](docs/round0/VERIFICATION.md) for evidence status.

Existing source class names, Xcode project names, internal resource keys, and Rime configuration conventions may remain where they do not collide with another installed product. Their preservation reduces unnecessary upstream divergence and does not make the resulting bundle an official Squirrel build.

## Maintaining the derived project

- Keep the upstream remote read-only unless a separate upstream contribution is authorized.
- Record the current imported upstream revision before attempting a future merge. Do not replace the pinned baseline with a moving branch silently.
- Keep EcholME translation/context/commit services separate from upstream platform handling as later rounds implement them.
- Preserve upstream notices and describe meaningful modifications in [CHANGES_FROM_UPSTREAM.md](CHANGES_FROM_UPSTREAM.md).
- Review upstream changes and their script side effects before adoption; source code in the repository is not permission to run every installer, cleanup task, or release workflow.
- Retain the inherited GitHub workflows as upstream reference, but guard their jobs with `github.repository == 'rime/squirrel'` so a later authorized push of this derived project cannot accidentally execute their package/release steps. The guard is not a replacement for a new reviewed EcholME CI workflow, and no CI pass is claimed.
- Do not move to another implementation round or publish the project without the user's authorization.

## License and source delivery

[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) tracks the initial inventory and outstanding review. Its existence does not certify a complete binary distribution.

Before giving an application binary to an external tester or publishing it, prepare the corresponding source, required dependency sources, notices, and build/install material for that exact binary. A link to a moving main branch or a root-only GitHub archive is not the project's source-delivery strategy. No external binary distribution is authorized in Round 0.
