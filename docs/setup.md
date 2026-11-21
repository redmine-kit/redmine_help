# Setup

## Requirements

- Redmine 7.0 or later (checked with 7.0.3), on Ruby 3.2 to 4.0
- Redmine's CommonMark formatter (`commonmarker`, in Redmine's Gemfile); the help is Markdown whatever text formatting Redmine is set to

## Installation

### gem

The plugin is installed as a gem (first choice) or as a folder in `plugins/`. Each version tag publishes the plugin as a gem to GitHub Packages (`https://rubygems.pkg.github.com/redmine-kit`). Installing from GitHub Packages needs a GitHub token with `read:packages`, even for a public package. Add the plugin and the guide to Redmine's `Gemfile.local`:

```ruby
source 'https://rubygems.pkg.github.com/redmine-kit' do
  gem 'redmine_kit_help'
  gem 'redmine-guide'
end
```

Then install them:

```sh
bundle install
```

Restart Redmine. Redmine loads the plugin from the gem's folder; nothing goes into `plugins/`. The plugin has no migrations. A checkout of the plugin in `plugins/redmine_kit_help` takes the place of the gem.

### Without the gem

Clone the plugin into `plugins/` and the guide anywhere, and point the plugin at the guide:

```sh
git clone https://github.com/redmine-kit/redmine_help.git plugins/redmine_kit_help
git clone https://github.com/redmine-kit/redmine-guide.git /srv/redmine-guide
export REDMINE_KIT_HELP_GUIDE_PATH=/srv/redmine-guide
```

## The guide

The guide's content (Markdown in `en/`, `ja/`, the sections in `index.yml` and the screens in `map.yml`) is not in this plugin. It is [redmine-guide](https://github.com/redmine-kit/redmine-guide), so that the guide can follow redmine.org and be translated on its own schedule. The plugin finds it in this order:

1. `REDMINE_KIT_HELP_GUIDE_PATH`: a checkout of redmine-guide
2. the gem `redmine-guide`, when Bundler has loaded it

Without the guide, the help shows only the help of other plugins and the operator's pages; the contents say that no guide is installed.

## Configuration

| Key | Description | Parameter |
| --- | --- | --- |
| `REDMINE_KIT_HELP_GUIDE_PATH` | The guide's directory (a checkout of redmine-guide) | Optional. Default: the gem `redmine-guide` |
| `REDMINE_KIT_HELP_EXTRA_PATH` | The operator's directory: added pages, support blocks, replaced topics ([extending.md](extending.md#the-operators-directory)) | Optional |

The Help link opens the side panel ([README.md](README.md#side-panel)). Without JavaScript, it opens the help page in a new tab, as Redmine's own link does.

## Tests

The tests run in a container with Redmine 7.0.3 and PostgreSQL 16 ([Apple container](https://github.com/apple/container) when it is installed and running, else Docker; `CONTAINER_CLI=container` or `CONTAINER_CLI=docker` chooses); the system tests of the side panel (`test/system`) run in headless Chromium:

```sh
bin/test              # the plugin's tests
bin/test --redmine    # also every Redmine test, with the plugin installed
bin/test-gem          # the plugin installed as a gem: from the gem's folder, then a checkout in plugins/
REDMINE_BRANCH=master bin/test
COVERAGE=1 bin/test   # with the coverage in coverage/coverage.xml
bin/services --down   # stops PostgreSQL and Chromium
bin/lint              # RuboCop (in the same container tool)
```

With `COVERAGE=1`, the plugin's tests also write the coverage of the plugin's own files (SimpleCov, Cobertura XML in `coverage/coverage.xml`). CI sets it on Redmine 7.0.3 and uploads the report to [Codecov](https://codecov.io/gh/redmine-kit/redmine_help) with the flag `plugin`. The upload authenticates with OIDC (`id-token: write`), so no token is stored as a secret. Codecov's statuses are informational and never fail a commit or a pull request (`codecov.yml`).

The tests use the small guide in `test/fixtures/help`, not redmine-guide. The screenshots of these docs are made with `bin/screenshots` (Docker only for now).
