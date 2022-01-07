module DB
  abstract class Transaction
    # :nodoc:
    property? _avram_joinable = true
  end

  class TopLevelTransaction < Transaction
    def initialize(@connection : Connection)
      @nested_transaction = false
      @connection.perform_begin_transaction
      @connection._avram_stack.push(self)
    end

    protected def do_close
      @connection.release_from_transaction
      @connection._avram_stack.pop
    end
  end

  class SavePointTransaction < Transaction
    def initialize(@parent : Transaction, @savepoint_name : String)
      @nested_transaction = false
      @connection = @parent.connection
      @connection.perform_create_savepoint(@savepoint_name)
      @connection._avram_stack.push(self)
    end

    protected def do_close
      @parent.release_from_nested_transaction
      @connection._avram_stack.pop
    end
  end
end
