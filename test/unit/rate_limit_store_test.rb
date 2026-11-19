# frozen_string_literal: true

require_relative '../test_helper'

# Where the search's rate limit counts (RedmineKit::Help::RateLimitStore): Rails.cache, which a Redmine server's
# processes share, so that the limit isn't multiplied by its Puma workers or Lambda instances; this process's bounded
# store only where Rails.cache counts nothing (a NullStore, as in Redmine's test environment); a store set explicitly.
class RateLimitStoreTest < ActiveSupport::TestCase
  STORE = RedmineKit::Help::RateLimitStore

  def teardown
    STORE.store = nil
  end

  test "a server's path: Rails.cache, where the counts go" do
    STORE.store = nil
    shared = ActiveSupport::Cache::MemoryStore.new
    Rails.stubs(:cache).returns(shared)
    assert_same shared, STORE.store
    assert_equal 1, STORE.increment('rate-limit:help:x', 1, expires_in: 1.minute)
    assert_equal 2, STORE.increment('rate-limit:help:x', 1, expires_in: 1.minute)
    assert_equal 2, shared.read('rate-limit:help:x', raw: true).to_i
  end

  test "a NullStore as Rails.cache (Redmine's tests): this process's bounded store" do
    STORE.store = nil
    Rails.stubs(:cache).returns(ActiveSupport::Cache::NullStore.new)
    assert_same STORE::FALLBACK, STORE.store
  end

  test 'a store set explicitly, and nil back to the default' do
    given = ActiveSupport::Cache::MemoryStore.new
    STORE.store = given
    assert_same given, STORE.store
    STORE.store = nil
    Rails.stubs(:cache).returns(shared = ActiveSupport::Cache::MemoryStore.new)
    assert_same shared, STORE.store
  end
end
