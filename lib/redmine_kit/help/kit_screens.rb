# frozen_string_literal: true

module RedmineKit
  module Help
    # The new UI's screens as Redmine's (config/kit_screens.yml): a screen's
    # name in Redmine Kit UI's route table and its ?tab=, as the controller,
    # action and parameters the sources' map.yml is keyed by. Read once; the
    # file is the plugin's own.
    module KitScreens
      FILE = File.expand_path('../../../config/kit_screens.yml', __dir__)
      NAME = /\A[A-Za-z][A-Za-z0-9]{0,63}\z/
      TAB = /\A[a-z0-9_]{1,32}\z/

      module_function

      def map
        @map ||= YAML.safe_load_file(FILE, aliases: false).freeze
      end

      # [controller, action, params] of a screen, or nil for a screen that
      # isn't Redmine's (a plugin's) or a name of another shape.
      def screen(name, tab = nil)
        return unless name.is_a?(String) && name.match?(NAME)

        value = map[name]
        return unless value

        controller, action = value.split('#', 2)
        params = tab.is_a?(String) && tab.match?(TAB) ? { 'tab' => tab } : {}
        [controller, action.to_s, params]
      end
    end
  end
end
