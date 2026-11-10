# frozen_string_literal: true

# The plugin as a gem, published to GitHub Packages (.github/workflows/gem.yml).
# The gem holds the plugin's run-time files, so that the installed gem can be
# linked into Redmine's plugins/ (docs/setup.md#installation). The guide's
# content is a separate gem, redmine-guide (docs/setup.md#the-guide).
Gem::Specification.new do |spec|
  spec.name = 'redmine_help'
  spec.version = File.read(File.join(__dir__, 'lib/redmine_help.rb'))[/VERSION = '([^']+)'/, 1]
  spec.summary = "Opens help for the current Redmine screen in the user's language"
  spec.authors = ['Redmine Kit']
  spec.license = 'GPL-2.0-or-later'
  spec.homepage = 'https://github.com/redmine-kit/redmine_help'
  spec.required_ruby_version = '>= 4.0'
  spec.files = Dir['{init.rb,LICENSE}', '{app,assets,config,lib}/**/*']
  spec.require_paths = []
  spec.metadata['github_repo'] = 'ssh://github.com/redmine-kit/redmine_help'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
