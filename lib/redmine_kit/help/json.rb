# frozen_string_literal: true

module RedmineKit
  module Help
    # The help as JSON, for the new UI's help panel and pages (Redmine Kit
    # UI's Kit module of this plugin, frontend/): the same library, the same
    # language rules and the same map as Redmine's own pages. Topics are
    # Markdown (the new UI renders them), with their links rewritten
    # (MarkdownLinks).
    module Json
      module_function

      # GET /help.json: the sections of the sidebar, each with its topics, and
      # whether the guide is installed (without it the contents say so).
      def contents(library, language)
        sections = library.sections(language).map do |section|
          { id: section.id, title: section.title(language),
            topics: section.topics.map { |topic| { id: topic.id, title: section.topic_title(topic, language) } } }
        end
        { help: { language: language, guide: library.guide?, sections: sections } }
      end

      # GET /help/<topic>.json: the topic in the language (or the fallback),
      # the operator's blocks under it, its section, and the anchor asked for
      # (?anchor=, an English anchor) in the topic's language. The plugins'
      # sections are in the body; `insertions` says where (their heading's
      # anchor), whose (the plugin's id and name: the label) and in which
      # language each is.
      def topic(library, topic, language, anchor: nil)
        section = library.sections(language).find { |s| s.topics.any? { |t| t.id == topic.id } }
        markdown = ->(text) { MarkdownLinks.rewrite(text, topic.id, language, library) }
        { help: {
          topic: { id: topic.id, title: topic.title, language: topic.language, anchors: topic.anchors,
                   body: markdown.call(topic.body), anchor: library.anchor(topic.id, language, anchor).presence,
                   insertions: topic.insertions.select { |insertion| insertion[:anchor] } },
          support: library.support(topic.id, language).map(&markdown),
          section: section && { id: section.id, title: section.title(language) }
        } }
      end

      # GET /help/search.json?q=: the topics with every word, with a snippet.
      # The library is read once and kept (RedmineKit::Help.library), so a
      # search reads a few dozen topics in memory: no cache to keep right.
      def search(library, query, language)
        results = library.search(query, language).map do |topic, snippet|
          { id: topic.id, title: topic.title, snippet: snippet }
        end
        { help: { q: query, results: results } }
      end

      # Redmine's help pages as the guide's topics: the text formatting's
      # (help#show_wiki_syntax) is the topic of
      # the server's formatting, Textile's or else Markdown's; the code
      # highlighting's (help#show_code_highlighting) its languages.
      SYNTAX_TOPICS = {
        'wiki' => lambda {
          Setting.text_formatting == 'textile' ? 'user/text-formatting-textile' : 'user/text-formatting-markdown'
        },
        'code' => -> { 'user/code-highlighting-languages' }
      }.freeze

      # GET /help/context.json?syntax=wiki|code: the topic of one of Redmine's
      # help pages, or none (the contents) for another value or a topic the
      # library doesn't have.
      def syntax(library, language, value)
        id = SYNTAX_TOPICS[value]&.call if value.is_a?(String)
        topic = library.topic(id, language) if id
        { help: { topic: topic&.id, anchor: nil, follow: false } }
      end

      # GET /help/context.json?screen=&tab=: the topic of the new UI's screen
      # (KitScreens), at its anchor in the language, or none (the contents);
      # `follow`: the screen's tab has a topic of its own, so the panel moves
      # with a change of tab only then.
      def context(library, language, screen, tab)
        controller, action, params = KitScreens.screen(screen, tab)
        key, (id, anchor) = controller ? library.lookup(controller, action, params) : nil
        topic = id && library.topic(id, language)
        return { help: { topic: nil, anchor: nil, follow: false } } unless topic

        { help: { topic: topic.id, anchor: library.anchor(topic.id, language, anchor).presence,
                  follow: key.to_s.include?('?') } }
      end
    end
  end
end
