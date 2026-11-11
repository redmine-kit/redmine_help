# Adding help

## Directory layout

The guide, a plugin's help and the operator's directory have the same layout:

```text
index.yml          # sections of the sidebar
map.yml            # screens to topics (mapping.md)
en/                # one directory per language
  <topic>.md       # a topic; a # heading on the first line is its title
  _support.md      # (operator only) a block shown on every page
  _support/<topic>.md  # (operator only) a block shown on one topic
ja/
  <topic>.md
images/            # images the topics show, by relative links
```

`index.yml` lists sections and their topics. A topic is its id, or an id with a label for the sidebar, used while the topic is not translated into the user's language (a translated topic shows its own heading):

```yaml
sections:
  - id: support
    title: { en: Support, ja: サポート }
    topics:
      - support/contact
      - { id: support/hours, title: { en: Opening hours, ja: 受付時間 } }
```

A topic missing in the user's language is shown in English, with a note.

## Plugins

A Redmine plugin adds help by shipping a `help/` directory at its root with the layout above. Redmine Help finds it in every installed plugin; nothing needs to be registered. The plugin's sections come after the guide's in the sidebar, and its `map.yml` maps the plugin's screens (its controllers) to its topics. Name the topics under the plugin's own directory (for example `aws-ses/sending`) so that they do not clash with the guide's.

## The operator's directory

`REDMINE_HELP_EXTRA_PATH` points at a directory with the same layout, kept outside Redmine (for example in a derived image or a mounted volume). It can:

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
