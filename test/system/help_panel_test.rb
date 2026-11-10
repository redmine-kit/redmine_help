# frozen_string_literal: true

require_relative '../test_helper'
require File.expand_path('../../../../test/application_system_test_case', __dir__)

module RedmineHelp
  # The side panel in a browser (assets/javascripts/help_panel.js), with the
  # help of test/fixtures/help. bin/test runs it in headless Chromium.
  class HelpPanelTest < ApplicationSystemTestCase
    include RedmineHelp::TestHelper

    fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles, :trackers, :projects_trackers,
             :enabled_modules, :issue_statuses, :issues, :enumerations, :custom_fields, :custom_values,
             :custom_fields_trackers, :workflows, :versions, :issue_categories

    setup do
      use_help(extra: true)
      User.find(1).update!(language: 'en')
    end

    teardown do
      restore_help
    end

    test 'the Help link opens the panel next to the page, which stays usable' do
      start '/projects/ecookbook/issues/new'
      assert_equal 'false', help_link['aria-expanded']
      assert_equal 'help-panel', help_link['aria-controls']
      assert_equal 'button', help_link['role']
      help_link.click
      within_panel do
        assert_selector '#help-panel-title', text: 'Issue tracking'
        assert_selector 'div.wiki-page', text: 'Issues are the heart of Redmine'
        assert_selector 'div.box.wiki', text: 'extension 1234'
      end
      assert_equal 'true', help_link['aria-expanded']
      assert_equal 'help-panel-title', active_element_id
      fill_in 'issue_subject', with: 'Typed with the help open'
      assert_equal 'Typed with the help open', find('#issue_subject').value
      assert_selector '#help-panel'
      help_link.click
      assert_no_selector '#help-panel'
      assert_equal 'false', help_link['aria-expanded']
    end

    test 'links open in the panel, and Back returns' do
      start '/projects/ecookbook/issues/new'
      help_link.click
      within_panel do
        assert_selector '#help-panel-title', text: 'Issue tracking'
        assert_no_selector '.help-panel-back'
        click_link 'issue list'
        assert_selector '#help-panel-title', text: 'Issue list'
        assert_selector 'a.help-panel-full-view[href$="/help/user/issue-list#filters"]'
        find('.help-panel-back').click
        assert_selector '#help-panel-title', text: 'Issue tracking'
        assert_no_selector '.help-panel-back'
      end
      assert_current_path '/projects/ecookbook/issues/new'
    end

    test 'the search shows its results in the panel' do
      start '/projects/ecookbook/issues'
      help_link.click
      within_panel do
        assert_selector '#help-panel-title', text: 'Issue list'
        fill_in 'help-panel-search-q', with: 'filter'
        find('#help-panel-search-q').send_keys(:enter)
        assert_selector '#help-panel-title', text: 'Search'
        click_link 'Issue list'
        assert_selector '#help-panel-title', text: 'Issue list'
      end
    end

    test 'the panel follows a tab that has a topic of its own' do
      start '/settings'
      help_link.click
      within_panel do
        assert_selector '#help-panel-title', text: 'Settings (our company)'
        assert_no_selector 'a.help-panel-full-view[href*="#"]'
      end
      find('#tab-authentication').click
      within_panel do
        assert_selector 'a.help-panel-full-view[href$="/help/admin/settings#authentication"]'
        assert_selector '.help-panel-back'
      end
      assert_includes help_link[:href], 'tab=authentication'
      # Display has no topic of its own: the panel stays.
      find('#tab-display').click
      assert_includes help_link[:href], 'tab=display'
      within_panel { assert_selector 'a.help-panel-full-view[href$="#authentication"]' }
    end

    test 'Esc closes the panel and the focus returns to the Help link' do
      start '/projects/ecookbook/issues'
      help_link.click
      within_panel { assert_selector '#help-panel-title', text: 'Issue list' }
      find('#help-panel-title').send_keys(:escape)
      assert_no_selector '#help-panel'
      assert_equal 'false', help_link['aria-expanded']
      assert_equal help_link['href'], page.evaluate_script('document.activeElement.href')
    end

    test 'an open panel opens again on the next screen, with its topic' do
      start '/projects/ecookbook/issues'
      help_link.click
      within_panel { assert_selector '#help-panel-title', text: 'Issue list' }
      visit '/projects/ecookbook/issues/new'
      within_panel { assert_selector '#help-panel-title', text: 'Issue tracking' }
      find('.help-panel-close').click
      assert_no_selector '#help-panel'
      visit '/projects/ecookbook/issues'
      assert_selector '#top-menu a.help[aria-expanded="false"]'
      assert_no_selector '#help-panel'
    end

    test 'on a narrow window the panel covers the window' do
      start '/projects/ecookbook/issues'
      page.driver.browser.manage.window.resize_to(500, 800)
      find('.js-flyout-menu-toggle-button').click
      find('.js-flyout-menu a.help').click
      within_panel { assert_selector '#help-panel-title', text: 'Issue list' }
      assert_equal 0, page.evaluate_script("document.getElementById('help-panel').getBoundingClientRect().left").to_i
      find('.help-panel-close').click
      assert_no_selector '#help-panel'
    ensure
      page.driver.browser.manage.window.resize_to(1024, 900)
    end

    private

    def start(path)
      log_user('admin', 'admin')
      visit path
      page.execute_script('window.localStorage.clear()')
      visit path
    end

    def help_link
      find('#top-menu a.help')
    end

    def within_panel(&)
      within('#help-panel', &)
    end

    def active_element_id
      page.evaluate_script('document.activeElement.id')
    end
  end
end
