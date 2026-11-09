# frozen_string_literal: true

module RedmineHelp
  # A topic in one language: its Markdown file and where it comes from.
  Topic = Struct.new(:id, :language, :path, :source, keyword_init: true) do
    def text
      @text ||= File.read(path, encoding: 'UTF-8')
    end

    # The page's # heading, or the topic's name.
    def title
      body[/^#[ \t]+(.+)$/, 1]&.strip || id.split('/').last.tr('-', ' ').capitalize
    end

    # The Markdown without front matter.
    def body
      text.sub(/\A---\n.*?\n---\n/m, '')
    end
  end

  # A section of the sidebar: its title (one string, or one per language) and
  # its topics in one language.
  Section = Struct.new(:id, :titles, :topics, keyword_init: true) do
    def title(language)
      return titles.to_s unless titles.is_a?(Hash)

      titles[language] || titles[FALLBACK_LANGUAGE] || titles.values.first || id
    end
  end
end
