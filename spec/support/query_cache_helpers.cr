module QueryCacheHelpers
  private def without_query_cache
    TestDatabase.temp_config(enable_query_cache: false) do
      yield
    end
  end
end
