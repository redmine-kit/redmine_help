# frozen_string_literal: true

module RedmineKit
  module Help
    # A topic in one language: its Markdown file and where it comes from. The
    # file is read when the source lists the language's topics (Source#topics),
    # and the topic is kept, read-only, as long as the library.
    class Topic
      attr_reader :id, :language, :path, :source, :text, :anchors

      def initialize(id:, language:, path:, source:)
        @id = id
        @language = language
        @path = path
        @source = source
        @text = File.read(path, encoding: 'UTF-8').freeze
        @anchors = heading_anchors.freeze
        freeze
      end

      # The page's # heading, or the topic's name.
      def title
        body[/^#[ \t]+(.+)$/, 1]&.strip || id.split('/').last.tr('-', ' ').capitalize
      end

      # The Markdown without front matter.
      def body
        text.sub(/\A---\n.*?\n---\n/m, '')
      end

      # The Markdown as read: without the targets of links and images. The
      # search and its snippets read this.
      def readable_body
        body.gsub(/\]\([^)]*\)/, ']')
      end

      private

      # The headings' anchors in order, as Redmine makes them
      # (ApplicationHelper#parse_headings and #sanitize_anchor_name).
      def heading_anchors
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
end
