# frozen_string_literal: true

module RedmineKit
  module Help
    # A topic in one language: its Markdown file and where it comes from. The
    # file is read when the source lists the language's topics (Source#topics),
    # and the topic is kept, read-only, as long as the library.
    #
    # A topic with the plugins' sections inserted (Insertions) is a new Topic
    # of the same id, file and source, with `merged`: the merged text and the
    # inserted sections' places (`insertions`).
    class Topic
      attr_reader :id, :language, :path, :source, :text, :anchors, :insertions

      def initialize(id:, language:, path:, source:, merged: {})
        @id = id
        @language = language
        @path = path
        @source = source
        @text = (merged[:text] || File.read(path, encoding: 'UTF-8')).freeze
        @anchors = Headings.of(body).map(&:anchor).freeze
        @insertions = (merged[:insertions] || []).freeze
        freeze
      end

      # The page's # heading, or the topic's name.
      def title
        body[/^#[ \t]+(.+)$/, 1]&.strip || id.split('/').last.tr('-', ' ').capitalize
      end

      # The Markdown without front matter.
      def body
        Headings.without_front_matter(text)
      end

      # The Markdown as read: without the targets of links and images. The
      # search and its snippets read this.
      def readable_body
        body.gsub(/\]\([^)]*\)/, ']')
      end
    end
  end
end
