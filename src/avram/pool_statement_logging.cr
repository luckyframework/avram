module DB
  abstract class PoolStatement
    def exec : ExecResult
      log_query
      statement_with_retry &.exec
    rescue e : PQ::PQError
      log_error
      raise e
    end

    def exec(*args_, args : Array? = nil) : ExecResult
      log_query(*args_, args: args)
      statement_with_retry &.exec(*args_, args: args)
    rescue e : PQ::PQError
      log_error(*args_, args: args)
      raise e
    end

    def query : ResultSet
      log_query
      statement_with_retry &.query
    rescue e : PQ::PQError
      log_error
      raise e
    end

    def query(*args_, args : Array? = nil) : ResultSet
      log_query(*args_, args: args)
      statement_with_retry &.query(*args_, args: args)
    rescue e : PQ::PQError
      log_error(*args_, args: args)
      raise e
    end

    def scalar(*args_, args : Array? = nil)
      log_query(*args_, args: args)
      statement_with_retry &.scalar(*args_, args: args)
    rescue e : PQ::PQError
      log_error(*args_, args: args)
      raise e
    end

    private def log_query(*args_, args : Array? = nil) : Nil
      Avram::QueryLog.dexter.info do
        log_data(*args_, args: args || [] of String)
      end
    end

    private def log_error(*args_, args : Array? = nil) : Nil
      Avram::FailedQueryLog.dexter.info do
        log_data(*args_, args: args || [] of String)
      end
    end

    private def log_data(*args_, args : Array)
      logging_args = EnumerableConcat.build(args_, args)
      logging_args = if logging_args.is_a?(Tuple) || logging_args.nil?
                       [] of String
                     elsif logging_args.is_a?(String)
                       [logging_args]
                     else
                       logging_args.to_a
                     end

      {query: @query, args: logging_args}
    end
  end
end
