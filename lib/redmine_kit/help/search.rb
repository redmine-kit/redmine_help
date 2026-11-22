# frozen_string_literal: true

module RedmineKit
  module Help
    # A simple search in the titles and texts of topics (Library#search):
    # the topics with every word (at most 5), each with a snippet around the
    # first word.
    module Search
      module_function

      def call(topics, query)
        words = query.to_s.downcase.split.uniq.first(5)
        return [] if words.empty?

        topics.filter_map do |topic|
          haystack = "#{topic.title}\n#{topic.readable_body}".downcase
          next unless words.all? { |word| haystack.include?(word) }

          [topic, snippet(topic.readable_body, words.first)]
        end
      end

      def snippet(text, word)
        plain = text.gsub(/[#*_`>\[\]()|]/, ' ').squeeze(' ')
        index = plain.downcase.index(word) || 0
        start = [index - 60, 0].max
        plain[start, 200].to_s.strip
      end
    end
  end
end
