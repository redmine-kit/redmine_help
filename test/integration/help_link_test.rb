# frozen_string_literal: true

require_relative '../test_helper'

module RedmineHelp
  class HelpLinkTest < Redmine::IntegrationTest
    include RedmineHelp::TestHelper

    test "the header's Help link points at the help for the current screen" do
      with_help do
        log_user('admin', 'admin')
        get '/settings?tab=authentication'
        assert_select '#top-menu a.help[href=?]', '/help/context?a=index&c=settings&tab=authentication'
        get '/projects/ecookbook/issues'
        assert_select '#top-menu a.help[href=?]', '/help/context?a=index&c=issues'
        get '/help/context?a=index&c=issues'
        assert_redirected_to '/help/user/issue-list'
      end
    end

    test "without JavaScript the Help link opens the help page in a new tab, as Redmine's does" do
      with_help do
        log_user('admin', 'admin')
        get '/projects/ecookbook/issues/new'
        assert_select '#top-menu a.help[target="_blank"][rel="noopener"][href=?]', '/help/context?a=new&c=issues'
        get '/help/context?a=new&c=issues'
        assert_redirected_to '/help/user/issues'
      end
    end

    test 'the side panel is loaded on Redmine pages, not on the help pages' do
      with_help do
        get '/projects/ecookbook/issues'
        assert_select 'head script[src*="plugin_assets/redmine_help/help_panel"][defer]'
        assert_select 'head link[href*="plugin_assets/redmine_help/help_panel"]'
        get '/help/user/issues'
        assert_select 'head script[src*="help_panel"]', 0
      end
    end

    test 'images are served by their URLs, with @ and dots in their names' do
      with_help do
        get '/help/user/issues', params: { lang: 'en' }
        sources = css_select('div.wiki img').map { |image| image['src'] }
        assert_equal ['/help/assets/en/user/images/issue.png', '/help/assets/en/user/images/issue@2x.png'], sources
        sources.each do |source|
          get source
          assert_response :success, source
        end
      end
    end

    test "Redmine's own help pages (text formatting) still work" do
      with_help do
        get '/help/wiki_syntax'
        assert_response :success
        get '/help/code_highlighting'
        assert_response :success
      end
    end
  end
end
