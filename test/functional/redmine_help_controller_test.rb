# frozen_string_literal: true

require_relative '../test_helper'

class RedmineHelpControllerTest < Redmine::ControllerTest
  include RedmineHelp::TestHelper

  def setup
    User.current = nil
    @request.session[:user_id] = 2
  end

  test 'context opens the topic mapped to the screen, with its anchor' do
    with_help do
      get :context, params: { c: 'settings', a: 'index', tab: 'authentication' }
      assert_redirected_to '/help/admin/settings#authentication'
    end
  end

  test 'context opens the index for a screen without a topic' do
    with_help do
      get :context, params: { c: 'news', a: 'index' }
      assert_redirected_to '/help'
    end
  end

  test 'show renders the topic like a wiki page, with the table of contents and rewritten links' do
    with_help do
      get :show, params: { topic: 'user/issues', lang: 'en' }
      assert_response :success
      assert_select 'div.wiki.wiki-page h1', text: /Issue tracking/
      assert_select 'div.wiki.wiki-page ul.toc.right a[href="#Updating-an-issue"]'
      assert_select 'a[href="/help/user/issue-list?lang=en#filters"]'
      assert_select 'a[href="/help/admin/settings?lang=en"]'
      assert_select 'img[src="/help/assets/en/user/images/issue.png"]'
      retina = '/help/assets/en/user/images/issue@2x.png'
      assert_select "img[src=\"#{retina}\"][srcset=\"#{retina} 2x\"]"
      assert_select '#sidebar h3', text: 'User guide'
      assert_select '#sidebar strong', text: 'Issue tracking'
    end
  end

  test "show uses the user's language and says when it falls back" do
    User.find(2).update!(language: 'ja')
    with_help do
      get :show, params: { topic: 'user/issues' }
      assert_select 'div.wiki h1', text: /チケットトラッキング/
      get :show, params: { topic: 'user/issue-list' }
      assert_select 'div.wiki h1', text: /Issue list/
      assert_select 'p.other-formats', text: /English/
    end
  end

  test 'show adds the support blocks and the overrides of the operator directory' do
    with_help(extra: true) do
      get :show, params: { topic: 'user/issues', lang: 'en' }
      assert_select 'div.box.wiki', text: /extension 1234/
      assert_select 'div.box.wiki', text: /every Monday/
      get :show, params: { topic: 'admin/settings', lang: 'en' }
      assert_select 'div.wiki h1', text: /our company/
    end
  end

  test 'show answers 404 for an unknown topic' do
    with_help do
      get :show, params: { topic: 'user/missing' }
      assert_response :not_found
    end
  end

  test 'index lists the sections, and says when no help is installed' do
    with_help do
      get :index, params: { lang: 'ja' }
      assert_select 'h3', text: 'ユーザーガイド'
    end
    with_help(guide: false) do
      get :index
      assert_select 'p.nodata'
    end
  end

  test 'search lists the matching topics' do
    with_help do
      get :search, params: { q: 'filter', lang: 'en' }
      assert_select 'dl#search-results dt a', text: 'Issue list'
      get :search, params: { q: 'nothing-like-this', lang: 'en' }
      assert_select 'p.nodata'
    end
  end

  test 'asset sends an image and refuses other files' do
    with_help do
      get :asset, params: { path: 'en/user/images/issue.png' }
      assert_response :success
      get :asset, params: { path: 'en/user/images/issue@2x.png' }
      assert_response :success
      get :asset, params: { path: 'en/user/issues.md' }
      assert_response :not_found
    end
  end

  test 'anonymous users can read the help unless login is required' do
    @request.session[:user_id] = nil
    with_help do
      get :show, params: { topic: 'user/issues' }
      assert_response :success
      with_settings login_required: '1' do
        get :show, params: { topic: 'user/issues' }
        assert_response :redirect
      end
    end
  end
end
