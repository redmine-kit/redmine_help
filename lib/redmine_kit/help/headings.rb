# frozen_string_literal: true

module RedmineKit
  module Help
    # The headings of a topic's Markdown, in order: their line, level, text and
    # anchor, the anchor as Redmine makes it (ApplicationHelper#parse_headings
    # and #sanitize_anchor_name: a repeated anchor gets -2, -3 …). Headings in
    # code blocks are none.
    module Headings
      Heading = Struct.new(:line, :level, :anchor, keyword_init: true)

      FENCE = /\A(?:```|~~~)/
      HEADING = /\A(#+)[ \t]+(.+)\z/
      FRONT_MATTER = /\A---\n.*?\n---\n/m

      module_function

      def of(markdown)
        seen = Hash.new(0)
        fenced = false
        markdown.to_s.lines.each_with_index.filter_map do |raw, index|
          line = raw.chomp
          fenced = !fenced if line.match?(FENCE)
          next if fenced || !(match = HEADING.match(line))

          anchor = anchor_of(match[2])
          seen[anchor] += 1
          anchor = "#{anchor}-#{seen[anchor]}" if seen[anchor] > 1
          Heading.new(line: index, level: match[1].size, anchor: anchor)
        end
      end

      def anchor_of(heading)
        plain = heading.strip.gsub(/!?\[([^\]]*)\]\([^)]*\)/, '\\1').delete('`*')
        plain.gsub(/[^\s\-\p{Word}]/, '').gsub(/\s+(-+\s*)?/, '-')
      end

      def without_front_matter(text)
        text.to_s.sub(FRONT_MATTER, '')
      end
    end
  end
end
