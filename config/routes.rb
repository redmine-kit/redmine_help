# frozen_string_literal: true

get 'help', to: 'help_topics#index', as: 'help_index'
get 'help/search', to: 'help_topics#search', as: 'help_search'
get 'help/context', to: 'help_topics#context', as: 'help_context'
get 'help/assets/*path', to: 'help_topics#asset', as: 'help_asset', format: false
# a topic's JSON (the new UI): /help/user/issues.json
get 'help/*topic', to: 'help_topics#show', as: 'help_topic_json', format: true, constraints: { format: 'json' }
get 'help/*topic', to: 'help_topics#show', as: 'help_topic', format: false
