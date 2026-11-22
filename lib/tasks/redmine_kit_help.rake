# frozen_string_literal: true

namespace :redmine_kit do
  namespace :help do
    desc "Check the plugins' help/ against the installed guide (PLUGIN=<id> for one; DIR=<help/> with PLUGIN " \
         'for a help/ not installed): maps, sections, translations and the sections they insert into the guide'
    task check: :environment do
      plugin = ENV['PLUGIN'].presence
      dir = ENV['DIR'].presence
      abort 'redmine_kit_help: DIR needs PLUGIN, the id to check it as' if dir && !plugin
      abort "redmine_kit_help: no directory #{dir}" if dir && !File.directory?(dir)

      library = dir ? RedmineKit::Help::Check.library_with(plugin, dir) : RedmineKit::Help.library
      check = RedmineKit::Help::Check.new(library)
      abort "redmine_kit_help: no help/ in the installed plugin #{plugin}" if plugin && check.plugins.exclude?(plugin)
      warn 'redmine_kit_help: the guide is not installed; topics of the guide count as missing' unless library.guide?

      problems = check.problems(plugin)
      problems.each { |problem| puts problem }
      checked = plugin ? [plugin] : check.plugins
      puts "redmine_kit_help: #{checked.join(', ').presence || 'no plugin has help/'}: #{problems.size} problem(s)"
      exit 1 if problems.any?
    end
  end
end
