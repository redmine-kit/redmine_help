# frozen_string_literal: true

# Coverage of the plugin's own files (COVERAGE=1 bin/test sets PLUGIN_COVERAGE
# for the plugin's tests), written as Cobertura XML to coverage/ for Codecov.
# It starts before Redmine loads, so that lib/ and app/ are counted.
if !ENV['PLUGIN_COVERAGE'].to_s.empty? && !(defined?(SimpleCov) && SimpleCov.running)
  require 'simplecov'
  require 'simplecov-cobertura'
  SimpleCov.start do
    root File.expand_path('..', __dir__)
    # Every file of the plugin, so that a file no test loads shows as 0%. The
    # glob is absolute: SimpleCov reads it from the current directory
    # (Redmine's when bin/rails test runs), not from root.
    track_files "#{root}/{init.rb,app/**/*.rb,lib/**/*.rb}"
    add_filter '/test/'
    enable_coverage :branch
    formatter SimpleCov::Formatter::CoberturaFormatter
  end
end

require File.expand_path('../../../test/test_helper', __dir__)

module RedmineKit
  module Help
    module TestHelper
      FIXTURES = File.expand_path('fixtures/help', __dir__)

      # The help of the fixtures: the guide, a plugin's help/ and the
      # operator's directory, as the given environment would have them.
      def with_help(...)
        use_help(...)
        yield
      ensure
        restore_help
      end

      def use_help(guide: true, extra: false, plugin: false)
        @saved_help_env = ENV.to_h.slice('REDMINE_KIT_HELP_GUIDE_PATH', 'REDMINE_KIT_HELP_EXTRA_PATH')
        ENV['REDMINE_KIT_HELP_GUIDE_PATH'] = guide ? File.join(FIXTURES, 'guide') : nil
        ENV['REDMINE_KIT_HELP_EXTRA_PATH'] = extra ? File.join(FIXTURES, 'extra') : nil
        plugins = plugin ? [RedmineKit::Help::Source.new('sample', File.join(FIXTURES, 'plugin'), :plugin)] : []
        RedmineKit::Help::Source.stubs(:plugins).returns(plugins)
        RedmineKit::Help.reset!
        # each test starts with no search counted or cached: the rate limit's own store (Redmine's test environment's
        # Rails.cache counts nothing: RateLimitStore), Json.search's cache
        RedmineKit::Help::RateLimitStore.store = ActiveSupport::Cache::MemoryStore.new(size: 1.megabyte)
        RedmineKit::Help::Json::SEARCH_CACHE.clear
      end

      def restore_help
        RedmineKit::Help::Source.unstub(:plugins)
        RedmineKit::Help::RateLimitStore.store = nil
        saved = @saved_help_env || {}
        saved.each { |key, value| ENV[key] = value }
        %w[REDMINE_KIT_HELP_GUIDE_PATH REDMINE_KIT_HELP_EXTRA_PATH].each do |key|
          ENV.delete(key) unless saved.key?(key)
        end
        RedmineKit::Help.reset!
      end
    end
  end
end
