# frozen_string_literal: true

require_relative '../test_helper'

# The help as JSON for the new UI's panel and pages: the same library, language and map as Redmine's pages, open to
# whoever may open Redmine's pages.
class HelpTopicsJsonTest < Redmine::ControllerTest
  tests HelpTopicsController
  include RedmineKit::Help::TestHelper

  def setup
    User.current = nil
  end

  def json
    response.parsed_body['help']
  end

  test 'the contents: the sections with their topics, the operator’s first' do
    with_help(extra: true) do
      get :index, params: { lang: 'en' }, format: :json
      assert_response :success
      assert_equal 'application/json', response.media_type
      assert_equal %w[support user admin], json['sections'].pluck('id')
      user = json['sections'][1]
      assert_equal 'User guide', user['title']
      assert_equal [['user/issues', 'Issue tracking'], ['user/issue-list', 'The issue list']],
                   user['topics'].map(&:values)
    end
  end

  test 'a topic: its Markdown with the links and images rewritten, its anchors, the operator’s blocks, its section' do
    with_help(extra: true) do
      get :show, params: { topic: 'user/issues', lang: 'en', anchor: 'Updating-an-issue' }, format: :json
      assert_response :success
      topic = json['topic']
      assert_equal 'Issue tracking', topic['title']
      assert_equal %w[Issue-tracking Updating-an-issue], topic['anchors']
      assert_equal 'Updating-an-issue', topic['anchor']
      assert_includes topic['body'], '[issue list](/help/user/issue-list#filters)'
      assert_includes topic['body'], '[settings](/help/admin/settings)'
      assert_includes topic['body'], '![An issue](/help/assets/en/user/images/issue.png)'
      assert_equal ['**Help desk:** extension 1234', 'Issues are reviewed every Monday.'], json['support'].map(&:strip)
      assert_equal 'user', json.dig('section', 'id')
    end
  end

  test "a topic in the user's language: the anchors of the translation, the fallback's language said" do
    with_help do
      get :show, params: { topic: 'user/issues', lang: 'ja', anchor: 'Updating-an-issue' }, format: :json
      assert_equal 'ja', json.dig('topic', 'language')
      assert_equal 'チケットの更新', json.dig('topic', 'anchor')
      assert_includes json.dig('topic', 'body'), '(/help/user/issues#チケットの更新)'
      get :show, params: { topic: 'user/issue-list', lang: 'ja' }, format: :json
      assert_equal 'en', json.dig('topic', 'language')
    end
  end

  test 'an unknown topic, or one outside the help, is a 404' do
    with_help do
      get :show, params: { topic: 'user/nothing' }, format: :json
      assert_response :not_found
      get :show, params: { topic: '../../config/database' }, format: :json
      assert_response :not_found
    end
  end

  test 'the search: every word, a snippet; other shapes of q are no search' do
    with_help do
      get :search, params: { q: 'issue update', lang: 'en' }, format: :json
      assert_equal %w[user/issues], json['results'].pluck('id')
      assert_includes json['results'].first['snippet'], 'Update'
      get :search, params: { q: { a: 'issue' }, lang: 'en' }, format: :json
      assert_response :success
      assert_equal [], json['results']
    end
  end

  # the new UI's screen => [topic, anchor, follow]
  CONTEXTS = {
    { screen: 'ProjectTable' } => ['user/issue-list', nil, false],
    { screen: 'IssueEdit' } => ['user/issues', nil, false],
    { screen: 'AdminSettings', tab: 'authentication' } => ['admin/settings', 'authentication', true],
    { screen: 'AdminSettings', tab: 'display' } => ['admin/settings', nil, false],
    { screen: 'News' } => [nil, nil, false],
    { screen: 'redmine_kit_agile:AgileBacklog' } => [nil, nil, false],
    { screen: '../issues' } => [nil, nil, false],
    { screen: %w[Main] } => [nil, nil, false]
  }.freeze

  CONTEXTS.each do |params, (topic, anchor, follow)|
    test "the screen's topic: #{params.inspect}" do
      with_help do
        get :context, params: params.merge(lang: 'en'), format: :json
        assert_response :success
        assert_equal [topic, anchor, follow], json.values_at('topic', 'anchor', 'follow')
      end
    end
  end

  # Redmine's help pages (help#show_wiki_syntax, #show_code_highlighting) as the guide's topics: the new UI draws the
  # topic at Redmine's address (G53). syntax => [text formatting, topic]
  SYNTAXES = {
    'wiki' => [['markdown', 'user/text-formatting-markdown'], ['common_mark', 'user/text-formatting-markdown'],
               ['textile', 'user/text-formatting-textile'], ['', 'user/text-formatting-markdown']],
    'code' => [['markdown', 'user/code-highlighting-languages'], ['textile', 'user/code-highlighting-languages']],
    'other' => [['markdown', nil]],
    '../user/issues' => [['markdown', nil]]
  }.freeze

  SYNTAXES.each do |syntax, cases|
    cases.each do |formatting, topic|
      test "Redmine's help page #{syntax} with the text formatting #{formatting.inspect}" do
        with_help do
          with_settings text_formatting: formatting do
            get :context, params: { syntax: syntax, lang: 'en' }, format: :json
            assert_response :success
            assert_equal [topic, nil, false], json.values_at('topic', 'anchor', 'follow')
          end
        end
      end
    end
  end

  test "Redmine's help page: a syntax that isn't text is none" do
    with_help do
      get :context, params: { syntax: %w[wiki], lang: 'en' }, format: :json
      assert_response :success
      assert_nil json['topic']
    end
  end

  test "the search: at most #{HelpTopicsController::SEARCH_LIMIT} a minute per IP address, then 429, again later" do
    with_help do
      HelpTopicsController::SEARCH_LIMIT.times do |i|
        get :search, params: { q: "issue #{i}", lang: 'en' }, format: :json
        assert_response :success, i.to_s
      end
      get :search, params: { q: 'issue', lang: 'en' }, format: :json
      assert_response :too_many_requests
      # the pages too: one count
      get :search, params: { q: 'issue', lang: 'en' }
      assert_response :too_many_requests
      # another address is counted on its own
      @request.remote_addr = '192.0.2.7'
      get :search, params: { q: 'issue', lang: 'en' }, format: :json
      assert_response :success
      @request.remote_addr = '0.0.0.0'
      travel 61.seconds do
        get :search, params: { q: 'issue', lang: 'en' }, format: :json
        assert_response :success
      end
    end
  end

  test 'the search JSON is cached per library, language and words' do
    with_help do
      RedmineKit::Help::Library.any_instance.expects(:search).once.returns([])
      2.times do
        get :search, params: { q: 'Issue  update', lang: 'en' }, format: :json
        assert_response :success
      end
      get :search, params: { q: 'issue update', lang: 'en' }, format: :json
      assert_equal [], json['results']
    end
  end

  test 'anonymous users get the JSON unless login is required' do
    with_help do
      get :index, format: :json
      assert_response :success
      with_settings login_required: '1' do
        get :index, format: :json
        assert_response :unauthorized
        get :show, params: { topic: 'user/issues' }, format: :json
        assert_response :unauthorized
        get :context, params: { syntax: 'wiki' }, format: :json
        assert_response :unauthorized
      end
    end
  end
end
