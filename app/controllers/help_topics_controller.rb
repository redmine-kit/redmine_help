# frozen_string_literal: true

# The help pages (docs/README.md). Open to whoever can see Redmine: logged-in
# users, and anonymous users when Redmine does not require login.
#
# With panel=1, context, show and search render the same content without
# Redmine's layout, for the side panel that the header's Help link opens
# (assets/javascripts/help_panel.js).
#
# With .json, index, show, search and context answer the same help as JSON
# for the new UI's panel and pages (RedmineKit::Help::Json; Redmine Kit UI's
# kit requests of the session). context.json takes the new UI's screen
# (?screen=, ?tab=) instead of Redmine's controller and action, or one of
# Redmine's help pages (?syntax=wiki|code: help#show_wiki_syntax,
# #show_code_highlighting).
#
# The search has no rate limit and no cache of its own, as Redmine's
# /search has none: the panel searches as the user types (users behind one
# office address would reach a limit per address in normal use), and it
# reads a few dozen topics the library keeps in memory, its words at most
# 100 characters (5 words: Library#search). Floods are for what stands in
# front of Redmine (a reverse proxy, AWS WAF).
class HelpTopicsController < ApplicationController
  Json = RedmineKit::Help::Json
  before_action :set_help_language
  helper :help_topics
  helper_method :panel?

  # The topic for the screen the Help link was clicked on.
  def context
    return render_context_json if json?

    key, (id, anchor) = library.lookup(params[:c].to_s, params[:a].to_s, map_params)
    @topic = library.topic(id, @language) if id
    @anchor = library.anchor(id, @language, anchor).presence if @topic
    if panel?
      # Whether the screen's parameter (a tab) has a topic of its own.
      @follow = key.to_s.include?('?')
      @topic ? render_topic : render_index
    elsif @topic
      redirect_to help_topic_path(@topic.id, lang: language_param, anchor: @anchor)
    else
      redirect_to help_index_path(lang: language_param)
    end
  end

  def index
    return render(json: Json.contents(library, @language)) if json?

    render_index
  end

  def show
    @topic = library.topic(params[:topic].to_s, @language)
    return render_404 unless @topic
    return render(json: Json.topic(library, @topic, @language, anchor: text_param(:anchor))) if json?

    render_topic
  end

  def search
    @query = text_param(:q).strip.first(100)
    return render(json: Json.search(library, @query, @language)) if json?

    @results = library.search(@query, @language)
    render_panel if panel?
  end

  def asset
    file = library.asset(params[:path].to_s)
    return render_404 unless file

    send_file file, disposition: 'inline'
  end

  private

  # The new UI's screen (?screen=, ?tab=), or one of Redmine's help pages
  # (?syntax=).
  def render_context_json
    return render(json: Json.syntax(library, @language, params[:syntax])) if params.key?(:syntax)

    render(json: Json.context(library, @language, params[:screen], params[:tab]))
  end

  def library
    RedmineKit::Help.library
  end

  # The parameters of the screen that the map's keys may name (a tab).
  def map_params
    params.permit(*RedmineKit::Help::MAP_PARAMS).to_h
  end

  def render_index
    @sections = library.sections(@language)
    @guide = library.guide?
    panel? ? render_panel : render(:index)
  end

  def render_topic
    @support = library.support(@topic.id, @language)
    @section = library.sections(@language).find { |section| section.topics.any? { |t| t.id == @topic.id } }
    panel? ? render_panel : render(:show)
  end

  def render_panel
    render :panel, layout: false
  end

  def panel?
    params[:panel] == '1'
  end

  def json?
    request.format.json?
  end

  # A parameter that should be text: anything else (an array, a hash) is none.
  def text_param(name)
    params[name].is_a?(String) ? params[name] : ''
  end

  # ?lang=xx, else the user's language, else Redmine's default.
  def set_help_language
    requested = params[:lang].presence || User.current.language.presence || Setting.default_language
    @language = library.language_for(requested)
  end

  def language_param
    params[:lang].presence
  end
end
