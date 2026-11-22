# frozen_string_literal: true

require_relative '../test_helper'

module RedmineKit
  module Help
    class MenuTest < ActiveSupport::TestCase
      # A view without the plugin's routes, as in some of Redmine's own tests.
      class ViewWithoutRoutes
        include RedmineKit::Help::Menu::Helper
      end

      test "the Help link is Redmine's own when the plugin's routes are not drawn" do
        assert_equal Redmine::Info.help_url, ViewWithoutRoutes.new.redmine_kit_help_link_url
      end

      # A plugin's namespaced controller.
      class NamespacedView
        include RedmineKit::Help::Menu::Helper

        def controller_path = 'redmine_kit/holidays/non_working_dates'
        def action_name = 'new'
        def params = ActionController::Parameters.new('tab' => 'x')
        def help_context_path(screen) = screen
      end

      test "a namespaced controller is named by its whole path, as the new UI's routes name it" do
        assert_equal({ c: 'redmine_kit/holidays/non_working_dates', a: 'new', tab: 'x' },
                     NamespacedView.new.redmine_kit_help_link_url)
      end

      test "the menu's Help item is the plugin's" do
        item = Redmine::MenuManager.items(:top_menu).find { |node| node.name == :help }
        assert_equal :redmine_kit_help_link_url, item.url
      end
    end
  end
end
