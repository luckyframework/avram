module Avram
  # These are the supported database engines.
  # Configure this in your Database class
  # ```
  # AppDatabase.configure do |settings|
  #   settings.engine = Avram::Engine::Cockroachdb
  # end
  #
  # AppDatabase.settings.engine.cockroachdb?
  # ```
  @[Experimental("Currently not used for anything, but standing in as a future placeholder")]
  enum Engine
    Postgresql
    Cockroachdb
  end
end
