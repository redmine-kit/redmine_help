# frozen_string_literal: true

module RedmineKit
  module Help
    # Points the header's Help link at the help for the current screen.
    module Menu
      module_function

      def install
        Redmine::MenuManager.map :top_menu do |menu|
          menu.delete :help
          # A Symbol is called as a helper in the view (Redmine::MenuManager),
          # so the link knows the current screen.
          menu.push :help, :redmine_kit_help_link_url, html: { target: '_blank', rel: 'noopener' }, last: true
        end
        ApplicationHelper.include(Helper) unless ApplicationHelper.include?(Helper)
      end

      # Included into ApplicationHelper.
      module Helper
        def redmine_kit_help_link_url
          # Some of Redmine's own tests draw the routes without the plugins'
          # routes; the link is then Redmine's own.
          return Redmine::Info.help_url unless respond_to?(:help_context_path)

          # controller_path: a plugin's namespaced controller by its whole path
          # (redmine_kit/holidays/non_working_dates), as the new UI's routes
          # name it (KitScreens), so one key of map.yml serves both UIs
          screen = { c: controller_path, a: action_name }
          RedmineKit::Help::MAP_PARAMS.each { |name| screen[name.to_sym] = params[name] if params[name].is_a?(String) }
          help_context_path(screen)
        end
      end
    end
  end
end
