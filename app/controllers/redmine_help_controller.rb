# frozen_string_literal: true

# The help pages (docs/README.md). Open to whoever can see Redmine: logged-in
# users, and anonymous users when Redmine does not require login.
#
# With panel=1, context, show and search render the same content without
# Redmine's layout, for the side panel that the header's Help link opens
# (assets/javascripts/help_panel.js).
class RedmineHelpController < ApplicationController
  before_action :set_help_language
  helper :redmine_help
  helper_method :panel?

  # The topic for the screen the Help link was clicked on.
  def context
    key, (id, anchor) = library.lookup(params[:c].to_s, params[:a].to_s, params.permit(*RedmineHelp::MAP_PARAMS).to_h)
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
    render_index
  end

  def show
    @topic = library.topic(params[:topic].to_s, @language)
    return render_404 unless @topic

    render_topic
  end

  def search
    @query = params[:q].to_s.strip.first(100)
    @results = library.search(@query, @language)
    render_panel if panel?
  end

  def asset
    file = library.asset(params[:path].to_s)
    return render_404 unless file

    send_file file, disposition: 'inline'
  end

  private

  def library
    RedmineHelp.library
  end

  def render_index
    @sections = library.sections(@language)
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

  # ?lang=xx, else the user's language, else Redmine's default.
  def set_help_language
    requested = params[:lang].presence || User.current.language.presence || Setting.default_language
    @language = library.language_for(requested)
  end

  def language_param
    params[:lang].presence
  end
end
