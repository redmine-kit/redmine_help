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
