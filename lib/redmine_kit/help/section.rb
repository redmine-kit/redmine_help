# frozen_string_literal: true

module RedmineKit
  module Help
    # A section of the sidebar: its title (one string, or one per language),
    # its topics in one language, and the topics' labels from index.yml.
    Section = Struct.new(:id, :titles, :topics, :labels, keyword_init: true) do
      def title(language)
        RedmineKit::Help.localized(titles, language) || id
      end

      # A translated topic shows its own heading; a topic shown in the fallback
      # language shows the label index.yml gives it, if any.
      def topic_title(topic, language)
        return topic.title if topic.language == language && language != FALLBACK_LANGUAGE

        RedmineKit::Help.localized(labels.to_h[topic.id], language) || topic.title
      end
    end
  end
end
