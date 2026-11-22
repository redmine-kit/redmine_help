# frozen_string_literal: true

# Renders the help's Markdown like a wiki page: Redmine's CommonMark
# formatter, then Redmine's own heading anchors and table of contents
# (ApplicationHelper#parse_headings and #replace_toc), then links between
# topics and to the topics' images, and the plugins' labels on the sections
# they insert.
module HelpTopicsHelper
  # panel: for the side panel, whose header shows the title: the page's
  # # heading is left out, and the table of contents is not floated
  # ({{toc}} instead of {{>toc}}), since the panel is narrow. insertions: the
  # plugins' sections in the text (Topic#insertions), labelled by their
  # heading.
  def help_to_html(markdown, topic_id, toc: true, panel: false, insertions: [])
    html = Redmine::WikiFormatting.to_html('common_mark', markdown.to_s).dup
    @parsed_headings = []
    @heading_anchors = {}
    parse_headings(html, nil, nil, nil, true, {})
    if toc
      html.prepend(panel ? '<p>{{toc}}</p>' : '<p>{{>toc}}</p>')
      replace_toc(html, @parsed_headings.reject { |level, _, _| level == 1 })
    end
    help_rewrite_links(html, topic_id, title: !panel, insertions: insertions).html_safe
  end

  # Relative links to .md files become links to topics; relative images
  # become links to the topic's directory under /help/assets. title: false
  # leaves out the first # heading.
  def help_rewrite_links(html, topic_id, title: true, insertions: [])
    dir = File.dirname(topic_id)
    doc = Nokogiri::HTML::DocumentFragment.parse(html)
    doc.at_css('h1')&.remove unless title
    insertions.each { |insertion| help_label_insertion(doc, insertion) }
    doc.css('a[href]').each { |link| help_rewrite_link(link, dir) }
    doc.css('img[src]').each { |image| help_rewrite_image(image, dir) }
    doc.to_html
  end

  # The label of a plugin's section (Insertions: its name, and the section's
  # language when it isn't the topic's) after the section's heading, before
  # Redmine's ¶; the table of contents keeps the heading's own text.
  def help_label_insertion(doc, insertion)
    # Redmine's ¶ links to the anchor as written; an HTML parser may have escaped it
    anchor = doc.css('a.wiki-anchor').find { |link| CGI.unescape(link['href'].to_s) == "##{insertion[:anchor]}" }
    return unless anchor

    anchor.add_previous_sibling(" #{content_tag('span', insertion[:label], class: 'badge help-insertion-label')}")
  end

  def help_rewrite_link(link, dir)
    path, anchor = link['href'].split('#', 2)
    return if link['href'].match?(%r{\A([a-z]+:|//|#|/)}i) || !path.end_with?('.md')

    topic = help_join(dir, path.delete_suffix('.md'))
    anchor = RedmineKit::Help.library.anchor(topic, @language, anchor)
    link['href'] = help_topic_path(topic, lang: params[:lang].presence, anchor: anchor.presence)
  end

  # The image and its srcset (Redmine adds "<name>@2x.png 2x" for images
  # named @2x).
  def help_rewrite_image(image, dir)
    image['src'] = help_image_url(image['src'], dir)
    return unless image['srcset']

    image['srcset'] = image['srcset'].split(',').map do |candidate|
      url, size = candidate.strip.split(/\s+/, 2)
      [help_image_url(url, dir), size].compact.join(' ')
    end.join(', ')
  end

  def help_image_url(url, dir)
    return url if url.match?(%r{\A([a-z]+:|//|/)}i)

    help_asset_path(help_join(@topic&.language || @language, dir, url))
  end

  def help_join(*parts)
    Pathname(File.join(*parts.reject { |part| part == '.' })).cleanpath.to_s.sub(%r{\A(\.\./)+}, '')
  end

  def help_title(topic)
    topic.title
  end

  # Links to the help in the other languages there is help in.
  def help_language_links
    RedmineKit::Help.library.languages.map do |code|
      name = ::I18n.t(:general_lang_name, locale: code, default: code)
      if code == @language
        content_tag('strong', name)
      else
        link_to(name, url_for(params.permit(:topic, :q).merge(lang: code)))
      end
    end
  end
end
