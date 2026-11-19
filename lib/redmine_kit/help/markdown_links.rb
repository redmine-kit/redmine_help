# frozen_string_literal: true

module RedmineKit
  module Help
    # A topic's Markdown for the new UI, which renders it itself (its Prose):
    # the same rewriting as the pages' HTML (HelpTopicsHelper#help_rewrite_links)
    # on the Markdown's own links. A relative link to a .md file becomes the
    # topic's path (/help/<topic>#<anchor>, the anchor in the topic's
    # language); a relative image the topic's file under /help/assets. Other
    # links stay as written; links in code are left alone.
    module MarkdownLinks
      LINK = /(!?)\[((?:[^\[\]\\]|\\.)*)\]\(([^()\s]+)((?:\s+"[^"]*")?)\)/
      # code blocks and code spans, kept as written
      CODE = /(^(?:```|~~~).*?^(?:```|~~~)|`[^`\n]*`)/m

      module_function

      def rewrite(markdown, topic_id, language, library)
        dir = File.dirname(topic_id)
        parts = markdown.to_s.split(CODE)
        parts.each_with_index.map do |part, i|
          i.odd? ? part : part.gsub(LINK) { link(Regexp.last_match, dir, language, library) }
        end.join
      end

      def link(match, dir, language, library)
        image, text, target, title = match.captures
        url = image.empty? ? topic_url(target, dir, language, library) : asset_url(target, dir, language)
        url ? "#{image}[#{text}](#{url}#{title})" : match[0]
      end

      def topic_url(target, dir, language, library)
        return if absolute?(target)

        path, anchor = target.split('#', 2)
        return unless path.end_with?('.md')

        topic = join(dir, path.delete_suffix('.md'))
        anchor = library.anchor(topic, language, anchor)
        anchor.present? ? "/help/#{topic}##{anchor}" : "/help/#{topic}"
      end

      def asset_url(target, dir, language)
        absolute?(target) ? nil : "/help/assets/#{join(language, dir, target)}"
      end

      def absolute?(target)
        target.match?(%r{\A([a-z]+:|//|#|/)}i)
      end

      def join(*parts)
        Pathname(File.join(*parts.reject { |part| part == '.' })).cleanpath.to_s.sub(%r{\A(\.\./)+}, '')
      end
    end
  end
end
