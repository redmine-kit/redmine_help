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

  test "context finds the anchor in the user's language" do
    User.find(2).update!(language: 'ja')
    with_help do
      get :context, params: { c: 'journals', a: 'edit' }
      assert_equal 'チケットの更新', CGI.unescape(URI(response.location).fragment)
      get :show, params: { topic: 'user/issues' }
      link = css_select('div.wiki-page p a').first
      assert_equal 'チケットの更新', CGI.unescape(URI(link['href']).fragment)
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
      assert_select 'p.other-formats', text: /言語: English/
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

  test 'context with panel=1 renders the topic for the side panel, without the layout' do
    with_help do
      get :context, params: { c: 'settings', a: 'index', tab: 'authentication', lang: 'en', panel: '1' }
      assert_response :success
      assert_not_includes response.body, '<html'
      assert_select '#top-menu', 0
      assert_select '.help-panel-header[data-anchor="authentication"][data-follow="true"]'
      assert_select '.help-panel-header h3#help-panel-title[tabindex="-1"]', text: 'Application settings'
      assert_select '.help-panel-header .contextual a.icon-maximize.help-panel-full-view' \
                    '[href="/help/admin/settings?lang=en#authentication"][target="_blank"][title="Open in full view"]'
      assert_select '.help-panel-header .contextual a.icon-close.help-panel-close[role="button"][title="Close"]'
      assert_select '.help-panel-header .contextual a.icon-back.help-panel-back[role="button"][hidden]', text: 'Back'
      assert_select '.help-panel-content form#help-panel-search[action="/help/search"] input#help-panel-search-q'
      assert_select '.help-panel-header a.icon-list.help-panel-contents[href="/help?lang=en"][target="_blank"]',
                    text: 'Table of contents'
      # The title is in the panel's header, not repeated in the text.
      assert_select '.help-panel-content div.wiki.wiki-page h1', 0
      assert_select '.help-panel-content div.wiki.wiki-page a[name="Authentication"] + h2'
    end
  end

  test "context with panel=1 tells whether the screen's tab has a topic of its own" do
    with_help do
      get :context, params: { c: 'settings', a: 'index', tab: 'display', panel: '1' }
      assert_select '.help-panel-header[data-follow="false"]'
      assert_select '#help-panel-title', text: 'Application settings'
    end
  end

  test 'context with panel=1 shows the contents for a screen without a topic' do
    with_help do
      get :context, params: { c: 'news', a: 'index', panel: '1' }
      assert_response :success
      assert_select '#help-panel-title', text: 'Help'
      assert_select '.help-panel-content h3', text: 'User guide'
      assert_select 'a.help-panel-full-view[href="/help"]'
    end
  end

  test 'show with panel=1 renders the topic like the page, with an inline table of contents and the support blocks' do
    with_help(extra: true) do
      get :show, params: { topic: 'user/issues', lang: 'en', panel: '1' }
      assert_response :success
      assert_not_includes response.body, '<html'
      assert_select '#help-panel-title', text: 'Issue tracking'
      assert_select 'div.wiki.wiki-page ul.toc:not(.right) a[href="#Updating-an-issue"]'
      assert_select 'a[href="/help/user/issue-list?lang=en#filters"]'
      assert_select 'img[src="/help/assets/en/user/images/issue.png"]'
      assert_select 'div.box.wiki', text: /extension 1234/
      assert_select 'div.box.wiki', text: /every Monday/
      get :show, params: { topic: 'user/missing', panel: '1' }
      assert_response :not_found
    end
  end

  test "the panel uses Redmine's strings in the user's language" do
    User.find(2).update!(language: 'ja')
    with_help do
      get :show, params: { topic: 'user/issue-list', panel: '1' }
      assert_select '#help-panel-title', text: 'Issue list'
      assert_select 'a.help-panel-full-view[title="全画面で表示"]'
      assert_select 'a.help-panel-close[title="閉じる"]'
      assert_select 'a.help-panel-back', text: '戻る'
      assert_select 'a[target="_blank"]', text: '目次'
      assert_select 'input#help-panel-search-q[placeholder="検索"]'
      assert_select 'p.other-formats', text: /言語: English/
    end
  end

  test 'search with panel=1 lists the results in the panel' do
    with_help do
      get :search, params: { q: 'filter', lang: 'en', panel: '1' }
      assert_response :success
      assert_not_includes response.body, '<html'
      assert_select '#help-panel-title', text: 'Search'
      assert_select 'input#help-panel-search-q[value="filter"]'
      assert_select 'dl#search-results dt a[href="/help/user/issue-list?lang=en"]', text: 'Issue list'
      assert_select 'a.help-panel-full-view[href="/help/search?lang=en&q=filter"]'
    end
  end

  test 'without panel=1 the pages keep the layout and the context redirects' do
    with_help do
      get :show, params: { topic: 'user/issues', lang: 'en' }
      assert_includes response.body, '<html'
      assert_select '#sidebar ul a[href="/help?lang=en"]:not([target])', text: 'Table of contents'
      assert_select '.help-panel-header', 0
      get :context, params: { c: 'issues', a: 'new' }
      assert_redirected_to '/help/user/issues'
    end
  end

  test 'anonymous users can read the help unless login is required' do
    @request.session[:user_id] = nil
    with_help do
      get :show, params: { topic: 'user/issues' }
      assert_response :success
      get :context, params: { c: 'issues', a: 'index', panel: '1' }
      assert_response :success
      with_settings login_required: '1' do
        get :show, params: { topic: 'user/issues' }
        assert_response :redirect
        get :show, params: { topic: 'user/issues', panel: '1' }, xhr: true
        assert_response :unauthorized
      end
    end
  end
end
