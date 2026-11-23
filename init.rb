# frozen_string_literal: true

# The plugins this one requires (config/dependencies.yml): without one,
# Redmine stops here and names it.
load File.expand_path('config/dependencies.rb', __dir__)

# Redmine Kit Help: the header's Help link opens help for the current screen
# (README.md). It is installed as a gem (boot/redmine_kit_help.rb) or in
# plugins/ (docs/setup.md, "Installation"); RedmineKit::Help comes from lib/
# through Rails' code loader (Zeitwerk) either way.
Redmine::Plugin.register :redmine_kit_help do
  name 'Redmine Kit Help'
  author 'Redmine Kit'
  description 'Help for the current screen'
  version RedmineKit::Help::VERSION
  url 'https://github.com/redmine-kit/redmine_help'
  author_url 'https://github.com/redmine-kit'
  requires_redmine version_or_higher: '7.0.0'
  # This folder, as Redmine's plugin loader found it: plugins/redmine_kit_help
  # (a checkout or a link, kept unresolved: Redmine finds the plugin's assets by
  # this path), or the installed gem's folder (boot/redmine_kit_help.rb).
  # Redmine's default is plugins/<id>, which a gem doesn't have.
  directory File.dirname(__FILE__)
end

RedmineKit::Help.setup
