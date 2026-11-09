# frozen_string_literal: true

# Coverage of the plugin's own files (bin/test sets PLUGIN_COVERAGE for the
# plugin's tests), written as Cobertura XML to coverage/ for Codecov.
if ENV['PLUGIN_COVERAGE']
  require 'simplecov'
  require 'simplecov-cobertura'
  SimpleCov.start do
    root File.expand_path('..', __dir__)
    add_filter '/test/'
    enable_coverage :branch
    formatter SimpleCov::Formatter::CoberturaFormatter
  end
end

require File.expand_path('../../../test/test_helper', __dir__)

module RedmineHelp
  module TestHelper
    FIXTURES = File.expand_path('fixtures/help', __dir__)

    # The help of the fixtures: the guide, a plugin's help/ and the
    # operator's directory, as the given environment would have them.
    def with_help(guide: true, extra: false, plugin: false)
      saved = ENV.to_h.slice('REDMINE_HELP_GUIDE_PATH', 'REDMINE_HELP_EXTRA_PATH')
      ENV['REDMINE_HELP_GUIDE_PATH'] = guide ? File.join(FIXTURES, 'guide') : nil
      ENV['REDMINE_HELP_EXTRA_PATH'] = extra ? File.join(FIXTURES, 'extra') : nil
      plugins = plugin ? [RedmineHelp::Source.new('sample', File.join(FIXTURES, 'plugin'), :plugin)] : []
      RedmineHelp::Source.stubs(:plugins).returns(plugins)
      RedmineHelp.reset!
      yield
    ensure
      RedmineHelp::Source.unstub(:plugins)
      saved.each { |key, value| ENV[key] = value }
      %w[REDMINE_HELP_GUIDE_PATH REDMINE_HELP_EXTRA_PATH].each { |key| ENV.delete(key) unless saved.key?(key) }
      RedmineHelp.reset!
    end
  end
end
