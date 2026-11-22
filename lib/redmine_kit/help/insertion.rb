# frozen_string_literal: true

module RedmineKit
  module Help
    # A plugin's section for a topic of the guide: <language>/_insertions/<name>.md
    # in the plugin's help/ (docs/extending.md "Sections in the guide's
    # topics"). The English file's front matter says where it goes: `topic`
    # (the guide's topic) and `after` (the English anchor of the heading whose
    # section it follows). A translation has the same name; its front matter,
    # if any, is not read.
    class Insertion
      TOPIC = %r{\A[a-z0-9][a-z0-9_-]*(/[a-z0-9][a-z0-9_-]*)*\z}
      ANCHOR = /\A[\p{Word}-]{1,200}\z/

      attr_reader :name, :language, :path, :source, :body, :topic, :after

      # The source's insertions of the language, by name.
      def self.all(source, language)
        dir = source.root.join(language, '_insertions')
        Dir.glob('**/*.md', base: dir).sort.to_h do |file|
          name = file.delete_suffix('.md')
          [name, new(name: name, language: language, path: dir.join(file), source: source)]
        end
      end

      def initialize(name:, language:, path:, source:)
        @name = name
        @language = language
        @path = path
        @source = source
        text = File.read(path, encoding: 'UTF-8')
        @body = Headings.without_front_matter(text).strip.freeze
        @topic, @after = place(text)
        freeze
      end

      # Whether the front matter names a topic and a heading (English files).
      def placed?
        topic.present? && after.present?
      end

      # The plugin's name for the label: Redmine::Plugin#name (a string, or a
      # locale key).
      def plugin_name
        name = source.name
        name.is_a?(Symbol) ? ::I18n.t(name, default: source.id) : name.to_s.presence || source.id
      end

      # This section in the language: the plugin's translation, or this one.
      def in(language)
        return self if language == FALLBACK_LANGUAGE

        source.insertions(language)[name] || self
      end

      # The label after the section's heading in a topic of the language: the
      # plugin's name, with the section's language when it isn't the topic's
      # ("Redmine Kit Checklist (English)").
      def label(topic_language)
        return plugin_name if language == topic_language

        "#{plugin_name} (#{::I18n.t(:general_lang_name, locale: language, default: language)})"
      end

      # The level of the insertion's first heading (nil: it starts with none).
      def level
        first = Headings.of(body).first
        first&.line&.zero? ? first.level : nil
      end

      private

      # The front matter's topic and after, each only in its expected shape.
      def place(text)
        data = front_matter(text)
        [shaped(data['topic'], TOPIC), shaped(data['after'], ANCHOR)]
      end

      # The front matter as a mapping: {} when there is none, or it isn't
      # valid YAML (aliases, tags, classes) or a mapping.
      def front_matter(text)
        yaml = text[Headings::FRONT_MATTER]
        data = yaml && YAML.safe_load(yaml.delete_prefix("---\n").delete_suffix("---\n"), freeze: true)
        data.is_a?(Hash) ? data : {}
      rescue Psych::Exception, SystemStackError
        {}
      end

      def shaped(value, pattern)
        value if value.is_a?(String) && value.match?(pattern)
      end
    end
  end
end
