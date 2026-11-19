# frozen_string_literal: true

require_relative '../test_helper'

module RedmineKit
  module Help
    # The new UI's screens as Redmine's: a name of the route table and its tab, nothing for any other shape.
    class KitScreensTest < ActiveSupport::TestCase
      test "a screen is Redmine's controller and action, with its tab" do
        assert_equal ['projects', 'settings', { 'tab' => 'members' }], KitScreens.screen('ProjectSettings', 'members')
        assert_equal ['issues', 'index', {}], KitScreens.screen('ProjectTable')
        assert_equal ['timelog', '', {}], KitScreens.screen('TimeSheet')
      end

      test 'unknown names, plugin screens and other shapes are none; an odd tab is left out' do
        [nil, '', 'NoSuchScreen', 'redmine_kit_agile:AgileBacklog', '../Main', ['Main'], 'Main' * 20].each do |name|
          assert_nil KitScreens.screen(name), name.inspect
        end
        assert_equal({}, KitScreens.screen('AdminSettings', '../x').last)
        assert_equal({}, KitScreens.screen('AdminSettings', %w[a]).last)
      end

      test 'every screen names a controller' do
        KitScreens.map.each_value { |value| assert_match(/\A[a-z_]+(#[a-z_]+)?\z/, value) }
      end
    end
  end
end
