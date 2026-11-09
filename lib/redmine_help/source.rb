# frozen_string_literal: true

module RedmineHelp
  # A directory of help: <language>/<topic>.md, index.yml (the sections of
  # the sidebar) and map.yml (screens to topics). See docs/extending.md.
  class Source
    attr_reader :id, :root, :kind

    def initialize(id, root, kind)
      @id = id
      @root = Pathname(root)
      @kind = kind
    end

    # In order of precedence: the operator's directory, the plugins, the guide.
    def self.all
      [extra, *plugins, guide].compact
    end

    # The Redmine guide: REDMINE_HELP_GUIDE_PATH (a checkout of
    # redmine-kit/redmine-guide), or the redmine-guide gem.
    def self.guide
      path = ENV['REDMINE_HELP_GUIDE_PATH'].presence
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
        new(plugin.id.to_s, dir, :plugin) if plugin.id != :redmine_help && File.directory?(dir)
      end
    end

    # The operator's directory: support pages, additions and overrides.
    def self.extra
      path = ENV['REDMINE_HELP_EXTRA_PATH'].presence
      path && File.directory?(path) ? new('extra', path, :extra) : nil
    end

    def languages
      Dir.children(root).select { |name| name.match?(/\A[a-z]{2}(-[a-z0-9]+)?\z/i) && root.join(name).directory? }
    end

    # Topics of a language: "user/issues" => path.
    def topics(language)
      dir = root.join(language)
      return {} unless dir.directory?

      Dir.glob('**/*.md', base: dir).each_with_object({}) do |file, topics|
        next if File.basename(file).start_with?('_')

        topics[file.delete_suffix('.md')] = dir.join(file)
      end
    end

    # Blocks added to pages: <language>/_support.md (every page) and
    # <language>/_support/<topic>.md (one topic).
    def support(language, topic)
      [root.join(language, '_support.md'), root.join(language, '_support', "#{topic}.md")].select(&:file?)
    end

    def index
      read_yaml('index.yml')['sections'] || []
    end

    def map
      read_yaml('map.yml')
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

    def read_yaml(name)
      file = root.join(name)
      file.file? ? (YAML.safe_load_file(file) || {}) : {}
    end
  end
end
