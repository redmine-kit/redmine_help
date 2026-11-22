# frozen_string_literal: true

require_relative '../test_helper'

module RedmineKit
  module Help
    # rake redmine_kit:help:check: a plugin's help/ against the installed guide.
    class CheckTest < ActiveSupport::TestCase
      include RedmineKit::Help::TestHelper

      test "a plugin's correct help has no problem" do
        with_help(plugin: %w[another sample]) do
          assert_empty Check.new.problems
          assert_equal %w[another sample], Check.new.plugins
        end
      end

      test "names each problem of a plugin's help with its file" do
        Rails.logger.stubs(:warn)
        with_help(plugin: %w[broken sample]) do
          root = File.join(FIXTURES, 'broken')
          assert_equal [
            "#{root}/map.yml: broken#index: no heading Missing-heading in user/issues",
            "#{root}/map.yml: broken#show: no topic nothing/here",
            "#{root}/en/_insertions/no-heading.md: no heading No-such-heading in user/issues",
            "#{root}/en/_insertions/no-topic.md: no topic user/nothing",
            "#{root}/en/_insertions/unplaced.md: names no topic and heading (topic:, after:)",
            "#{root}/en/_insertions/wrong-level.md: its heading is level 4; after Closing-an-issue (level 2) it is " \
            'level 2 or 3',
            "#{root}/ja/_insertions/orphan.md: no English section orphan"
          ], Check.new.problems('broken')
          assert_empty Check.new.problems('sample')
        end
      end

      test "checks a help/ that isn't installed as the plugin given, in place of the plugin's own" do
        Rails.logger.stubs(:warn)
        with_help(plugin: %w[sample]) do
          library = Check.library_with('sample', File.join(FIXTURES, 'broken'))
          assert_equal %w[sample], Check.new(library).plugins
          assert_includes Check.new(library).problems('sample'),
                          "#{File.join(FIXTURES, 'broken')}/en/_insertions/no-topic.md: no topic user/nothing"
        end
      end
    end
  end
end
