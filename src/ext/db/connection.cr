module DB
  abstract class Connection
    # :nodoc:
    getter _avram_stack = [] of DB::Transaction

    # :nodoc:
    def _avram_in_transaction? : Bool
      !_avram_stack.empty?
    end
  end
end
