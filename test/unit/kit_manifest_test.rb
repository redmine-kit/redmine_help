# frozen_string_literal: true

require_relative '../test_helper'

# config/kit_ui.yml, what the plugin adds to Redmine Kit UI's new UI
# (docs/README.md "The new UI"; redmine_kit_ui's docs/plugins-kit.md): read as
# redmine_kit_ui reads it (YAML.safe_load, no aliases), the screens of the help
# pages and of Redmine's help pages, and the panel that is the TopBar's Help,
# each component exported by the built module.
class KitManifestTest < ActiveSupport::TestCase
  ROOT = File.expand_path('../..', __dir__)
  KEYS = %w[api_version module stylesheet menus screens slots settings new_issue blocks].freeze

  def manifest
    @manifest ||= YAML.safe_load_file(File.join(ROOT, 'config/kit_ui.yml'), aliases: false)
  end

  test 'version 1 with known keys only, the module and its stylesheet among the assets' do
    assert_equal 1, manifest['api_version']
    assert_empty manifest.keys - KEYS
    assert File.file?(File.join(ROOT, 'assets/javascripts', manifest['module']))
    assert File.file?(File.join(ROOT, 'assets/stylesheets', manifest['stylesheet']))
  end

  test 'the help pages and Redmine help pages as screens, without a permission' do
    screens = manifest['screens'].to_h { |screen| [screen['path'], screen['component']] }
    assert_equal({ '/help' => 'HelpPage', '/help/search' => 'HelpPage', '/help/*topic' => 'HelpPage',
                   '/help/wiki_syntax/:type' => 'HelpWikiSyntax', '/help/wiki_syntax' => 'HelpWikiSyntax',
                   '/help/code_highlighting' => 'HelpCodeHighlighting' }, screens)
    assert(manifest['screens'].none? { |screen| screen.key?('permission') })
  end

  test "the panel replaces the TopBar's Help, stays open in the tab and is anonymous visitors' too" do
    panel = manifest['slots'].sole
    assert_equal({ 'slot' => 'topbar.panel', 'component' => 'HelpPanel', 'title' => 'label_help', 'icon' => 'help',
                   'replaces' => 'help', 'persist' => true, 'anonymous' => true }, panel)
    # Redmine's own Help is replaced on the server too, as redmine_kit_ui requires for `replaces: help`
    item = Redmine::MenuManager.items(:top_menu).detect { |menu_item| menu_item.name == :help }
    assert_not_equal Redmine::Info.help_url, item.url
  end

  test 'every component the manifest names is exported by the built module' do
    built = File.read(File.join(ROOT, 'assets/javascripts', manifest['module']))
    exported = built.scan(/^export\s*\{([^}]*)\}/m).flatten.join(',').split(',')
                    .map { |name| name.strip.split(/\s+as\s+/).last }
    names = (manifest['screens'] + manifest['slots']).map { |part| part['component'] }.uniq
    assert_empty names - exported
  end
end
