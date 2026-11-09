# frozen_string_literal: true

# Help for the current screen, in the user's language, from Markdown files
# (docs/README.md). The header's Help link opens the topic mapped to the
# screen; the topics come from the Redmine guide, from other plugins' help/
# directories, and from an operator's directory (REDMINE_HELP_EXTRA_PATH).
module RedmineHelp
  VERSION = '0.1.0'

  # The language of the topics when the user's language has none.
  FALLBACK_LANGUAGE = 'en'

  # Request parameters that can select a more precise topic in the map
  # (e.g. "settings#index?tab=authentication").
  MAP_PARAMS = %w[tab type].freeze

  module_function

  def setup
    require_relative 'redmine_help/source'
    require_relative 'redmine_help/topic'
    require_relative 'redmine_help/library'
    require_relative 'redmine_help/menu'
    Menu.install
  end

  # The help, read again when the files change (in development) or once.
  def library
    @library = nil if @library&.stale?
    @library ||= Library.new(Source.all)
  end

  def reset!
    @library = nil
  end

  # A title in the language: a string, or a hash of languages.
  def localized(titles, language)
    return titles.presence&.to_s unless titles.is_a?(Hash)

    titles[language] || titles[FALLBACK_LANGUAGE] || titles.values.first
  end
end
