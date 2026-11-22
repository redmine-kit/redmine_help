# frozen_string_literal: true

# Redmine Kit Help as a gem (docs/setup.md, "Installation"): Bundler requires
# this file when Redmine's Gemfile.local has `gem 'redmine_kit_help'`.
#
# Redmine 7.0.3 loads plugins from its plugins/ folder only
# (Redmine::PluginLoader). This hands the gem's folder to the same loader, after
# Redmine's initializers have listed plugins/: Redmine then runs init.rb (which
# registers the plugin with this folder, `directory`) and serves its assets,
# locales and views as for any plugin; the folder's lib/ and app/
# go to Rails' code loader (Zeitwerk) as Redmine adds a plugin's
# (PluginLoader.add_autoload_paths); its routes come after Redmine's, as
# Redmine draws a plugin's; its rake tasks (lib/tasks: the help's check) load
# as Redmine loads plugins/*/lib/tasks. A plugin of the same id in plugins/ (a
# checkout or a link) wins, and nothing is done.
#
# No constant is defined here: RedmineKit::Help comes from lib/ through the
# code loader, as in plugins/, so that it reloads and Zeitwerk checks it.
require 'active_support/lazy_load_hooks'

ActiveSupport.on_load(:before_configuration, yield: true) do |app|
  dir = File.expand_path('..', __dir__)
  app.initializer 'redmine_kit_help.gem', after: :load_config_initializers do |application|
    loader = Redmine::PluginLoader
    next if loader.directories.any? { |path| File.basename(path.to_s) == 'redmine_kit_help' }

    loader.directories << Redmine::PluginPath.new(dir)
    Rails::Engine::Configuration.new(dir).tap { |config| config.paths.add 'lib', eager_load: true }
                                .all_eager_load_paths.each do |path|
      Rails.autoloaders.main.push_dir(path)
      application.config.watchable_dirs[path] = [:rb]
    end
    routes = File.join(dir, 'config/routes.rb')
    application.routes.append { instance_eval(File.read(routes), routes) } if File.file?(routes)
  end
  # Rake loads the tasks before the initializers run: plugins/ is looked at as
  # Redmine's PluginLoader looks at it.
  app.rake_tasks do
    plugins = File.join(Rails.root.to_s, Rails.application.config.redmine_plugins_directory.to_s, 'redmine_kit_help')
    Dir[File.join(dir, 'lib/tasks/**/*.rake')].each { |task| load task } unless File.directory?(plugins)
  end
end
