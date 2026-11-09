# frozen_string_literal: true

require_relative 'lib/redmine_help'

Redmine::Plugin.register :redmine_help do
  name 'Redmine Help'
  author 'Redmine Kit'
  description "Opens help for the current screen in the user's language, from Markdown files"
  version RedmineHelp::VERSION
  url 'https://github.com/redmine-kit/redmine_help'
  author_url 'https://github.com/redmine-kit'
  requires_redmine version_or_higher: '7.0.0'
end

RedmineHelp.setup
