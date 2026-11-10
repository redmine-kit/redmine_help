# Mapping screens to topics

The Help link in the header goes to `/help/context` with the screen it was clicked on: the controller, the action, and the parameters `tab` and `type` when the screen has them. The plugin looks the screen up in the maps and opens the topic. The side panel asks the same URL with `panel=1`, which renders the topic for the panel instead of redirecting to it; `show` and `search` take `panel=1` too.

## The map

A map is `map.yml` next to the topics (in the guide, in a plugin's `help/`, in the operator's directory). Each key is a screen; each value is a topic, with an optional heading anchor:

```yaml
issues#index: user/issue-list
issues#show: user/issues
issues: user/issues
settings#index?tab=authentication: admin/settings#Authentication
settings#index: admin/settings
```

A topic is the path of its Markdown file without `.md`, from the language's directory: `user/issue-list` is `en/user/issue-list.md` and `ja/user/issue-list.md`.

## Lookup

For a screen, the keys are tried in this order, and the first key found in any map wins:

1. `controller#action?tab=value` and `controller#action?type=value` (when the screen has the parameter)
2. `controller#action`
3. `controller` (every action of the controller)

Within one key, the maps are tried in the order of precedence: the operator's directory, then the plugins, then the guide. A screen with no key opens the contents (`/help`).

When a tab is switched in the page (without loading the page again), the side panel looks the screen up with the new tab, and moves only when a key with the tab (`controller#action?tab=value`) matches. A tab without its own key keeps the panel where it is.

## Anchors

An anchor is the anchor Redmine gives the heading: the heading's text with spaces turned into `-` (as in Redmine's wiki). `admin/settings#Authentication` opens the page at the heading "Authentication".

Anchors are always the English page's. A translation keeps the English page's headings one for one (same count, levels and order), and the help finds the heading at the same position in the translation. The same goes for links between topics (`settings.md#Authentication`). A translation whose headings differ opens at the top.
