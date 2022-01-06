module DB
  abstract class Connection
    getter stack = [] of DB::Transaction
  end
end
