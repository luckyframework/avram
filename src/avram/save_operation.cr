require "./database_validations"
require "./callbacks"
require "./nested_save_operation"
require "./needy_initializer_and_save_methods"
require "./define_attribute"
require "./mark_as_failed"
require "./param_key_override"
require "./inherit_column_attributes"
require "./validations"
require "./define_attribute"
require "./operation_errors"
require "./param_key_override"

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

  enum SaveStatus
    Saved
    SaveFailed
    Unperformed
  end

  macro inherited
    @@permitted_param_keys = [] of String
  end

  @record : T?
  @params : Avram::Paramable
  getter :record, :params
  property save_status : SaveStatus = SaveStatus::Unperformed

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

  # :nodoc:
  def published_save_failed_event
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
    errors.map do |attribute_name, messages|
      "#{attribute_name} #{messages.join(", ")}"
    end.join(". ")
  end

  # :nodoc:
  def self.save(*args, **named_args, &block)
    {% raise <<-ERROR
      SaveOperations do not have a 'save' method.

      Try this...

        ▸ Use 'create' to create a brand new record.
        ▸ Use 'update' to update an existing record.

      ERROR
    %}
  end

  # :nodoc:
  macro add_column_attributes(attributes)
    {% for attribute in attributes %}
      {% COLUMN_ATTRIBUTES << attribute %}
    {% end %}

    private def extract_changes_from_params
      permitted_params.each do |key, value|
        {% for attribute in attributes %}
          set_{{ attribute[:name] }}_from_param value if key == {{ attribute[:name].stringify }}
        {% end %}
      end
    end

    {% for attribute in attributes %}
      @_{{ attribute[:name] }} : Avram::Attribute({{ attribute[:type] }}?)?

      def {{ attribute[:name] }}
        _{{ attribute[:name] }}
      end

      def {{ attribute[:name] }}=(_value)
        \{% raise <<-ERROR
          Can't set an attribute value with '{{attribute[:name]}} = '

          Try this...

            ▸ Use '.value' to set the value: '{{attribute[:name]}}.value = '

          ERROR
          %}
      end

      private def _{{ attribute[:name] }}
        record_value = @record.try(&.{{ attribute[:name] }})
        value = record_value.nil? ? default_value_for_{{ attribute[:name] }} : record_value

        @_{{ attribute[:name] }} ||= Avram::Attribute({{ attribute[:type] }}?).new(
          name: :{{ attribute[:name].id }},
          param: permitted_params["{{ attribute[:name] }}"]?,
          value: value,
          param_key: self.class.param_key)
      end

      private def default_value_for_{{ attribute[:name] }}
        {% if attribute[:value] || attribute[:value] == false %}
          {% if attribute[:type].is_a?(Generic) %}
            parse_result = {{ attribute[:type].type_vars.first }}::Lucky.parse([{{ attribute[:value] }}])
          {% else %}
            parse_result = {{ attribute[:type] }}::Lucky.parse({{ attribute[:value] }})
          {% end %}
          if parse_result.is_a? Avram::Type::SuccessfulCast
            parse_result.value.as({{ attribute[:type] }})
          else
            nil
          end
        {% else %}
          nil
        {% end %}
      end

      def permitted_params
        new_params = {} of String => String
        @params.nested(self.class.param_key).each do |key, value|
          new_params[key] = value
        end
        new_params.select(@@permitted_param_keys)
      end

      def set_{{ attribute[:name] }}_from_param(_value)
        # In nilable types, `nil` is ok, and non-nilable types we will get the
        # "is required" error.
        if _value.blank?
          {{ attribute[:name] }}.value = nil
          return
        end
        {% if attribute[:type].is_a?(Generic) %}
          # Pass `_value` in as an Array. Currently only single values are supported.
          # TODO: Update this once Lucky params support Arrays natively
          parse_result = {{ attribute[:type].type_vars.first }}::Lucky.parse([_value])
        {% else %}
          parse_result = {{ attribute[:type] }}::Lucky.parse(_value)
        {% end %}
        if parse_result.is_a? Avram::Type::SuccessfulCast
          {{ attribute[:name] }}.value = parse_result.value.as({{ attribute[:type] }})
        else
          {{ attribute[:name] }}.add_error "is invalid"
        end
      end
    {% end %}

    def attributes
      column_attributes + super
    end

    private def column_attributes
      [
        {% for attribute in attributes %}
          {{ attribute[:name] }},
        {% end %}
      ]
    end

    def required_attributes
      Tuple.new(
        {% for attribute in attributes %}
          {% if !attribute[:nilable] && !attribute[:autogenerated] %}
            {{ attribute[:name] }},
          {% end %}
        {% end %}
      )
    end
  end

  # Runs required validation,
  # then returns `true` if all attributes are valid.
  # Set `valid` to false to force invalid state.
  def valid? : Bool
    return false unless valid
    # These validations must be ran after all `before_save` callbacks have completed
    # in the case that someone has set a required field in a `before_save`. If we run
    # this in a `before_save` ourselves, the ordering would cause this to be ran first.
    validate_required *required_attributes
    attributes.all? &.valid?
  end

  # Returns true if the operation has run and saved the record successfully
  def saved?
    save_status == SaveStatus::Saved
  end

  # Return true if the operation has run and the record failed to save
  def save_failed?
    save_status == SaveStatus::SaveFailed
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
          Can't permit '#{attribute_name}' because the column has not been defined on the model.

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
    _changes = {} of Symbol => String?
    column_attributes.each do |attribute|
      if attribute.changed?
        _changes[attribute.name] = cast_value(attribute.value)
      end
    end
    _changes
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
      value.not_nil!.class.adapter.to_db(value.as({{ column[:type] }}))
    end
    {% end %}
  end

  def save : Bool
    before_save
    if valid? && (!persisted? || changes.any?)
      transaction_committed = database.transaction do
        insert_or_update
        saved_record = record.not_nil!
        after_save(saved_record)
        true
      end

      if transaction_committed
        saved_record = record.not_nil!
        after_commit(saved_record)
        self.save_status = SaveStatus::Saved
        Avram::Events::SaveSuccessEvent.publish(
          operation_class: self.class.name,
          attributes: generic_attributes
        )
        true
      else
        mark_as_failed
        false
      end
    elsif valid? && changes.empty?
      self.save_status = SaveStatus::Saved
      true
    else
      mark_as_failed
      false
    end
  end

  def save! : T
    if save
      record.not_nil!
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
    Avram::Insert.new(table_name, changes, T.column_names)
  end
end
