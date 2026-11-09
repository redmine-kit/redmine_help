# Setup

## Requirements

- Redmine 7.0 or later (checked with 7.0.3)
- Redmine's CommonMark formatter (`commonmarker`, in Redmine's Gemfile); the help is Markdown whatever text formatting Redmine is set to

## Installation

### gem

Each version tag publishes the plugin as a gem to GitHub Packages (`https://rubygems.pkg.github.com/redmine-kit`). Installing from GitHub Packages needs a GitHub token with `read:packages`, even for a public package. Add the plugin and the guide to `Gemfile.local`, install them, and link the plugin into `plugins/`:

```ruby
source 'https://rubygems.pkg.github.com/redmine-kit' do
  gem 'redmine_help'
  gem 'redmine-guide'
end
```

```sh
bundle install
ln -s "$(bundle info --path redmine_help)" plugins/redmine_help
```

Restart Redmine. The plugin has no migrations.

### Without the gem

Clone the plugin into `plugins/` and the guide anywhere, and point the plugin at the guide:

```sh
git clone https://github.com/redmine-kit/redmine_help.git plugins/redmine_help
git clone https://github.com/redmine-kit/redmine-guide.git /srv/redmine-guide
export REDMINE_HELP_GUIDE_PATH=/srv/redmine-guide
```

## The guide

The guide's content (Markdown in `en/`, `ja/`, the sections in `index.yml` and the screens in `map.yml`) is not in this plugin. It is [redmine-guide](https://github.com/redmine-kit/redmine-guide), so that the guide can follow redmine.org and be translated on its own schedule. The plugin finds it in this order:

1. `REDMINE_HELP_GUIDE_PATH`: a checkout of redmine-guide
2. the gem `redmine-guide`, when Bundler has loaded it

Without the guide, the help shows only the help of other plugins and the operator's pages; the contents say that no guide is installed.

## Configuration

| Key | Description | Parameter |
| --- | --- | --- |
| `REDMINE_HELP_GUIDE_PATH` | The guide's directory (a checkout of redmine-guide) | Optional. Default: the gem `redmine-guide` |
| `REDMINE_HELP_EXTRA_PATH` | The operator's directory: added pages, support blocks, replaced topics ([extending.md](extending.md#the-operators-directory)) | Optional |

The Help link opens in a new tab, as Redmine's own link does.

## Tests

The tests run in Docker with Redmine 7.0.3 and PostgreSQL 16:

```sh
bin/test              # the plugin's tests
bin/test --redmine    # also every Redmine test, with the plugin installed
REDMINE_BRANCH=master bin/test
bin/services --down   # stops PostgreSQL
bin/lint              # RuboCop
```

The tests use the small guide in `test/fixtures/help`, not redmine-guide. The screenshots of these docs are made with `bin/screenshots`.
