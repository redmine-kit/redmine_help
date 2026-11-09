# frozen_string_literal: true

require_relative 'screenshot_case'

# The help screen of docs/README.md: the help for the issue list, opened by
# the header's Help link, with the guide of redmine-guide
# (REDMINE_HELP_GUIDE_PATH, set by bin/screenshots).
class RedmineHelpScreenshotsTest < ScreenshotCase
  def test_screens
    each_language do |language|
      visit '/projects/ecookbook/issues'
      # The link opens a new tab; the screenshot follows it in this one.
      visit find('#top-menu a.help')[:href]
      assert_selector 'div.wiki.wiki-page ul.toc'
      shoot 'help', language, selector: '#main'
    end
  end
end
