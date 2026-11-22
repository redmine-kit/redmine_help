# frozen_string_literal: true

module RedmineKit
  module Help
    # The plugins' sections in the guide's topics (Insertion,
    # docs/extending.md "Sections in the guide's topics"): which sections go
    # into a topic, and the topic with them merged into its Markdown, so that
    # the pages, the panel, the JSON, the table of contents, the anchors of the
    # map and the search all read one text.
    #
    # - A section goes at the end of the section of its heading (`after`):
    #   before the next heading of the same or a higher level, or at the end.
    # - Several sections at one place: in the order of Redmine's plugin list
    #   (Administration › Plugins: Redmine::Plugin.all, by id), then by file
    #   name.
    # - In the topic's language when the plugin has the translation, else in
    #   English. The heading is found in a translation at the English heading's
    #   position (Library#anchor's rule).
    # - A topic of the operator's directory (a replacement) gets none: the
    #   operator's text is shown as written.
    # - A section whose topic or heading is missing is left out, with a warning
    #   in Redmine's log that names its file.
    class Insertions
      def initialize(library)
        @library = library
        @merged = Concurrent::Map.new
        @warned = Concurrent::Map.new
      end

      # The topic with its sections, merged once per topic and language and
      # kept, read-only, as long as the library.
      def topic(base)
        @merged.compute_if_absent([base.id, base.language]) { apply(base) }
      end

      # The English sections placed in a topic, in their order.
      def for(topic_id)
        index.fetch(topic_id, [])
      end

      # The topic with its sections, or the topic as it is.
      def apply(topic)
        return topic if topic.source.kind == :extra

        list = self.for(topic.id)
        return topic if list.empty?

        places = list.filter_map { |insertion| place(topic, insertion) }
        return topic if places.empty?

        merge(topic, places)
      end

      # The insertions by topic: placed, with an existing topic (each problem
      # logged once).
      def index
        @index ||= begin
          all = english.select { |insertion| placeable?(insertion) }
          all.group_by(&:topic).transform_values(&:freeze).freeze
        end
      end

      # Every English insertion of the plugins, in their order.
      def english
        @library.sources.select { |source| source.kind == :plugin }.flat_map do |source|
          source.insertions(FALLBACK_LANGUAGE).values
        end
      end

      private

      # A warning in Redmine's log, once for the library (its files are read
      # once).
      def warn_once(message)
        @warned.put_if_absent(message, true) || Rails.logger.warn(message)
      end

      def placeable?(insertion)
        unless insertion.placed?
          warn_once("redmine_kit_help: #{insertion.path} names no topic and heading (topic:, after:); ignored")
          return false
        end
        return true if @library.base_topic(insertion.topic, FALLBACK_LANGUAGE)

        warn_once("redmine_kit_help: #{insertion.path}: no topic #{insertion.topic}; ignored")
        false
      end

      # [line, insertion in the topic's language] for one insertion, or nil
      # (logged) when the topic has no such heading.
      def place(topic, insertion)
        headings = Headings.of(topic.body)
        anchor = heading_in(topic, insertion.after)
        at = anchor && headings.index { |heading| heading.anchor == anchor }
        unless at
          warn_once("redmine_kit_help: #{insertion.path}: no heading #{insertion.after} " \
                    "in #{topic.id} (#{topic.language}); ignored")
          return
        end

        level = headings[at].level
        stop = headings[(at + 1)..].find { |heading| heading.level <= level }&.line
        [stop || topic.body.lines.size, insertion.in(topic.language)]
      end

      # The English anchor in the topic's language: the heading at the same
      # position, or none when the translation's headings differ.
      def heading_in(topic, anchor)
        return anchor if topic.language == FALLBACK_LANGUAGE

        english = @library.base_topic(topic.id, FALLBACK_LANGUAGE)
        return unless english && english.anchors.size == topic.anchors.size

        index = english.anchors.index(anchor)
        index && topic.anchors[index]
      end

      # The topic's lines with the sections before the line of their place
      # (or at the end), each after a blank line; `starts`: the line where
      # each section begins.
      def merge(topic, places)
        out = []
        starts = []
        lines = lines_of(topic.body)
        by_line = places.group_by(&:first).transform_values { |list| list.map(&:last) }
        (0..lines.size).each do |number|
          by_line.fetch(number, []).each { |insertion| starts << [append(out, insertion), insertion] }
          out << lines[number] if number < lines.size
        end
        topic_with(topic, out.join, starts)
      end

      # Adds the section to the lines; returns the line where it begins.
      def append(out, insertion)
        out << "\n" unless out.empty? || out.last.strip.empty?
        start = out.size
        out.concat(lines_of(insertion.body), ["\n"])
        start
      end

      def lines_of(text)
        text.lines.map { |line| line.end_with?("\n") ? line : "#{line}\n" }
      end

      def topic_with(topic, text, starts)
        Topic.new(id: topic.id, language: topic.language, path: topic.path, source: topic.source,
                  merged: { text: text, insertions: described(topic, text, starts) })
      end

      # The inserted sections: their heading's anchor in the merged text, the
      # plugin, its name, the section's language, and the label both UIs show
      # after the heading: the plugin's name, with the section's language when
      # it isn't the topic's ("Redmine Kit Checklist (English)").
      def described(topic, text, starts)
        headings = Headings.of(text)
        starts.map do |line, insertion|
          { anchor: headings.find { |heading| heading.line == line }&.anchor, plugin: insertion.source.id,
            name: insertion.plugin_name, language: insertion.language,
            label: insertion.label(topic.language) }.freeze
        end
      end
    end
  end
end
