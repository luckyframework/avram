module Avram::SpecHelper
  TRUNCATE            = "truncate"
  NO_CASCADE          = "no_cascade"
  NO_RESTART_IDENTITY = "no_restart_identity"

  macro use_transactional_specs(*databases)
    Spec.around_each do |spec|
      Avram::SpecHelper.wrap_spec_in_transaction(spec, {{ databases.splat }})
    end
  end

  def self.wrap_spec_in_transaction(spec : Spec::Example::Procsy, *databases)
    if named_args = use_truncation?(spec)
      spec.run
      return databases.each(&.truncate **named_args)
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

  # TODO: <https://github.com/luckyframework/avram/pull/984#issuecomment-1821577487>
  # See <https://github.com/luckyframework/avram/pull/984#issuecomment-1826000231>
  private def self.use_truncation?(spec : Spec::Example::Procsy)
    current = spec.example

    while !current.is_a?(Spec::RootContext)
      temp = current.as(Spec::Item)

      temp.tags.try do |tags|
        truncate = tags.includes?(TRUNCATE)
        cascade = !tags.includes?(NO_CASCADE)
        restart_id = !tags.includes?(NO_RESTART_IDENTITY)

        return {cascade: cascade, restart_identity: restart_id} if truncate
      end

      current = temp.parent
    end
  end
end
