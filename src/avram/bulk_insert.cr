module Avram::BulkInsert(T)
  macro included
    define_import

    macro inherited
      define_import
    end
  end

  macro define_import
    def self.import(operations : Array(self))
      operations.each(&.before_save)

      if operations.all?(&.valid?)
        now = Time.utc

        insert_values = operations.map do |operation|
          operation.created_at.value ||= now if operation.responds_to?(:created_at)
          operation.updated_at.value ||= now if operation.responds_to?(:updated_at)
          operation.values
        end

        insert_sql = Avram::Insert.new(T.table_name, insert_values, T.column_names)

        transaction_committed = T.database.transaction do
          T.database.query insert_sql.statement, args: insert_sql.args do |rs|
            T.from_rs(rs).each_with_index do |record, index|
              operation = operations[index]
              operation.record = record
              operation.after_save(record)
            end
          end

          true
        end

        if transaction_committed
          operations.each do |operation|
            operation.save_status = OperationStatus::Saved
            operation.after_commit(operation.record.as(T))

            Avram::Events::SaveSuccessEvent.publish(
              operation_class: self.class.name,
              attributes: operation.generic_attributes
            )
          end

          true
        else
          operations.each do |operation|
            operation.mark_as_failed

            Avram::Events::SaveFailedEvent.publish(
              operation_class: self.class.name,
              attributes: operation.generic_attributes
            )
          end

          false
        end
      else
        operations.each do |operation|
          operation.mark_as_failed

          Avram::Events::SaveFailedEvent.publish(
            operation_class: self.class.name,
            attributes: operation.generic_attributes
          )
        end

        false
      end
    end
  end
end