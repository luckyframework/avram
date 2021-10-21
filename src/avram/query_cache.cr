module Avram
  # This module is included in the inherited Database.
  # Each inheritence will have access to its own cache
  module QueryCache
    macro included
      # The benefit of using SplayTreeMap is that it's threadsafe
      # unlike Hash. This gives us extra performance in a multithreaded
      # environment.
      CACHE_VAULT = SplayTreeMap(String, Avram::ResultSet).new
      CACHE_COUNTER = SplayTreeMap(String, Int64).new(0i64)

      # Used similar to Hash, the keys are generally
      # going to be some SQL statement combined with
      # the args passed to that SQL to build a unique string.
      #
      # The values are the ResultSet returned from Postgres.
      # You can use this value to pass in to your model
      # ```
      # rs = AppDatabase.cache_vault["SELECT ..."]
      # User.from_rs(rs)
      # ```
      def self.cache_vault : SplayTreeMap
        CACHE_VAULT
      end

      # Used similar to Hash, the keys will be "hit",
      # or "miss". This keeps track of how many times
      # your Database has hit the cache, or missed.
      #
      # Running the same query 5 times would be 1 miss (no cache)
      # and then 4 hits (the cache)
      # ```
      # AppDatabase.cache_counter["miss"] # => 1
      # AppDatabase.cache_counter["hit"] # => 4
      # ```
      def self.cache_counter
        CACHE_COUNTER
      end

      # Completely reset both the `cache_vault` and
      # the `cache_counter`.
      def self.reset_cache!
        cache_vault.clear
        cache_counter.clear
      end

      # Creates a String based on the keys passed in
      def build_cache_key(*keys) : String
        String.build do |io|
          keys.each do |key|
            io << key.to_s.strip
          end
        end
      end

      # Checks the cache to see if the key already exists
      # If it does, it'll increment the cache hit counter,
      # and return the result.
      # If the key does not exist, increment the miss counter,
      # and return the yield from the block
      def with_cache(key : String) : Avram::ResultSet
        if CACHE_VAULT.has_key?(key)
          CACHE_COUNTER["hit"] += 1
          CACHE_VAULT[key]
        else
          CACHE_COUNTER["miss"] += 1
          CACHE_VAULT[key] = yield
        end
      end
    end
  end
end
