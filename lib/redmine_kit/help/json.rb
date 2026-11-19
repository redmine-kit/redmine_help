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

      # GET /help.json: the sections of the sidebar, each with its topics.
      def contents(library, language)
        sections = library.sections(language).map do |section|
          { id: section.id, title: section.title(language),
            topics: section.topics.map { |topic| { id: topic.id, title: section.topic_title(topic, language) } } }
        end
        { help: { language: language, sections: sections } }
      end

      # GET /help/<topic>.json: the topic in the language (or the fallback),
      # the operator's blocks under it, its section, and the anchor asked for
      # (?anchor=, an English anchor) in the topic's language.
      def topic(library, topic, language, anchor: nil)
        section = library.sections(language).find { |s| s.topics.any? { |t| t.id == topic.id } }
        markdown = ->(text) { MarkdownLinks.rewrite(text, topic.id, language, library) }
        { help: {
          topic: { id: topic.id, title: topic.title, language: topic.language, anchors: topic.anchors,
                   body: markdown.call(topic.body), anchor: library.anchor(topic.id, language, anchor).presence },
          support: library.support(topic.id, language).map(&markdown),
          section: section && { id: section.id, title: section.title(language) }
        } }
      end

      # GET /help/search.json?q=: the topics with every word, with a snippet.
      def search(library, query, language)
        results = library.search(query, language).map do |topic, snippet|
          { id: topic.id, title: topic.title, snippet: snippet }
        end
        { help: { q: query, results: results } }
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
