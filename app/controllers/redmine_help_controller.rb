# frozen_string_literal: true

# The help pages (docs/README.md). Open to whoever can see Redmine: logged-in
# users, and anonymous users when Redmine does not require login.
class RedmineHelpController < ApplicationController
  before_action :set_help_language
  helper :redmine_help

  # The topic for the screen the Help link was clicked on.
  def context
    found = library.resolve(params[:c].to_s, params[:a].to_s, params.permit(*RedmineHelp::MAP_PARAMS).to_h)
    if found && library.topic(found.first, @language)
      redirect_to help_topic_path(found.first, lang: language_param, anchor: found.second.presence)
    else
      redirect_to help_index_path(lang: language_param)
    end
  end

  def index
    @sections = library.sections(@language)
  end

  def show
    @topic = library.topic(params[:topic].to_s, @language)
    return render_404 unless @topic

    @support = library.support(@topic.id, @language)
    @section = library.sections(@language).find { |section| section.topics.any? { |t| t.id == @topic.id } }
  end

  def search
    @query = params[:q].to_s.strip.first(100)
    @results = library.search(@query, @language)
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

  # ?lang=xx, else the user's language, else Redmine's default.
  def set_help_language
    requested = params[:lang].presence || User.current.language.presence || Setting.default_language
    @language = library.language_for(requested)
  end

  def language_param
    params[:lang].presence
  end
end
