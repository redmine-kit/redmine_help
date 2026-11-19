# frozen_string_literal: true

module RedmineKit
  module Help
    # Where the search's rate limit counts (HelpTopicsController's
    # rate_limit, which only calls `increment` on its store). Rails.cache,
    # which the processes of a Redmine server share when it is a shared
    # cache (Memcached, Redis, the database's): a per-process count would
    # multiply the limit by the number of Puma workers or Lambda instances.
    #
    # `store` is read at each request, so a test or an operator sets another
    # (`RateLimitStore.store = …`); nil goes back to the default.
    module RateLimitStore
      # Redmine's test environment has a NullStore as Rails.cache, which
      # counts nothing (increment answers nil, so no limit at all): then a
      # bounded, thread-safe store of this process.
      FALLBACK = ActiveSupport::Cache::MemoryStore.new(size: 1.megabyte)

      class << self
        attr_writer :store

        def store
          @store || default
        end

        # Rails.cache, unless it is a NullStore.
        def default
          Rails.cache.is_a?(ActiveSupport::Cache::NullStore) ? FALLBACK : Rails.cache
        end

        def increment(...)
          store.increment(...)
        end
      end
    end
  end
end
