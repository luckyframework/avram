# Adds the ability to "create or update" (upsert) to `Avram::SaveOperation`
#
# This is included in SaveOperations by default. See `upsert_lookup_columns` for usage details.
module Avram::Upsert
  # Defines the columns Avram should use when performing an `upsert`
  #
  # An "upsert" is short for "update or insert", or in Avram terminology a
  # "create or update". If the values in an operation conflict with an existing
  # record in the database, Avram updates that record. If there is no
  # conflicting record, then Avram will create new one.
  #
  # In Avram, you must define which columns Avram should look at when
  # determining if a conflicting record exists. This is done using the macro
  # `Avram::Upsert.upsert_lookup_columns`
  #
  # **Note:** In almost _every_ case the `upsert_lookup_columns` should have a **unique index** defined
  # in the database to ensure no conflicting records are created, even from outside Avram.
  #
  # ## Full Example
  #
  # ```
  # class User < BaseModel
  #   table do
  #     column name : String
  #     column email : String # This column has a unique index
  #   end
  # end
  #
  # class SaveUser < User::SaveOperation
  #   # Can be one or more columns. In this case we choose just :email
  #   upsert_lookup_columns :email
  # end
  #
  # # Will create a new row in the database since no row with
  # # `email: "bob@example.com"` exists yet
  # SaveUser.upsert!(name: "Bobby", email: "bob@example.com")
  #
  # # Will update the name on the row we just created since the email is
  # # the same as one in the database
  # SaveUser.upsert!(name: "Bob", email: "bob@example.com")
  # ```
  #
  # ## Difference between `upsert` and `upsert!`
  #
  # There is an `upsert` and `upsert!` that work similarly to `create` and `create!`.
  # `upsert!` will raise an error if the operation is invalid. Whereas `upsert`
  # will yield the operation and the new record if the operation is valid, or
  # the operation and `nil` if it is invalid.
  #
  # ```
  # # Will raise because the name is blank
  # SaveUser.upsert!(name: "", email: "bob@example.com")
  #
  # # Operation is invalid because name is blank
  # SaveUser.upsert(name: "", email: "bob@example.com") do |operation, user|
  #   # `user` is `nil` because the operation is invalid.
  #   # If the `name` was valid `user` would be the newly created user
  # end
  # ````
  macro upsert_lookup_columns(*attribute_names)
    def self.upsert!(*args, **named_args) : T
      operation = new(*args, **named_args)
      existing_record = find_existing_unique_record(operation)

      if existing_record
        operation.record = existing_record
      end

      operation.save!
    end

    def self.upsert(*args, **named_args)
      operation = new(*args, **named_args)
      existing_record = find_existing_unique_record(operation)

      if existing_record
        operation.record = existing_record
      end

      operation.save
      yield operation, operation.record
    end

    def self.find_existing_unique_record(operation) : T?
      T::BaseQuery.new
        {% for attribute in attribute_names %}
          .{{ attribute.id }}.nilable_eq(operation.{{ attribute.id }}.value)
        {% end %}
        .first?
    end
  end

  # :nodoc:
  macro included
    {% for method in ["upsert", "upsert!"] %}
      # Performs a create or update depending on if there is a conflicting row in the database.
      #
      # See `Avram::Upsert.upsert_lookup_columns` for full documentation and examples.
      def self.{{ method.id }}(*args, **named_args)
        \{% raise "Please use the 'upsert_lookup_columns' macro in #{@type} before using '{{ method.id }}'" %}
      end
    {% end %}
  end
end
