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
      load_images
      shoot_window 'help', language
    end
  end

  private

  # Saves the browser window (Redmine's header, the start of the page and
  # the sidebar) as docs/<images>/<name>.png: a help page is too long for a
  # screenshot of the whole page.
  def shoot_window(name, language)
    page.driver.browser.manage.window.resize_to(1280, 1000)
    page.execute_script('window.scrollTo(0, 0); document.activeElement?.blur()')
    path = File.join(DOCS, LANGUAGES.fetch(language), "#{name}.png")
    page.driver.browser.save_screenshot(path)
    assert File.size?(path), "no screenshot at #{path}"
  end

  # Loads every image of the page before the screenshot: the window grows
  # only when the screenshot is taken, and images below the window may not
  # have loaded yet.
  def load_images
    page.execute_script("document.querySelectorAll('img').forEach(function (img) { img.loading = 'eager'; })")
    page.driver.browser.manage.window.resize_to(1280, 6000)
    Timeout.timeout(30) do
      sleep 0.2 until page.evaluate_script('Array.from(document.images).every(function (img) { return img.complete; })')
    end
  end
end
