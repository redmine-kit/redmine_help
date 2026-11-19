# frozen_string_literal: true

require_relative '../test_helper'

module RedmineKit
  module Help
    # A topic's Markdown for the new UI: relative links to topics and images rewritten, everything else as written.
    class MarkdownLinksTest < ActiveSupport::TestCase
      include TestHelper

      def rewrite(markdown, language = 'en')
        MarkdownLinks.rewrite(markdown, 'user/issues', language, Help.library)
      end

      test 'links to topics, relative to the topic, with their anchors' do
        with_help do
          assert_equal '[a](/help/user/issue-list#filters)', rewrite('[a](issue-list.md#filters)')
          assert_equal '[b](/help/admin/settings "t")', rewrite('[b](../admin/settings.md "t")')
          assert_equal '[c](/help/user/issues#チケットの更新)', rewrite('[c](issues.md#Updating-an-issue)', 'ja')
        end
      end

      test 'images under /help/assets in the language; a path that goes up stays under it' do
        with_help do
          assert_equal '![x](/help/assets/en/user/images/issue.png)', rewrite('![x](images/issue.png)')
          assert_equal '![x](/help/assets/etc/passwd)', rewrite('![x](../../../etc/passwd)')
        end
      end

      test 'other links, absolute ones and code stay as written' do
        with_help do
          ['[r](https://www.redmine.org/)', '[s](/projects)', '[t](#top)', '[u](notes.txt)', '`[v](issues.md)`',
           "```\n[w](issues.md)\n```"].each { |text| assert_equal text, rewrite(text) }
        end
      end
    end
  end
end
