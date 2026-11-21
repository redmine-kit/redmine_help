# frozen_string_literal: true

# The plugin as a gem, published to GitHub Packages (.github/workflows/gem.yml):
# Bundler requires boot/redmine_kit_help.rb, which hands the gem's folder to
# Redmine's plugin loader (docs/setup.md#installation). The gem holds the
# plugin's run-time files; the module's source (frontend/) is not one: its
# build is in assets/. The guide's content is a separate gem, redmine-guide
# (docs/setup.md#the-guide).
Gem::Specification.new do |spec|
  spec.name = 'redmine_kit_help'
  spec.version = File.read(File.join(__dir__, 'lib/redmine_kit/help.rb'))[/VERSION = '([^']+)'/, 1]
  spec.summary = 'Help for the current screen'
  spec.authors = ['Redmine Kit']
  spec.license = 'GPL-2.0-or-later'
  spec.homepage = 'https://github.com/redmine-kit/redmine_help'
  # The Ruby versions of Redmine 7.0 (its Gemfile: ruby '>= 3.2.0', '< 4.1.0').
  spec.required_ruby_version = ['>= 3.2', '< 4.1']
  spec.files = Dir['{init.rb,LICENSE}', '{app,assets,boot,config,lib}/**/*']
  # boot/ only: lib/ is the code loader's (Zeitwerk), never required by name.
  spec.require_paths = ['boot']
  spec.metadata['github_repo'] = 'ssh://github.com/redmine-kit/redmine_help'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
