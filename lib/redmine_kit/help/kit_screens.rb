# frozen_string_literal: true

module RedmineKit
  module Help
    # The new UI's screens as Redmine's (config/kit_screens.yml): a screen's
    # name in Redmine Kit UI's route table and its ?tab=, as the controller,
    # action and parameters the sources' map.yml is keyed by. Read once; the
    # file is the plugin's own.
    #
    # A plugin's screen (`<plugin>:<component>`, Redmine Kit UI's
    # ExtensionScreen) is the Redmine route of its path in the plugin's
    # manifest (a plugin's screen keeps its Redmine route and HTML action,
    # redmine_kit_ui's docs/plugins-kit.md "Screens"), so the plugin's
    # map.yml, keyed by its controllers, maps both UIs. A component of several
    # screens is its first screen's.
    module KitScreens
      FILE = File.expand_path('../../../config/kit_screens.yml', __dir__)
      NAME = /\A[A-Za-z][A-Za-z0-9]{0,63}\z/
      PLUGIN_SCREEN = /\A([a-z][a-z0-9_]{0,59}):([A-Z][A-Za-z0-9]{0,63})\z/
      TAB = /\A[a-z0-9_]{1,32}\z/

      module_function

      def map
        @map ||= YAML.safe_load_file(FILE, aliases: false).freeze
      end

      # [controller, action, params] of a screen, or nil for a screen of
      # another shape, or one that is neither Redmine's nor a plugin's.
      def screen(name, tab = nil)
        return unless name.is_a?(String)

        controller, action = (PLUGIN_SCREEN.match(name) ? plugin_route(name) : core_route(name))&.split('#', 2)
        return unless controller

        params = tab.is_a?(String) && tab.match?(TAB) ? { 'tab' => tab } : {}
        [controller, action.to_s, params]
      end

      def core_route(name)
        map[name] if name.match?(NAME)
      end

      # "controller#action" of a plugin's screen: the Redmine route that its
      # path (its params filled in) is recognized as, or nil.
      def plugin_route(name)
        plugin, component = name.split(':', 2)
        path = plugin_screen_paths(plugin, component).first
        return unless path

        sample = path.gsub(/:[a-z_]+/, '1').gsub(/\*[a-z_]+/, 'x')
        route = Rails.application.routes.recognize_path(sample, method: :get)
        "#{route[:controller]}##{route[:action]}" if route[:controller]
      rescue ActionController::RoutingError
        nil
      end

      # The paths of the plugin's screens of the component, in the order of
      # its manifest (Redmine Kit UI's, when it is installed).
      def plugin_screen_paths(plugin, component)
        return [] unless Redmine::Plugin.installed?(:redmine_kit_ui) && Redmine::Plugin.installed?(plugin)

        manifest = RedmineKit::Ui::UiExtensionManifest.for(Redmine::Plugin.find(plugin))
        Array(manifest&.screens).filter_map { |screen| screen[:path] if screen[:component] == component }
      end
    end
  end
end
