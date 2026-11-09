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

    # The headings' anchors in order, as Redmine makes them
    # (ApplicationHelper#parse_headings and #sanitize_anchor_name).
    def anchors
      @anchors ||= begin
        seen = Hash.new(0)
        body.gsub(/^```.*?^```/m, '').scan(/^#+[ \t]+(.+)$/).flatten.map do |heading|
          plain = heading.strip.gsub(/!?\[([^\]]*)\]\([^)]*\)/, '\\1').delete('`*')
          anchor = plain.gsub(/[^\s\-\p{Word}]/, '').gsub(/\s+(-+\s*)?/, '-')
          seen[anchor] += 1
          seen[anchor] > 1 ? "#{anchor}-#{seen[anchor]}" : anchor
        end
      end
    end
  end

  # A section of the sidebar: its title (one string, or one per language),
  # its topics in one language, and the topics' labels from index.yml.
  Section = Struct.new(:id, :titles, :topics, :labels, keyword_init: true) do
    def title(language)
      RedmineHelp.localized(titles, language) || id
    end

    # A translated topic shows its own heading; a topic shown in the fallback
    # language shows the label index.yml gives it, if any.
    def topic_title(topic, language)
      return topic.title if topic.language == language && language != FALLBACK_LANGUAGE

      RedmineHelp.localized(labels.to_h[topic.id], language) || topic.title
    end
  end
end
