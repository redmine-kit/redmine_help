# frozen_string_literal: true

namespace :redmine_kit do
  namespace :help do
    desc "Check the plugins' help/ against the installed guide (PLUGIN=<id> for one): " \
         'maps, sections, translations and the sections they insert into the guide'
    task check: :environment do
      plugin = ENV['PLUGIN'].presence
      check = RedmineKit::Help::Check.new
      abort "redmine_kit_help: no help/ in the installed plugin #{plugin}" if plugin && check.plugins.exclude?(plugin)
      warn 'redmine_kit_help: the guide is not installed; topics of the guide count as missing' unless
        RedmineKit::Help.library.guide?

      problems = check.problems(plugin)
      problems.each { |problem| puts problem }
      checked = plugin ? [plugin] : check.plugins
      puts "redmine_kit_help: #{checked.join(', ').presence || 'no plugin has help/'}: #{problems.size} problem(s)"
      exit 1 if problems.any?
    end
  end
end
