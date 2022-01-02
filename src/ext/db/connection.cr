module DB
  abstract class Connection
    getter stack = [] of DB::Transaction

    def begin_transaction : Transaction
      return stack.last.begin_transaction if @transaction
      @transaction = true
      create_transaction
    end
  end
end
