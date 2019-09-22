module DB
  abstract class PoolStatement
    def exec : ExecResult
      log_query
      statement_with_retry &.exec
    end

    def exec(*args_, args : Array? = nil) : ExecResult
      log_query(*args_, args: args)
      statement_with_retry &.exec(*args_, args: args)
    end

    def query : ResultSet
      log_query
      statement_with_retry &.query
    end

    def query(*args_, args : Array? = nil) : ResultSet
      log_query(*args_, args: args)
      statement_with_retry &.query(*args_, args: args)
    end

    def scalar(*args_, args : Array? = nil)
      log_query(*args_, args: args)
      statement_with_retry &.scalar(*args_, args: args)
    end

    private def log_query(*args_, args : Array? = nil)
      Avram.settings.query_log_level.try do |level|
        logging_args = EnumerableConcat.build(args_, args)
        logging_args = logging_args.to_a if logging_args.is_a?(EnumerableConcat)
        Avram.logger.log(level, {query: @query, args: logging_args})
      end
    end
  end
end
