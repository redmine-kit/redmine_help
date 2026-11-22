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

      test "unknown names, an uninstalled plugin's screens and other shapes are none; an odd tab is left out" do
        [nil, '', 'NoSuchScreen', 'redmine_kit_agile:AgileBacklog', '../Main', ['Main'], 'Main' * 20].each do |name|
          assert_nil KitScreens.screen(name), name.inspect
        end
        assert_equal({}, KitScreens.screen('AdminSettings', '../x').last)
        assert_equal({}, KitScreens.screen('AdminSettings', %w[a]).last)
      end

      test "a plugin's screen is the Redmine route of its path in the plugin's manifest" do
        KitScreens.stubs(:plugin_screen_paths).with('redmine_kit_sample', 'SampleScreen')
                  .returns(['/issues/:id/edit', '/projects/:project_id/issues'])
        KitScreens.stubs(:plugin_screen_paths).with('redmine_kit_sample', 'GlobScreen').returns(['/help/*topic'])
        KitScreens.stubs(:plugin_screen_paths).with('redmine_kit_sample', 'NoScreen').returns([])
        # the first screen of the component
        assert_equal ['issues', 'edit', { 'tab' => 'notes' }],
                     KitScreens.screen('redmine_kit_sample:SampleScreen', 'notes')
        assert_equal ['help_topics', 'show', {}], KitScreens.screen('redmine_kit_sample:GlobScreen')
        assert_nil KitScreens.screen('redmine_kit_sample:NoScreen')
        assert_nil KitScreens.screen('Redmine_kit:SampleScreen')
        assert_nil KitScreens.screen('redmine_kit_sample:sample')
      end

      test "a plugin's settings is settings#plugin with the plugin as id; another shape of id is left out" do
        assert_equal ['settings', 'plugin', { 'id' => 'redmine_kit_checklist' }],
                     KitScreens.screen('PluginSettings', nil, 'redmine_kit_checklist')
        assert_equal ['settings', 'plugin', {}], KitScreens.screen('PluginSettings', nil, '../x')
        assert_equal ['settings', 'plugin', {}], KitScreens.screen('PluginSettings', nil, %w[a])
      end

      test "a plugin's screen whose path is no route of Redmine's is none" do
        KitScreens.stubs(:plugin_screen_paths).returns(['/no/such/route/here'])
        assert_nil KitScreens.screen('redmine_kit_sample:SampleScreen')
      end

      test 'every screen names a controller' do
        KitScreens.map.each_value { |value| assert_match(/\A[a-z_]+(#[a-z_]+)?\z/, value) }
      end
    end
  end
end
