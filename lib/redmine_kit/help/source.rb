# frozen_string_literal: true

module RedmineKit
  module Help
    # A directory of help: <language>/<topic>.md, index.yml (the sections of
    # the sidebar) and map.yml (screens to topics). See docs/extending.md.
    #
    # Its files are read once, on first use, and kept as long as the library
    # (RedmineKit::Help.library makes new sources when it goes stale): the
    # languages, the topics and support blocks of a language, index.yml and
    # map.yml. The cache holds only what is on disk (the language directories
    # and their files), frozen, in a map that the server's threads share.
    class Source
      attr_reader :id, :root, :kind, :name

      # name: a plugin's name (Redmine::Plugin#name), the label of its
      # sections in the guide's topics.
      def initialize(id, root, kind, name: nil)
        @id = id
        @root = Pathname(root)
        @kind = kind
        @name = name
        @cache = Concurrent::Map.new
      end

      # In order of precedence: the operator's directory, the plugins, the guide.
      def self.all
        [extra, *plugins, guide].compact
      end

      # The Redmine guide: REDMINE_KIT_HELP_GUIDE_PATH (a checkout of
      # redmine-kit/redmine-guide), or the redmine-guide gem.
      def self.guide
        path = ENV['REDMINE_KIT_HELP_GUIDE_PATH'].presence
        path ||= guide_gem_root
        path && File.directory?(path) ? new('guide', path, :guide) : nil
      end

      def self.guide_gem_root
        spec = Gem.loaded_specs['redmine-guide']
        spec&.full_gem_path
      end

      # Every installed Redmine plugin with a help/ directory.
      def self.plugins
        Redmine::Plugin.all.filter_map do |plugin|
          dir = File.join(plugin.directory.to_s, 'help')
          next unless plugin.id != :redmine_kit_help && File.directory?(dir)

          new(plugin.id.to_s, dir, :plugin, name: plugin.name)
        end
      end

      # The operator's directory: support pages, additions and overrides.
      def self.extra
        path = ENV['REDMINE_KIT_HELP_EXTRA_PATH'].presence
        path && File.directory?(path) ? new('extra', path, :extra) : nil
      end

      def languages
        cached(:languages) do
          Dir.children(root).select { |name| name.match?(/\A[a-z]{2}(-[a-z0-9]+)?\z/i) && root.join(name).directory? }
        end
      end

      # Topics of a language: "user/issues" => Topic.
      def topics(language)
        return {} unless languages.include?(language)

        cached(:topics, language) do
          dir = root.join(language)
          Dir.glob('**/*.md', base: dir).each_with_object({}) do |file, topics|
            # _support.md, _support/ and _insertions/ are not topics
            next if file.split('/').any? { |part| part.start_with?('_') }

            id = file.delete_suffix('.md')
            topics[id] = Topic.new(id: id, language: language, path: dir.join(file), source: self)
          end
        end
      end

      # Blocks added to pages, as Markdown: <language>/_support.md (every page)
      # and <language>/_support/<topic>.md (one topic).
      def support(language, topic)
        return [] unless languages.include?(language)

        every, per_topic = cached(:support, language) do
          dir = root.join(language)
          blocks = Dir.glob('**/*.md', base: dir.join('_support')).to_h do |file|
            [file.delete_suffix('.md'), read_text(dir.join('_support', file))]
          end
          [dir.join('_support.md').file? ? read_text(dir.join('_support.md')) : nil, blocks.freeze]
        end
        [every, per_topic[topic]].compact
      end

      # A plugin's sections for the guide's topics (Insertion), by name:
      # <language>/_insertions/<name>.md. Only plugins insert sections.
      def insertions(language)
        return {} unless kind == :plugin && languages.include?(language)

        cached(:insertions, language) { Insertion.all(self, language) }
      end

      # The sidebar's sections: a list of mappings, anything else left out.
      def index
        cached(:index) do
          sections = read_yaml('index.yml')['sections']
          sections.is_a?(Array) ? sections.grep(Hash) : []
        end
      end

      def map
        cached(:map) { read_yaml('map.yml') }
      end

      # Images and other files next to the topics (e.g. images/...).
      def asset(path)
        file = root.join(path).cleanpath
        return nil unless file.to_s.start_with?("#{root.cleanpath}/") && file.file?
        return nil unless %w[.png .jpg .jpeg .gif .svg .webp].include?(file.extname.downcase)

        file
      end

      def mtime
        Dir.glob(root.join('**', '*').to_s).map { |file| File.mtime(file) }.max || Time.at(0)
      end

      private

      def cached(*key)
        @cache.compute_if_absent(key) { yield.freeze }
      end

      def read_text(file)
        File.read(file, encoding: 'UTF-8').freeze
      end

      # A YAML file of the source as a mapping, or {} when it is missing, is
      # not valid YAML (or has aliases, tags or classes) or is not a mapping:
      # one bad file leaves the source's other files, and the other sources,
      # working. The log names the file, not the error.
      def read_yaml(name)
        file = root.join(name)
        return {} unless file.file?

        data = YAML.safe_load_file(file, freeze: true)
        return data if data.is_a?(Hash)

        Rails.logger.warn("redmine_kit_help: #{file} is not a mapping; ignored") unless data.nil?
        {}
      rescue Psych::Exception, SystemStackError
        Rails.logger.warn("redmine_kit_help: #{file} is not valid YAML; ignored")
        {}
      end
    end
  end
end
