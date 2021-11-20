# https://crystal-lang.org/api/latest/Fiber.html
class Fiber
  # This is stored on Fiber so it's released after each
  # HTTP Request.
  property query_cache : LuckyCache::BaseStore do
    if Avram.settings.query_cache_enabled
      LuckyCache::MemoryStore.new
    else
      LuckyCache::NullStore.new
    end
  end
end
