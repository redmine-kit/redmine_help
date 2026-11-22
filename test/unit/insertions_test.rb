# frozen_string_literal: true

require_relative '../test_helper'

module RedmineKit
  module Help
    # The plugins' sections in the guide's topics: placed at the end of their
    # heading's section, in the plugins' order, in the topic's language or in
    # English, never in the operator's replacement; a section without its
    # topic or heading is left out, the log naming its file.
    class InsertionsTest < ActiveSupport::TestCase
      include RedmineKit::Help::TestHelper

      def headings(topic)
        topic.body.scan(/^##+ (.+)$/).flatten
      end

      test "a section goes at the end of its heading's section, before the next heading" do
        with_help(plugin: true) do
          topic = RedmineKit::Help.library.topic('user/issues', 'en')
          assert_equal ['Updating an issue', 'Sample items', 'Closing an issue'], headings(topic)
          assert_equal %w[Issue-tracking Updating-an-issue Sample-items Closing-an-issue], topic.anchors
          assert_equal [{ anchor: 'Sample-items', plugin: 'sample', name: 'Sample plugin', language: 'en',
                          label: 'Sample plugin' }], topic.insertions
          assert_match(/Update an issue from its page\.\n\n## Sample items\n/, topic.body)
        end
      end

      test 'several sections at one place come in the plugins’ order' do
        with_help(plugin: %w[another sample]) do
          topic = RedmineKit::Help.library.topic('user/issues', 'en')
          assert_equal ['Updating an issue', "Another plugin's part", 'Sample items', 'Closing an issue'],
                       headings(topic)
          assert_equal %w[another sample], topic.insertions.pluck(:plugin)
        end
      end

      test "in the topic's language, else in English; the heading found by its position" do
        with_help(plugin: %w[another sample]) do
          topic = RedmineKit::Help.library.topic('user/issues', 'ja')
          assert_equal ['チケットの更新', "Another plugin's part", 'サンプルの項目', 'チケットの終了'], headings(topic)
          places = topic.insertions.map { |insertion| insertion.values_at(:anchor, :language) }
          assert_equal [%w[Another-plugins-part en], %w[サンプルの項目 ja]], places
          # an English anchor of a section (map.yml) is the translation's at the same position
          assert_equal 'サンプルの項目', RedmineKit::Help.library.anchor('user/issues', 'ja', 'Sample-items')
        end
      end

      test 'the search finds the text of a section' do
        with_help(plugin: true) do
          found = RedmineKit::Help.library.search('sample plugin items', 'en').map { |topic, _| topic.id }
          assert_equal ['user/issues'], found
        end
      end

      test "a screen opens at a section (the plugin's map)" do
        with_help(plugin: true) do
          assert_equal %w[user/issues Sample-items], RedmineKit::Help.library.resolve('sample', 'items')
        end
      end

      test "the operator's replacement of the topic gets no section" do
        with_help(extra: true, plugin: true) do
          topic = RedmineKit::Help.library.topic('admin/settings', 'en')
          assert_equal :extra, topic.source.kind
          assert_empty topic.insertions
        end
      end

      test 'a topic without sections is the file as it is' do
        with_help(plugin: true) do
          library = RedmineKit::Help.library
          assert_same library.base_topic('user/issue-list', 'en'), library.topic('user/issue-list', 'en')
        end
      end

      test 'a section without its topic or heading, or without front matter, is left out, the log naming it' do
        logged = []
        Rails.logger.stubs(:warn).with { |message| logged << message }
        with_help(plugin: %w[broken]) do
          topic = RedmineKit::Help.library.topic('user/issues', 'en')
          RedmineKit::Help.library.topic('user/issues', 'ja')
          assert_equal ['Updating an issue', 'Closing an issue', 'Too deep'], headings(topic)
        end
        broken = File.join(FIXTURES, 'broken/en/_insertions')
        assert_includes logged, "redmine_kit_help: #{broken}/no-topic.md: no topic user/nothing; ignored"
        assert_includes logged, "redmine_kit_help: #{broken}/no-heading.md: " \
                                'no heading No-such-heading in user/issues (en); ignored'
        assert_includes logged,
                        "redmine_kit_help: #{broken}/unplaced.md names no topic and heading (topic:, after:); ignored"
        assert_equal logged.uniq, logged, 'each problem once'
      end

      test 'insertions are not topics' do
        with_help(plugin: true) do
          ids = RedmineKit::Help.library.topics('en').map(&:id)
          assert(ids.none? { |id| id.include?('_insertions') })
        end
      end
    end
  end
end
