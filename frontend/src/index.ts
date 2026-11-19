// Redmine Kit Help's module for the new UI: its components, exported by name (redmine_kit_ui's docs/plugins-kit.md,
// "The module"), as config/kit_ui.yml declares them: the panel that is the TopBar's ヘルプ (topbar.panel, replaces: help),
// the help pages (/help, /help/search, /help/*topic) and Redmine's help pages (/help/wiki_syntax[/detailed],
// /help/code_highlighting).
export { HelpPanel } from './HelpPanel';
export { HelpPage, HelpWikiSyntax, HelpCodeHighlighting } from './HelpPage';
