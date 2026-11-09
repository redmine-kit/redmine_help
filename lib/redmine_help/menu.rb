# frozen_string_literal: true

module RedmineHelp
  # Points the header's Help link at the help for the current screen.
  module Menu
    module_function

    def install
      Redmine::MenuManager.map :top_menu do |menu|
        menu.delete :help
        # A Symbol is called as a helper in the view (Redmine::MenuManager),
        # so the link knows the current screen.
        menu.push :help, :redmine_help_link_url, html: { target: '_blank', rel: 'noopener' }, last: true
      end
      ApplicationHelper.include(Helper) unless ApplicationHelper.include?(Helper)
    end

    # Included into ApplicationHelper.
    module Helper
      def redmine_help_link_url
        # Some of Redmine's own tests draw the routes without the plugins'
        # routes; the link is then Redmine's own.
        return Redmine::Info.help_url unless respond_to?(:help_context_path)

        screen = { c: controller_name, a: action_name }
        RedmineHelp::MAP_PARAMS.each { |name| screen[name.to_sym] = params[name] if params[name].is_a?(String) }
        help_context_path(screen)
      end
    end
  end
end
