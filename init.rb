# frozen_string_literal: true

require_relative 'lib/redmine_kit/help'

Redmine::Plugin.register :redmine_kit_help do
  name 'Redmine Kit Help'
  author 'Redmine Kit'
  description 'Help for the current screen'
  version RedmineKit::Help::VERSION
  url 'https://github.com/redmine-kit/redmine_help'
  author_url 'https://github.com/redmine-kit'
  requires_redmine version_or_higher: '7.0.0'
end

RedmineKit::Help.setup
