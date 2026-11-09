# frozen_string_literal: true

require_relative '../test_helper'

module RedmineHelp
  class LibraryTest < ActiveSupport::TestCase
    include RedmineHelp::TestHelper

    test 'resolves a screen with a parameter, then the action, then the controller' do
      with_help do
        library = RedmineHelp.library
        assert_equal %w[admin/settings authentication], library.resolve('settings', 'index', 'tab' => 'authentication')
        assert_equal ['admin/settings'], library.resolve('settings', 'index', 'tab' => 'display')
        assert_equal ['user/issue-list'], library.resolve('issues', 'index')
        assert_equal ['user/issues'], library.resolve('issues', 'edit')
        assert_nil library.resolve('news', 'index')
      end
    end

    test 'falls back to English for a topic not translated' do
      with_help do
        library = RedmineHelp.library
        assert_equal 'ja', library.topic('user/issues', 'ja').language
        assert_equal 'en', library.topic('user/issue-list', 'ja').language
        assert_nil library.topic('user/missing', 'ja')
      end
    end

    test 'chooses the language there is help in' do
      with_help do
        library = RedmineHelp.library
        assert_equal %w[en ja], library.languages
        assert_equal 'ja', library.language_for('ja')
        assert_equal 'en', library.language_for('pt-BR')
        assert_equal 'en', library.language_for(nil)
      end
    end

    test 'titles come from the first heading, after front matter' do
      with_help do
        topic = RedmineHelp.library.topic('user/issues', 'en')
        assert_equal 'Issue tracking', topic.title
        assert_not_includes topic.body, 'source_version'
      end
    end

    test 'the operator directory overrides topics and maps, and adds support blocks and sections' do
      with_help(extra: true) do
        library = RedmineHelp.library
        assert_equal 'Settings (our company)', library.topic('admin/settings', 'en').title
        assert_equal ['**Help desk:** extension 1234', 'Issues are reviewed every Monday.'],
                     library.support('user/issues', 'en').map(&:strip)
        # No Japanese blocks: the English ones are used.
        assert_equal 2, library.support('user/issues', 'ja').size
        assert_equal %w[support user admin], library.sections('en').map(&:id)
      end
    end

    test "a plugin's help adds topics, a section and its screens" do
      with_help(plugin: true) do
        library = RedmineHelp.library
        assert_equal ['sample/screen'], library.resolve('sample', 'index')
        section = library.sections('en').last
        assert_equal 'Sample plugin', section.title('ja')
        assert_equal ['sample/screen'], section.topics.map(&:id)
      end
    end

    test 'searches titles and text' do
      with_help do
        results = RedmineHelp.library.search('filter issues', 'en')
        assert_equal(['user/issue-list'], results.map { |topic, _| topic.id })
        assert_empty RedmineHelp.library.search('', 'en')
      end
    end

    test 'serves only images inside a source' do
      with_help do
        assert RedmineHelp.library.asset('en/user/images/issue.png')
        assert_nil RedmineHelp.library.asset('../../../../etc/passwd')
        assert_nil RedmineHelp.library.asset('en/user/issues.md')
      end
    end

    test 'no help without sources' do
      with_help(guide: false) do
        assert_not RedmineHelp.library.available?
        assert_empty RedmineHelp.library.sections('en')
      end
    end
  end
end
