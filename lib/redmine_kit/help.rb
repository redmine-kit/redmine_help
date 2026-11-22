# frozen_string_literal: true

# Help for the current screen, in the user's language, from Markdown files
# (docs/README.md). The header's Help link opens the topic mapped to the
# screen; the topics come from the Redmine guide, from other plugins' help/
# directories, and from an operator's directory (REDMINE_KIT_HELP_EXTRA_PATH).
#
# RedmineKit, the organization's namespace, belongs to no plugin: no plugin has
# lib/redmine_kit.rb, and Rails' code loader (Zeitwerk) makes it from the
# plugins' lib/redmine_kit/ folders. This plugin owns RedmineKit::Help only.
module RedmineKit
  module Help
    VERSION = '0.2.1'

    # The language of the topics when the user's language has none.
    FALLBACK_LANGUAGE = 'en'

    # Request parameters that can select a more precise topic in the map
    # (e.g. "settings#index?tab=authentication", a plugin's settings
    # "settings#plugin?id=redmine_kit_checklist").
    MAP_PARAMS = %w[tab type id].freeze

    module_function

    # Called from init.rb, again on each reload: the header's Help link and
    # the side panel's hook. The other files are loaded by Rails' code loader
    # (Zeitwerk) when they are first used.
    def setup
      Menu.install
      Hooks.instance
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
end
