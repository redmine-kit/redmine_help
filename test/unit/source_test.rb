# frozen_string_literal: true

require_relative '../test_helper'

module RedmineKit
  module Help
    class SourceTest < ActiveSupport::TestCase
      include RedmineKit::Help::TestHelper

      BROKEN_MAP = <<~YAML
        issues#index: [user/issues
      YAML

      LIST_INDEX = <<~YAML
        - id: support
          topics: [support/contact]
      YAML

      ALIASES_MAP = <<~YAML
        issues#index: &topic user/issues
        issues#show: *topic
      YAML

      SECTIONS_NOT_A_LIST = <<~YAML
        sections: support
      YAML

      TOPIC = <<~MARKDOWN
        # Contact

        Ask the help desk.
      MARKDOWN

      teardown do
        FileUtils.rm_rf(@extra) if @extra
      end

      # The operator's directory with these files, next to the fixtures' guide.
      def with_extra(files, &)
        @extra = Dir.mktmpdir('redmine_kit_help')
        files.each do |name, content|
          FileUtils.mkdir_p(File.dirname(File.join(@extra, name)))
          File.write(File.join(@extra, name), content)
        end
        with_help(extra: true) do
          ENV['REDMINE_KIT_HELP_EXTRA_PATH'] = @extra
          RedmineKit::Help.reset!
          yield RedmineKit::Help.library
        end
      end

      def warnings
        messages = []
        Rails.logger.stubs(:warn).with { |message| messages << message }
        yield
        messages
      ensure
        Rails.logger.unstub(:warn)
      end

      test 'a map.yml that is not valid YAML is left out, and the other sources still answer' do
        logged = warnings do
          with_extra('map.yml' => BROKEN_MAP, 'en/support/contact.md' => TOPIC) do |library|
            assert_equal({}, library.sources.first.map)
            assert_equal ['user/issue-list'], library.resolve('issues', 'index')
            assert_equal 'Contact', library.topic('support/contact', 'en').title
          end
        end
        assert_equal 1, logged.size
        assert_includes logged.first, File.join(@extra, 'map.yml')
        assert_not_includes logged.first, 'user/issues', 'the log names the file, not its content'
      end

      test 'an index.yml that is a list, not a mapping, gives no sections' do
        logged = warnings do
          with_extra('index.yml' => LIST_INDEX, 'en/support/contact.md' => TOPIC) do |library|
            assert_equal [], library.sources.first.index
            assert_equal %w[user admin], library.sections('en').map(&:id)
          end
        end
        assert_includes logged.first, File.join(@extra, 'index.yml')
      end

      test 'sections that are not a list of mappings are left out' do
        with_extra('index.yml' => SECTIONS_NOT_A_LIST) do |library|
          assert_equal [], library.sources.first.index
          assert_equal %w[user admin], library.sections('en').map(&:id)
        end
      end

      test 'YAML aliases are not read' do
        warnings do
          with_extra('map.yml' => ALIASES_MAP) do |library|
            assert_equal({}, library.sources.first.map)
            assert_equal ['user/issue-list'], library.resolve('issues', 'index')
          end
        end
      end

      test 'a YAML file too deep to read is left out' do
        with_extra('map.yml' => "issues#index: user/issues\n") do |library|
          YAML.stubs(:safe_load_file).raises(SystemStackError)
          logged = warnings { assert_equal({}, library.sources.first.map) }
          assert_includes logged.first, File.join(@extra, 'map.yml')
        ensure
          YAML.unstub(:safe_load_file)
        end
      end
    end
  end
end
