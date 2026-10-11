# Third-party notices and review ledger

Recorded: 2026-10-11, America/New_York.

Status: **initial inventory; distribution review is incomplete**.

This ledger distinguishes imported frontend code, engine/framework dependencies, input data, artwork, and outbound services. It is not a substitute for the original license texts or an assertion that all dependencies of a future binary have been reviewed. The authoritative scope is the actual locked source and artifact inventory used to produce that binary.

## Imported frontend

### Squirrel

- Project: [rime/squirrel](https://github.com/rime/squirrel).
- Source revision: `769ae426f33f500266101a88f694aab0d158e680`.
- Imported into this project with upstream history in local commit `8b507af`.
- License: **GNU General Public License version 3**, as identified by the upstream README and retained in [LICENSE.txt](LICENSE.txt).
- Do not infer an “or later” grant from the generic GPL document's example text.
- Preserve source authorship, copyright notices, and disclaimers. Mark derived changes and their dates in [CHANGES_FROM_UPSTREAM.md](CHANGES_FROM_UPSTREAM.md).
- This project does not claim to be an official Squirrel release or claim ownership of upstream branding.

The [preserved upstream README](docs/upstream/README.squirrel.md) acknowledges programming contributors including 佛振, Linghua Zhang, Chongyu Zhu, 雪齋, faberii, Chun-wei Kuo, Junlu Cheng, Jak Wings, and xiehuc. It credits icon design to 佛振, 梁海, and 雨過之後, and color schemes to Aben, Chongyu Zhu, skoj, Superoutman, 佛振, and 梁海. These acknowledgments and per-file attribution remain preserved.

## Direct engine and framework references

| Component | Pinned baseline | License identification | Evidence / distribution action |
| --- | --- | --- | --- |
| librime | `33e78140250125871856cdc5b42ddc6a5fcd3cd4` / v1.17.0 | BSD-3-Clause | [Pinned license](https://github.com/rime/librime/blob/33e78140250125871856cdc5b42ddc6a5fcd3cd4/LICENSE). Preserve the exact license and copyright text; inventory compiled plugins and transitive libraries separately. |
| Sparkle | `41847a58cdef7506b257591fcca6f9495df591d4` / 2.6.2 | MIT | [Pinned license](https://github.com/sparkle-project/Sparkle/blob/41847a58cdef7506b257591fcca6f9495df591d4/LICENSE). Excluded from preparation, compilation, linking, and the Round 0 bundle. Historical source references remain preserved; reintroduction requires a renewed inventory. |
| plum | `b1be1969f914cc005add4090631b855db00c2591` | LGPL v3 identified by the imported Squirrel README; exact grant/text still to be checked for any distributed copy | An inherited Gitlink is not evidence that the installer or its fetched data is included. Do not execute package installation or claim its fetched schemas are covered by the tool's license. |

This table identifies source references. [dependencies.lock.json](dependencies.lock.json) records selected archive URLs/checksums and notice-source hashes. Downloaded-byte and bundled-resource checks are reported for the exact artifact in [VERIFICATION.md](docs/round0/VERIFICATION.md). Complete corresponding-source and recursive licensing closure remain pending; passing those build checks does not make a release distribution-ready.

## Recursive code dependencies

The upstream README and Makefile mention components including Boost, capnproto, darts-clone, glog, Google Test, LevelDB, OpenCC, UTF8-CPP, yaml-cpp, and marisa. This historical list is not a final software bill of materials: some entries may be build/test-only, optional, or absent from the selected release artifact.

For each actually selected component, the build inventory must record:

1. Repository or archive origin and exact revision/version.
2. A cryptographic hash for any downloaded artifact.
3. Build-only versus runtime/distributed role, including static linking.
4. Exact license and any NOTICE/copyright requirements.
5. Corresponding source location and any required modifications/build scripts.
6. Whether the material is copied into the application or only used to build it.

The dependency lock records recursive source revisions and notice sources; this is inventory progress, not a completed recursive source/license or binary audit. That final review remains **NOT_RUN** in this initial ledger. Optional Rime plugins and additional model downloads are excluded from the Round 0 application assembly. Do not convert this section into a claim that every historically listed project is bundled.

## Schemas, dictionaries, conversion tables, and artwork

The selected baseline is `luna_pinyin_simp`. [data/schema-manifest.json](data/schema-manifest.json) records runtime files, pinned raw sources, hashes, LICENSE files, and AUTHORS files for the following packages:

| Package | Revision | License text identified in package root |
| --- | --- | --- |
| rime-prelude | `082425ea0684bca36474415d4a0e8db9b016487e` | GNU Lesser General Public License version 3. |
| rime-luna-pinyin | `56b934b099dfbeab842320f13aa8b461a6ab3e42` | GNU Lesser General Public License version 3. |
| rime-stroke | `1e8fff9b9494ddec23b0cbc526bcfd8171a6fd48` | GNU Lesser General Public License version 3. |
| rime-essay | `054920de4f54c9e5994276a96a4fc2a35cb51aa3` | GNU Lesser General Public License version 3. |

These identifiers describe the supplied root license texts; they do not invent an `or-later` grant or clear all imported data rights by assumption. Keep per-file notices and AUTHORS, review any inherited data sources, and verify actual bundle contents before distribution.

| Resource class | Current handling | Required evidence |
| --- | --- | --- |
| `data/squirrel.yaml` frontend configuration | Imported at the pinned Squirrel revision. | Preserve attribution and inspect any additional included resources. |
| Pinyin schema, lexicon, and essay data | Selected and recorded in `data/schema-manifest.json`; final resource audit pending. | Verify repository/revision, original sources, license, transformations, and actual shipped files against the manifest. |
| OpenCC conversion data | Comes from the selected dependency artifact; final content/license mapping pending. | License and provenance for both conversion code and data; do not assume they are interchangeable. |
| Plugins and schema imports | Optional plugins excluded; selected-schema import closure still requires artifact verification. | Resolve referenced files and dependencies; top-level schema licensing is insufficient by itself. |
| Inherited icons and visual resources | Retained as upstream material pending resource-level review. | Preserve design credits, confirm applicable redistribution terms, and avoid upstream endorsement claims. |
| Future bilingual translation dictionary | Not selected or implemented in Round 0. | Independent code/data license review in Round 2; a pinyin lexicon is not a translation dictionary. |
| Future local model weights/tokenizers | Not selected or bundled in Round 0. | Review model/data license and distribution requirements before introduction. |

If a data resource lacks a clear grant, exclude it from an accepted distribution until the uncertainty is resolved. Do not fill the gap by assigning the enclosing application's GPL license to independently sourced data.

## Outbound services

No model API adapter, API credential, or cloud-translation request is implemented or validated by this Round 0 inventory. Future support for DeepSeek, GLM, OpenAI, Kimi, Claude, Gemini, MiMo, MiniMax, or custom endpoints does not license any provider's service or establish endpoint compatibility.

Service terms, user consent for outbound text, credential handling, and model-output handling are separate from the licensing of the local application. Remote API use must not be described as bundling provider model code. Conversely, a process boundary is not by itself sufficient to relicense tightly coupled local code.

## Gate before any external binary distribution

The gate applies to an external test build as well as a public release:

- Preserve the GNU GPL version 3 text, relevant notices, disclaimers, and modification records.
- Identify the exact application version, source commit, dependencies, data, and binary checksums.
- Prepare the complete corresponding source for the distributed covered work, including necessary submodule content, non-system dependency source, modifications, interface definitions, and build/install scripts as applicable.
- Provide a documented local-signing build path that does not depend on a private publisher certificate.
- Supply license/NOTICE material for the actual dependencies and resources; validate data rights independently.
- Verify the chosen source-delivery method under GPLv3 section 6. Do not rely solely on a moving branch or an automatically generated root-only archive.
- Inspect the produced application bundle and source archive rather than only source-tree templates.
- Preserve recipients' rights to modify and redistribute under the applicable licenses.
- Obtain separate user authorization for the intended external distribution or publication.

The applicable primary terms are retained in [LICENSE.txt](LICENSE.txt). Official references checked for this plan are [GPLv3 section 1: Corresponding Source](https://www.gnu.org/licenses/gpl-3.0.en.html#section1), [section 4: notices and license copies](https://www.gnu.org/licenses/gpl-3.0.en.html#section4), [section 5: modification notices, dates, and modified works](https://www.gnu.org/licenses/gpl-3.0.en.html#section5), and [section 6: binary distribution methods](https://www.gnu.org/licenses/gpl-3.0.en.html#section6).

For planned network downloads, use a reviewed section 6(d) delivery arrangement with clear source-access instructions adjacent to the binary and continued source availability. A separate source server is allowed under those conditions; an arbitrary GitHub link alone is not proof of compliance. The [GNU FAQ on separate source hosting](https://www.gnu.org/licenses/gpl-faq.en.html#SourceAndBinaryOnDifferentSites) and [exact corresponding versions](https://www.gnu.org/licenses/gpl-faq.en.html#DistributeExtendedBinary) explain this distinction. Private modifications need not be published merely because they exist; [the GNU FAQ on private modifications](https://www.gnu.org/licenses/gpl-faq.en.html#GPLRequireSourcePostedPublic) does not remove the obligations triggered by conveying a covered binary.

The disabled inherited CI/release workflows do not discharge any licensing requirement, and they are not a claim that a source or binary release has been tested. This review ledger is project preparation, not a compliance certificate or a declaration that distribution is ready. No external distribution has been authorized.
