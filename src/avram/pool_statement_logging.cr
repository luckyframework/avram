module DB
  abstract class PoolStatement
    def exec : ExecResult
      log_query
      statement_with_retry &.exec
    end

    def exec(*args) : ExecResult
      log_query(args)
      statement_with_retry &.exec(*args)
    end

    def exec(args : Array) : ExecResult
      log_query(args)
      statement_with_retry &.exec(args)
    end

    def query : ResultSet
      log_query
      statement_with_retry &.query
    end

    def query(*args) : ResultSet
      log_query(args)
      statement_with_retry &.query(*args)
    end

    def query(args : Array) : ResultSet
      log_query(args)
      statement_with_retry &.query(args)
    end

    def scalar(*args)
      log_query(args)
      statement_with_retry &.scalar(*args)
    end

    private def log_query(args = [] of String)
      Avram.settings.query_log_level.try do |level|
        Avram.logger.log(level, {query: @query, args: args})
      end
    end
  end
end
