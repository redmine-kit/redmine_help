# frozen_string_literal: true

get 'help', to: 'redmine_help#index', as: 'help_index'
get 'help/search', to: 'redmine_help#search', as: 'help_search'
get 'help/context', to: 'redmine_help#context', as: 'help_context'
get 'help/assets/*path', to: 'redmine_help#asset', as: 'help_asset', format: false
get 'help/*topic', to: 'redmine_help#show', as: 'help_topic', format: false
