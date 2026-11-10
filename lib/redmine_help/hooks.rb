# frozen_string_literal: true

module RedmineHelp
  # Loads the side panel (assets/javascripts/help_panel.js and its
  # stylesheet) on Redmine's pages. The help pages themselves keep the Help
  # link as a plain link.
  class Hooks < Redmine::Hook::ViewListener
    def view_layouts_base_html_head(context = {})
      return '' if context[:controller].is_a?(RedmineHelpController)

      safe_join([
                  stylesheet_link_tag('help_panel', plugin: 'redmine_help'),
                  javascript_include_tag('help_panel', plugin: 'redmine_help', defer: true)
                ], "\n")
    end
  end
end
