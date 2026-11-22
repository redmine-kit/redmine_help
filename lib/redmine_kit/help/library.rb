# frozen_string_literal: true

module RedmineKit
  module Help
    # All help in one place: the topics of every source, in order of
    # precedence (an earlier source's topic replaces a later one's), the
    # sidebar's sections and the map from screens to topics. The sources keep
    # what they read (Source), so a request reads no file but an image. A
    # topic comes with the plugins' sections inserted (Insertions), merged
    # once per topic and language and kept, read-only, as long as the library.
    class Library
      attr_reader :sources

      def initialize(sources)
        @sources = sources
        @loaded_at = Time.now
      end

      # Read again in development when a file changed.
      def stale?
        Rails.env.development? && sources.any? { |source| source.mtime > @loaded_at }
      end

      def available?
        sources.any?
      end

      # Whether the guide is installed: without it the contents say so (docs/setup.md).
      def guide? = sources.any? { |source| source.kind == :guide }

      def languages
        sources.flat_map(&:languages).uniq.sort
      end

      # The language to show: the requested one if there is help in it, or the
      # fallback.
      def language_for(requested)
        requested = requested.to_s
        return requested if languages.include?(requested)

        short = requested.split('-').first
        languages.include?(short) ? short : FALLBACK_LANGUAGE
      end

      # The topic in the language, or in the fallback language, with the
      # plugins' sections (Insertions).
      def topic(id, language)
        base = base_topic(id, language)
        base && insertions.topic(base)
      end

      # The topic as its file has it, without the plugins' sections.
      def base_topic(id, language)
        find(id, language) || (language == FALLBACK_LANGUAGE ? nil : find(id, FALLBACK_LANGUAGE))
      end

      def insertions
        @insertions ||= Insertions.new(self)
      end

      # A translation keeps the English page's headings one for one, so an
      # English anchor (map.yml, links between topics) points to the
      # translation's heading at the same position.
      def anchor(id, language, anchor)
        return anchor if anchor.blank? || language == FALLBACK_LANGUAGE

        english = topic(id, FALLBACK_LANGUAGE)
        translated = topic(id, language)
        return anchor unless parallel?(english, translated, language)

        index = english.anchors.index(anchor)
        index ? translated.anchors[index] : anchor
      end

      def topics(language)
        ids = sources.flat_map { |source| source.topics(language).keys + source.topics(FALLBACK_LANGUAGE).keys }.uniq
        ids.filter_map { |id| topic(id, language) }
      end

      # Blocks for the page, as Markdown: the operator's every-page block, then
      # the topic's.
      def support(topic_id, language)
        sources.select { |source| source.kind == :extra }.flat_map do |source|
          blocks = source.support(language, topic_id)
          blocks = source.support(FALLBACK_LANGUAGE, topic_id) if blocks.empty? && language != FALLBACK_LANGUAGE
          blocks
        end
      end

      # The sidebar: the operator's sections first (support), then the guide's,
      # then the plugins'. A topic listed by an earlier section is not repeated.
      def sections(language)
        listed = []
        %i[extra guide plugin].flat_map { |kind| sources.select { |s| s.kind == kind } }.flat_map do |source|
          source.index.filter_map { |entry| section(entry, language, listed) }
        end
      end

      # The topic (and anchor) for a screen: "controller#action?param=value",
      # then "controller#action", then "controller". An earlier source's entry
      # wins. Returns [topic, anchor] or nil.
      def resolve(controller, action, params = {})
        lookup(controller, action, params)&.last
      end

      # The key of the map that matched the screen, and its [topic, anchor];
      # nil when no key matched. A key with a parameter
      # ("settings#index?tab=authentication") means the parameter has a topic
      # of its own: the side panel follows a tab only then.
      def lookup(controller, action, params = {})
        keys = MAP_PARAMS.filter_map { |key| "#{controller}##{action}?#{key}=#{params[key]}" if params[key].present? }
        keys += ["#{controller}##{action}", controller.to_s]
        keys.each do |key|
          sources.each do |source|
            value = source.map[key]
            return [key, value.to_s.split('#', 2)] if value.present?
          end
        end
        nil
      end

      # A simple search in the titles and texts of the language's topics.
      def search(query, language)
        Search.call(topics(language), query)
      end

      def asset(path)
        sources.each do |source|
          file = source.asset(path)
          return file if file
        end
        nil
      end

      private

      # A translation in the language whose headings are the English topic's,
      # one for one.
      def parallel?(english, translated, language)
        english && translated&.language == language && english.anchors.size == translated.anchors.size
      end

      # A topic in index.yml is its id, or { id:, title: } with a label.
      def section(entry, language, listed)
        labels = Array(entry['topics']).to_h { |t| t.is_a?(Hash) ? [t['id'].to_s, t['title']] : [t.to_s, nil] }
        topics = (labels.keys - listed).filter_map { |id| topic(id, language) }
        listed.concat(topics.map(&:id))
        return if topics.empty?

        Section.new(id: entry['id'].to_s, titles: entry['title'], topics: topics, labels: labels.compact)
      end

      def find(id, language)
        sources.each do |source|
          topic = source.topics(language)[id]
          return topic if topic
        end
        nil
      end
    end
  end
end
