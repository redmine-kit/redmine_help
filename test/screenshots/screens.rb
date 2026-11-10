# frozen_string_literal: true

require_relative 'screenshot_case'

# The screens of docs/README.md, with the guide of redmine-guide
# (REDMINE_HELP_GUIDE_PATH, set by bin/screenshots): the side panel next to
# the new issue form and over a tab of Administration › Settings, and the
# help page of the issue list.
class RedmineHelpScreenshotsTest < ScreenshotCase
  def test_screens
    each_language do |language|
      visit '/projects/ecookbook/issues/new'
      open_panel
      shoot_window 'help-panel', language
      close_panel

      visit '/settings?tab=authentication'
      open_panel
      shoot_window 'help-panel-settings', language
      close_panel

      visit '/projects/ecookbook/issues'
      # The help page, as the Help link opens it without JavaScript and the
      # panel's full view link opens it in a new window.
      visit find('#top-menu a.help')[:href]
      assert_selector 'div.wiki.wiki-page ul.toc'
      load_images
      shoot_window 'help', language
    end
  end

  private

  # Opens the side panel with the Help link and waits for its images. The
  # panel's scroll position (the mapped section) is kept.
  def open_panel
    # The script has set the link up as the panel's button.
    find('#top-menu a.help[aria-controls="help-panel"]').click
    assert_selector '#help-panel .help-panel-content div.wiki-page', wait: 30
    page.execute_script("document.querySelectorAll('#help-panel img').forEach(function (i) { i.loading = 'eager'; })")
    Timeout.timeout(30) do
      sleep 0.2 until page.evaluate_script(
        "Array.from(document.querySelectorAll('#help-panel img')).every(function (img) { return img.complete; })"
      )
    end
  end

  # Closes the panel, so that the next screen opens without it.
  def close_panel
    find('#help-panel .help-panel-close').click
    assert_no_selector '#help-panel'
  end

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
