module Avram::Test
  TRUNCATE = "truncate"

  def self.wrap_spec_in_transaction(spec : Spec::Example::Procsy, database : Avram::Database.class)
    if use_truncation?(spec)
      spec.run
      database.truncate
      return
    end

    tracked_transactions = [] of DB::Transaction

    database.connections.values.each do |conn|
      tracked_transactions << conn.begin_transaction.tap(&.joinable=(false))
    end

    database.setup_connection do |conn|
      tracked_transactions << conn.begin_transaction.tap(&.joinable=(false))
    end

    spec.run

    tracked_transactions.each do |transaction|
      next if transaction.closed? || transaction.connection.closed?

      transaction.rollback
      transaction.connection.release
    end
    tracked_transactions.clear
    database.connections.clear
    database.setup_connection { }
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
