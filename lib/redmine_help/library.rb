# frozen_string_literal: true

module RedmineHelp
  # All help in one place: the topics of every source, in order of
  # precedence (an earlier source's topic replaces a later one's), the
  # sidebar's sections and the map from screens to topics.
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

    # The topic in the language, or in the fallback language.
    def topic(id, language)
      find(id, language) || (language == FALLBACK_LANGUAGE ? nil : find(id, FALLBACK_LANGUAGE))
    end

    def topics(language)
      ids = sources.flat_map { |source| source.topics(language).keys + source.topics(FALLBACK_LANGUAGE).keys }.uniq
      ids.filter_map { |id| topic(id, language) }
    end

    # Blocks for the page: the operator's every-page block, then the topic's.
    def support(topic_id, language)
      sources.select { |source| source.kind == :extra }.flat_map do |source|
        files = source.support(language, topic_id)
        files = source.support(FALLBACK_LANGUAGE, topic_id) if files.empty? && language != FALLBACK_LANGUAGE
        files.map { |file| File.read(file, encoding: 'UTF-8') }
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
      keys = MAP_PARAMS.filter_map { |name| "#{controller}##{action}?#{name}=#{params[name]}" if params[name].present? }
      keys += ["#{controller}##{action}", controller.to_s]
      keys.each do |key|
        sources.each do |source|
          value = source.map[key]
          return value.to_s.split('#', 2) if value.present?
        end
      end
      nil
    end

    # A simple search in the titles and texts of the language's topics.
    def search(query, language)
      words = query.to_s.downcase.split.uniq.first(5)
      return [] if words.empty?

      topics(language).filter_map do |topic|
        # The text as read: without the targets of links and images.
        haystack = "#{topic.title}\n#{topic.body.gsub(/\]\([^)]*\)/, ']')}".downcase
        next unless words.all? { |word| haystack.include?(word) }

        [topic, snippet(topic.body, words.first)]
      end
    end

    def asset(path)
      sources.each do |source|
        file = source.asset(path)
        return file if file
      end
      nil
    end

    private

    def section(entry, language, listed)
      topics = (Array(entry['topics']).map(&:to_s) - listed).filter_map { |id| topic(id, language) }
      listed.concat(topics.map(&:id))
      return if topics.empty?

      Section.new(id: entry['id'].to_s, titles: entry['title'], topics: topics)
    end

    def find(id, language)
      sources.each do |source|
        path = source.topics(language)[id]
        return Topic.new(id: id, language: language, path: path, source: source) if path
      end
      nil
    end

    def snippet(text, word)
      plain = text.gsub(/[#*_`>\[\]()|]/, ' ').squeeze(' ')
      index = plain.downcase.index(word) || 0
      start = [index - 60, 0].max
      plain[start, 200].to_s.strip
    end
  end
end
