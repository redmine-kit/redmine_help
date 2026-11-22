# Adding help

## Directory layout

The guide, a plugin's help and the operator's directory have the same layout:

```text
index.yml          # sections of the sidebar
map.yml            # screens to topics (mapping.md)
en/                # one directory per language
  <topic>.md       # a topic; its first # heading is its title
  _support.md      # (operator only) a block shown on every page
  _support/<topic>.md  # (operator only) a block shown on one topic
  _insertions/<name>.md  # (plugins only) a section for a topic of the guide
ja/
  <topic>.md
images/            # images the topics show, by relative links
```

`index.yml` lists sections and their topics. A topic is its id, or an id with a label for the sidebar, used while the topic is not translated into the user's language (a translated topic shows its own heading):

<!-- ja-ok-block: an index.yml with titles in two languages -->
```yaml
sections:
  - id: support
    title: { en: Support, ja: サポート }
    topics:
      - support/contact
      - { id: support/hours, title: { en: Opening hours, ja: 受付時間 } }
```

A topic missing in the user's language is shown in English, with a note.

The plugin reads these files once, the first time the help needs them, and keeps them in memory: restart Redmine after changing them (in development, a changed file is read again). An `index.yml` or `map.yml` that is not valid YAML, or not a mapping, is left out, with a warning in Redmine's log that names the file; the other files and directories still work.

## Plugins

A Redmine plugin adds help by shipping a `help/` directory at its root with the layout above. Redmine Kit Help finds it in every installed plugin; nothing needs to be registered. The plugin's sections come after the guide's in the sidebar, and its `map.yml` maps the plugin's screens (its controllers) to its topics. Name the topics under the plugin's own directory (for example `aws-ses/sending`) so that they do not clash with the guide's.

### Screens of the new UI

A plugin's screens in Redmine Kit UI's new UI (the `screens` of its manifest) need nothing more: the new UI names a plugin's screen `<plugin>:<component>`, and Redmine Kit Help looks up the Redmine route of the screen's path in the manifest, so the screen opens the topic that `map.yml` gives the route's controller and action, as in Redmine's own UI. A component that several screens draw (a new and an edit form) is looked up by its first screen in the manifest; map the controller (`checklist_items`) to give its actions one topic. A tab the plugin adds to a project's settings is `projects#settings?tab=<tab>` in both UIs ([mapping.md](mapping.md#the-new-ui)).

### Sections in the guide's topics

A plugin that changes one of Redmine's screens (an issue, a project's settings, Administration) adds a section to the guide's topic of that screen, so that the reader finds it where the screen is described. Each section is a Markdown file in `<language>/_insertions/`. The English file starts with front matter that names the guide's topic and the English anchor of the heading after whose section it goes ([mapping.md](mapping.md#anchors)):

```markdown
---
topic: user/issues
after: Listing-of-the-issue
---
## Checklist

The issue's page shows the project's checklist after the description …
```

- **Where it goes:** at the end of the section of the `after` heading, before the next heading of the same or a higher level (after the heading's subsections). The section starts with a heading of the same level as that heading.
- **What it becomes:** part of the topic. Its headings are in the topic's table of contents and anchors, the search finds its text, and a screen's `map.yml` entry can open the topic at it (`checklist_items#index: user/issues#Checklist`). Its links and images are relative to the topic's directory (`../checklist/checklist.md`), as if it were written in the topic; its Markdown is rendered with the topic's, by the same formatter and sanitizer.
- **The label:** its heading carries the plugin's name (`Redmine::Plugin#name`), on the help pages and in the panel of both UIs.
- **Several plugins at one heading:** their sections come in the order of Administration › Plugins (by the plugin's id), then by file name.
- **Languages:** a translation is the file of the same name in the language's directory (`ja/_insertions/<name>.md`), without front matter (its place is the English file's); it keeps the English file's headings one for one. In a topic shown in a language the plugin has no translation for, the English section is shown, and its label says so ("Redmine Kit Checklist (English)").
- **A missing topic or heading:** the section is left out, with a warning in Redmine's log that names the file, as for a `map.yml` that is not valid YAML. The rest of the plugin's help still works. Run the check below before releasing the plugin.
- **The operator's replacement:** a topic that the operator's directory replaces gets no section from plugins. The operator's text is shown as written, and can describe the plugins' parts itself.

### Checking a plugin's help

The rake task checks the plugins' `help/` against the installed guide: every `map.yml` and `index.yml` topic and anchor exists, each translation has its English topic or section and the same number of headings, and each section has its topic and heading, starts with a heading of that heading's level, and repeats no heading of the topic. Each problem names its file. The task exits with status 1 when it finds a problem.

Run it from Redmine's folder, for every plugin or for one:

```sh
bin/rails redmine_kit:help:check RAILS_ENV=production
bin/rails redmine_kit:help:check PLUGIN=redmine_kit_checklist RAILS_ENV=production
```

A plugin's test can assert the same, where Redmine Kit Help and the guide are installed:

```ruby
assert_empty RedmineKit::Help::Check.new.problems(:redmine_kit_checklist)
```

## The operator's directory

`REDMINE_KIT_HELP_EXTRA_PATH` points at a directory with the same layout, kept outside Redmine (for example in a derived image or a mounted volume). It can:

- **add pages:** topics and sections of its own, such as whom to contact in the company or the support of a hosted service. Its sections come first in the sidebar.
- **add a block to pages:** `<language>/_support.md` is shown below every page, `<language>/_support/<topic>.md` below one topic (for example the help desk's number, or a note on how the company uses issues). Without a block in the user's language, the English block is shown.
- **replace topics:** a topic with the same path as one of the guide or of a plugin replaces it.
- **map screens:** its `map.yml` comes before the plugins' and the guide's.

## Precedence

| What | Order (first wins) |
| --- | --- |
| A topic | the operator's directory, the plugins, the guide |
| A screen in the maps | the operator's directory, the plugins, the guide |
| Sections of the sidebar | the operator's directory, the guide, the plugins (a topic is listed once) |
| Blocks | the every-page block, then the topic's block |
| Plugins' sections in one place of a topic | Administration › Plugins' order (by the plugin's id), then the file name; none in a topic the operator replaced |
