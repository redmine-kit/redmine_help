# AGENTS.md

Guidelines for people and coding agents working in this repository. See [README.md](README.md) for an overview and [docs/](docs/README.md) for the details. The organization's rules are in `../AGENTS.md` (outside this repository, next to the other redmine-kit checkouts).

## What this project does

Redmine Kit Help (`redmine_kit_help`) is a Redmine plugin that points the header's Help link at help for the current screen, in the user's language, shown inside Redmine. The plugin holds the code only. The Redmine guide's content (Markdown, sections, the map from screens to topics) is [redmine-guide](https://github.com/redmine-kit/redmine-guide); other plugins ship their own `help/`; operators add a directory of their own (`REDMINE_KIT_HELP_EXTRA_PATH`).

## Rules

- **Redmine's extension points only:** do not edit Redmine's own files. The plugin replaces only the `:help` item of the top menu.
- **Screens like Redmine's:** the help pages follow Redmine's wiki page (`.wiki.wiki-page`, Redmine's heading anchors and table of contents, the sidebar) and search results (`dl#search-results`). See the organization's rule on Redmine screens.
- **No guide content here:** the guide's pages, translations, `index.yml` and `map.yml` belong to redmine-guide. Tests use the small guide in `test/fixtures/help`.
- **Safe file access:** topics and images are read only from inside a source's directory; never show a raw exception.
- **Tests:** `bin/test` (Apple container or Docker, Redmine 7.0.3, PostgreSQL 16). Mapping, fallback, precedence and the header link have tests.
- **The new UI's module** (`frontend/`, docs/README.md "The new UI"): its components use only `@redmine-kit/ui` and `@redmine-kit/plugin` and read the help's JSON (`RedmineKit::Help::Json`, the same library and map as the pages). After a change to `frontend/src/`, run `bin/setup` once, then `npm run check` in `frontend/` (type check, tests, build, `kit-check-ui`), and commit `assets/javascripts/kit/help.js` and `assets/stylesheets/kit/help.css`. The new UI's screens map to Redmine's in `config/kit_screens.yml`; the topics stay in map.yml.
- **No secrets in the repository.**

## Translations

The organization's translation rules apply to this plugin's locale files and docs, and to every help page:

- **Interface terms exactly as Redmine shows them.** A menu, tab, field, button, setting, permission or status name in a translation is the string from Redmine 7.0.3's `config/locales/<lang>.yml` (and the plugin's own locale files for plugin screens). Look it up; do not translate it again.
- **Consistent terms**, following redmine-guide's glossary (`glossary/<lang>.yml`).
- **Natural and precise**, as a native technical writer would write it; nothing added or dropped.
- **Japanese wording:** 「通知」 not 「知らせ」, 「確認」 not 「確かめ」, 「インストール」, 「コピー」, 「バージョンアップ」, 「例外を発生させる」, no 「版」 for a version.
- **Review** each translation against the English and the screen before committing.

## Documentation

- **Two languages.** English is the source (`README.md`, `docs/`); the Japanese translation is `README.ja.md` and `docs/ja/`, with the same file names. Change both together.
- **One language per document.** The English documents are in English only and name the UI with the English locale's strings (Redmine's and this plugin's `config/locales/en.yml`); Japanese appears only in the link to the translation, a strings table's `ja` column or a value an example must match (`../AGENTS.md` › Writing › Translations).
- **Anchors in Japanese.** Put `<a id="..."></a>` with the English heading's anchor before each Japanese heading.
- **Commands** to run go in `sh` blocks with a lead sentence, not inside a sentence.
- **Facts.** State only what has been checked, with the date and the source.

## Commits

- English, imperative mood, 72 characters or fewer in the first line, no trailing period.
- One purpose per commit.
- Do not rewrite pushed history.

## Development environment

- **Apple container first, Docker too** (a public repository). Scripts (`bin/test`, databases, emulators) use Apple container (`container`) when it is installed and running, else Docker (other machines, CI); `CONTAINER_CLI=docker|container` chooses. Docs give both, Apple container first. Images are built from the `Dockerfile` with either tool. In Apple container, the test containers run on the networks that every repository shares, `redmine-kit-test` and `redmine-kit-test-internal` (no way out), each with an anchor container that runs all the time (`ensure_shared_network` in `bin/container_cli`; apple/container#2051, until macOS 27.3; the organization's `../AGENTS.md`). Docker keeps a Compose network per repository.
- **Libraries at their latest versions.** Dependencies are kept at their latest stable releases, pinned exactly in the lockfiles; a version held back has its reason next to the pin.
- Both are the organization's rules (`../AGENTS.md`, "Development environment").
