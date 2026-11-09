# frozen_string_literal: true

require_relative '../test_helper'

module RedmineHelp
  class MenuTest < ActiveSupport::TestCase
    # A view without the plugin's routes, as in some of Redmine's own tests.
    class ViewWithoutRoutes
      include RedmineHelp::Menu::Helper
    end

    test "the Help link is Redmine's own when the plugin's routes are not drawn" do
      assert_equal Redmine::Info.help_url, ViewWithoutRoutes.new.redmine_help_link_url
    end

    test "the menu's Help item is the plugin's" do
      item = Redmine::MenuManager.items(:top_menu).find { |node| node.name == :help }
      assert_equal :redmine_help_link_url, item.url
    end
  end
end
