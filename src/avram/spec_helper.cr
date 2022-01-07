module Avram::SpecHelper
  TRUNCATE = "truncate"

  macro use_transactional_specs(*databases)
    Spec.around_each do |spec|
      Avram::SpecHelper.wrap_spec_in_transaction(spec, {{ databases.splat }})
    end
  end

  def self.wrap_spec_in_transaction(spec : Spec::Example::Procsy, *databases)
    if use_truncation?(spec)
      spec.run
      databases.each(&.truncate)
      return
    end

    tracked_transactions = [] of DB::Transaction

    databases.each do |database|
      database.lock_id = Fiber.current.object_id
      database.connections.values.each do |conn|
        tracked_transactions << conn.begin_transaction.tap(&._avram_joinable=(false))
      end

      database.setup_connection do |conn|
        tracked_transactions << conn.begin_transaction.tap(&._avram_joinable=(false))
      end
    end

    spec.run

    tracked_transactions.each do |transaction|
      next if transaction.closed? || transaction.connection.closed?

      transaction.rollback
      transaction.connection.release
    end
    tracked_transactions.clear
    databases.each do |database|
      database.connections.clear
      database.setup_connection { }
    end
  end

  private def self.use_truncation?(spec : Spec::Example::Procsy) : Bool
    current = spec.example
    while !current.is_a?(Spec::RootContext)
      temp = current.as(Spec::Item)
      return true if temp.tags.try(&.includes?(TRUNCATE))
      current = temp.parent
    end

    false
  end
end
