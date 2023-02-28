require "./database_validations"
require "./callbacks"
require "./nested_save_operation"
require "./needy_initializer_and_save_methods"
require "./define_attribute"
require "./mark_as_failed"
require "./param_key_override"
require "./inherit_column_attributes"
require "./validations"
require "./operation_errors"
require "./upsert"

abstract class Avram::SaveOperation(T)
  include Avram::DefineAttribute
  include Avram::Validations
  include Avram::OperationErrors
  include Avram::ParamKeyOverride
  include Avram::NeedyInitializerAndSaveMethods
  include Avram::Callbacks
  include Avram::DatabaseValidations(T)
  include Avram::NestedSaveOperation
  include Avram::MarkAsFailed
  include Avram::InheritColumnAttributes
  include Avram::Upsert
  include Avram::AddColumnAttributes

  enum OperationStatus
    Saved
    SaveFailed
    Unperformed
  end

  macro inherited
    @@permitted_param_keys = [] of String
  end

  @record : T?
  @params : Avram::Paramable

  # :nodoc:
  setter :record
  getter :params, :record
  property save_status : OperationStatus = OperationStatus::Unperformed

  abstract def attributes

  def self.param_key
    T.name.underscore
  end

  def initialize(@params)
  end

  def initialize
    @params = Avram::Params.new
  end

  delegate :database, :table_name, :primary_key_name, to: T

  private def publish_save_failed_event
    Avram::Events::SaveFailedEvent.publish(
      operation_class: self.class.name,
      attributes: generic_attributes
    )
  end

  def generic_attributes
    attributes.map do |attr|
      Avram::GenericAttribute.new(
        name: attr.name,
        param: attr.param.try(&.to_s),
        value: attr.value.try(&.to_s),
        original_value: attr.original_value.try(&.to_s),
        param_key: attr.param_key,
        errors: attr.errors
      )
    end
  end

  private def error_messages_as_string
    errors.join(". ") do |attribute_name, messages|
      "#{attribute_name} #{messages.join(", ")}"
    end
  end

  # :nodoc:
  def self.save(*args, **named_args, &_block)
    {% raise <<-ERROR
      SaveOperations do not have a 'save' method.

      Try this...

        ▸ Use 'create' to create a brand new record.
        ▸ Use 'update' to update an existing record.

      ERROR
    %}
  end

  # Runs all required validations for required types
  # as well as any additional valitaions the type needs to run
  # e.g. polymorphic validations
  def run_default_validations
    validate_required *required_attributes
    default_validations
  end

  # :nodoc:
  def default_validations; end

  # This allows you to skip the default validations
  # which may be used as an escape hatch when you want
  # to allow storing an empty string value.
  macro skip_default_validations
    def run_default_validations
    end
  end

  # Runs required validation,
  # then returns `true` if all attributes are valid,
  # and there's no custom errors
  def valid? : Bool
    # These validations must be ran after all `before_save` callbacks have completed
    # in the case that someone has set a required field in a `before_save`. If we run
    # this in a `before_save` ourselves, the ordering would cause this to be ran first.
    run_default_validations
    custom_errors.empty? && attributes.all?(&.valid?)
  end

  # Returns true if the operation has run and saved the record successfully
  def saved?
    save_status == OperationStatus::Saved
  end

  def created?
    saved? && new_record?
  end

  def updated?
    saved? && !new_record?
  end

  # Return true if the operation has run and the record failed to save
  def save_failed?
    save_status == OperationStatus::SaveFailed
  end

  macro permit_columns(*attribute_names)
    {% for attribute_name in attribute_names %}
      {% if attribute_name.is_a?(TypeDeclaration) %}
        {% raise <<-ERROR
          Must use a Symbol or a bare word in 'permit_columns'. Instead, got: #{attribute_name}

          Try this...

            ▸ permit_columns #{attribute_name.var}

          ERROR
        %}
      {% end %}
      {% unless attribute_name.is_a?(SymbolLiteral) || attribute_name.is_a?(Call) %}
        {% raise <<-ERROR
          Must use a Symbol or a bare word in 'permit_columns'. Instead, got: #{attribute_name}

          Try this...

            ▸ Use a bare word (recommended): 'permit_columns name'
            ▸ Use a Symbol: 'permit_columns :name'

          ERROR
        %}
      {% end %}
      {% if COLUMN_ATTRIBUTES.any? { |attribute| attribute[:name].id == attribute_name.id } %}
        def {{ attribute_name.id }}
          _{{ attribute_name.id }}.permitted
        end

        @@permitted_param_keys << "{{ attribute_name.id }}"
      {% else %}
        {% raise <<-ERROR
          Can't permit '#{attribute_name}' because the column has not been defined on the model for #{@type}.

          Try this...

            ▸ Make sure you spelled the column correctly.
            ▸ Add the column to the model if it doesn't exist.
            ▸ Use 'attribute' if you want an attribute that is not saved to the database.

          ERROR
        %}
      {% end %}
    {% end %}
  end

  def changes : Hash(Symbol, String?)
    attributes_to_hash(column_attributes.select(&.changed?))
  end

  macro add_cast_value_methods(columns)
    private def cast_value(value : Nil)
      nil
    end

    {% for column in columns %}
    # pass `value` to it's `Lucky.to_db` for parsing.
    # In most cases, that's just calling `to_s`, but in the case of an Array,
    # `value` is passed to `PQ::Param` to properly encode `[true]` to `{t}`, etc...
    private def cast_value(value : {{ column[:type] }})
      value.class.adapter.to_db(value.as({{ column[:type] }}))
    end
    {% end %}
  end

  def save : Bool
    before_save

    if valid?
      transaction_committed = database.transaction do
        insert_or_update if !changes.empty? || !persisted?
        after_save(record.as(T))
        true
      end

      if transaction_committed
        self.save_status = OperationStatus::Saved
        after_commit(record.as(T))
        Avram::Events::SaveSuccessEvent.publish(
          operation_class: self.class.name,
          attributes: generic_attributes
        )
        true
      else
        mark_as_failed
        publish_save_failed_event
        false
      end
    else
      mark_as_failed
      publish_save_failed_event
      false
    end
  end

  def save! : T
    if save
      record.as(T)
    else
      raise Avram::InvalidOperationError.new(operation: self)
    end
  end

  def update! : T
    save!
  end

  def persisted? : Bool
    !!record_id
  end

  # `#persisted?` always returns `true` in `after_*` hooks, whether
  # a new record was created, or an existing one was updated.
  #
  # This method should always return `true` for a create or `false`
  # for an update, independent of the stage we are at in the operation.
  def new_record? : Bool
    {{ T.constant(:PRIMARY_KEY_NAME).id }}.value.nil?
  end

  private def insert_or_update
    if persisted?
      update record_id
    else
      insert
    end
  end

  private def record_id
    @record.try &.id
  end

  def before_save; end

  def after_save(_record : T); end

  def after_commit(_record : T); end

  private def insert : T
    self.created_at.value ||= Time.utc if responds_to?(:created_at)
    self.updated_at.value ||= Time.utc if responds_to?(:updated_at)
    @record = database.query insert_sql.statement, args: insert_sql.args do |rs|
      @record = T.from_rs(rs).first
    end
  end

  private def update(id) : T
    self.updated_at.value = Time.utc if responds_to?(:updated_at)
    @record = database.query update_query(id).statement_for_update(changes), args: update_query(id).args_for_update(changes) do |rs|
      @record = T.from_rs(rs).first
    end
  end

  private def update_query(id)
    Avram::QueryBuilder
      .new(table_name)
      .select(T.column_names)
      .where(Avram::Where::Equal.new(primary_key_name, id.to_s))
  end

  private def insert_sql
    insert_values = attributes_to_hash(column_attributes).compact
    Avram::Insert.new(table_name, insert_values, T.column_names)
  end

  private def attributes_to_hash(attributes) : Hash(Symbol, String?)
    attributes.map { |attribute| {attribute.name, cast_value(attribute.value)} }.to_h
  end
end
