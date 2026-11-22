# frozen_string_literal: true

module RedmineKit
  module Help
    # A plugin's help/ as its author checks it (rake redmine_kit:help:check,
    # docs/extending.md "Checking a plugin's help"): the problems that would
    # leave a part of it out or open a screen at the wrong place, each naming
    # its file. Against the installed guide, so that a section's topic and
    # heading are the ones Redmine Kit Help shows.
    class Check
      def initialize(library = RedmineKit::Help.library)
        @library = library
      end

      # The installed help with a plugin's help/ from a directory (a checkout
      # not installed here) in place of the plugin's own, if any.
      def self.library_with(plugin, dir)
        sources = RedmineKit::Help::Source.all.reject { |source| source.kind == :plugin && source.id == plugin }
        name = Redmine::Plugin.installed?(plugin) ? Redmine::Plugin.find(plugin).name : plugin
        extra, rest = sources.partition { |source| source.kind == :extra }
        Library.new([*extra, Source.new(plugin, dir, :plugin, name: name), *rest])
      end

      # The problems of every plugin's help, or of one plugin's (its id).
      def problems(plugin = nil)
        sources = @library.sources.select { |source| source.kind == :plugin }
        sources = sources.select { |source| source.id == plugin.to_s } if plugin
        sources.flat_map { |source| source_problems(source) }
      end

      # The plugins with a help/ directory, by id.
      def plugins
        @library.sources.select { |source| source.kind == :plugin }.map(&:id)
      end

      private

      def source_problems(source)
        yaml_problems(source) + map_problems(source) + index_problems(source) +
          topic_problems(source) + insertion_problems(source)
      end

      def yaml_problems(source)
        %w[map.yml index.yml].filter_map do |name|
          file = source.root.join(name)
          next unless file.file?

          data = YAML.safe_load_file(file)
          "#{file}: not a mapping" unless data.is_a?(Hash)
        rescue Psych::Exception, SystemStackError
          "#{file}: not valid YAML"
        end
      end

      # Each screen's topic exists, and its anchor is a heading of the English
      # topic (with the plugins' sections).
      def map_problems(source)
        source.map.filter_map do |key, value|
          id, anchor = value.to_s.split('#', 2)
          topic = @library.topic(id, FALLBACK_LANGUAGE)
          if topic.nil?
            "#{source.root.join('map.yml')}: #{key}: no topic #{id}"
          elsif anchor.present? && topic.anchors.exclude?(anchor)
            "#{source.root.join('map.yml')}: #{key}: no heading #{anchor} in #{id}"
          end
        end
      end

      def index_problems(source)
        source.index.flat_map do |section|
          Array(section['topics']).filter_map do |entry|
            id = entry.is_a?(Hash) ? entry['id'].to_s : entry.to_s
            "#{source.root.join('index.yml')}: no topic #{id}" unless @library.topic(id, FALLBACK_LANGUAGE)
          end
        end
      end

      # A translation has an English topic and the same number of headings
      # (an English anchor finds its heading by position).
      def topic_problems(source)
        (source.languages - [FALLBACK_LANGUAGE]).flat_map do |language|
          source.topics(language).filter_map do |id, topic|
            english = source.topics(FALLBACK_LANGUAGE)[id]
            if english.nil?
              "#{topic.path}: no English topic #{id}"
            elsif english.anchors.size != topic.anchors.size
              "#{topic.path}: #{topic.anchors.size} headings, the English topic #{english.anchors.size}"
            end
          end
        end
      end

      def insertion_problems(source)
        english = source.insertions(FALLBACK_LANGUAGE)
        problems = english.values.flat_map { |insertion| placement_problems(insertion) }
        problems + (source.languages - [FALLBACK_LANGUAGE]).flat_map do |language|
          source.insertions(language).filter_map do |name, insertion|
            translation_problem(insertion, english[name])
          end
        end
      end

      def placement_problems(insertion)
        return ["#{insertion.path}: names no topic and heading (topic:, after:)"] unless insertion.placed?

        topic = @library.base_topic(insertion.topic, FALLBACK_LANGUAGE)
        return ["#{insertion.path}: no topic #{insertion.topic}"] unless topic

        heading = Headings.of(topic.body).find { |h| h.anchor == insertion.after }
        return ["#{insertion.path}: no heading #{insertion.after} in #{insertion.topic}"] unless heading

        heading_problems(insertion, topic, heading)
      end

      # It starts with a heading of the level of the one it follows (a section
      # after it) or one level below (a subsection at the end of its section),
      # whose anchor no heading of the topic has (else one of them would get
      # -2). Another level would end the heading's parent section early (an h2
      # after an h3) or skip a level.
      def heading_problems(insertion, topic, heading)
        first = Headings.of(insertion.body).first
        return ["#{insertion.path}: starts with no heading"] unless first&.line&.zero?

        problems = []
        unless [heading.level, heading.level + 1].include?(first.level)
          problems << "#{insertion.path}: its heading is level #{first.level}; after #{insertion.after} " \
                      "(level #{heading.level}) it is level #{heading.level} or #{heading.level + 1}"
        end
        if topic.anchors.include?(first.anchor)
          problems << "#{insertion.path}: #{insertion.topic} has a heading #{first.anchor} already"
        end
        problems
      end

      def translation_problem(insertion, english)
        return "#{insertion.path}: no English section #{insertion.name}" unless english

        count = Headings.of(insertion.body).size
        expected = Headings.of(english.body).size
        "#{insertion.path}: #{count} headings, the English section #{expected}" unless count == expected
      end
    end
  end
end
