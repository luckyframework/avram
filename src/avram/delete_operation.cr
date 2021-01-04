require "./validations"
require "./callbacks"
require "./define_attribute"
require "./operation_errors"
require "./param_key_override"
require "./inherit_column_attributes"
require "./needy_initializer_and_delete_methods"

abstract class Avram::DeleteOperation(T)
  include Avram::NeedyInitializerAndDeleteMethods
  include Avram::DefineAttribute
  include Avram::Validations
  include Avram::OperationErrors
  include Avram::ParamKeyOverride
  include Avram::Callbacks
  include Avram::InheritColumnAttributes

  enum DeleteStatus
    Deleted
    DeleteFailed
    Unperformed
  end

  macro inherited
    @@permitted_param_keys = [] of String

    @record : T
    @params : Avram::Paramable
    getter :record, :params
    property delete_status : DeleteStatus = DeleteStatus::Unperformed
  end

  def self.param_key
    T.name.underscore
  end

  def delete : Bool
    before_delete

    if valid?
      result = delete_or_soft_delete(@record)
      @record = result
      after_delete(@record)
      publish_delete_success_event
      mark_as_deleted
    else
      publish_delete_failed_event
      mark_as_failed
    end
  end

  def delete!
    if delete
      @record
    else
      raise Avram::InvalidOperationError.new(operation: self)
    end
  end

  # Returns `true` if all attributes are valid,
  # and there's no custom errors
  def valid?
    custom_errors.empty? && attributes.all?(&.valid?)
  end

  def mark_as_deleted
    self.delete_status = DeleteStatus::Deleted
    true
  end

  # Returns true if the operation has run and saved the record successfully
  def deleted?
    delete_status == DeleteStatus::Deleted
  end

  def mark_as_failed
    self.delete_status = DeleteStatus::DeleteFailed
    false
  end

  def before_delete; end

  def after_delete(_record : T); end

  # :nodoc:
  def publish_delete_failed_event
    Avram::Events::DeleteFailedEvent.publish(
      operation_class: self.class.name,
      errors: errors
    )
  end

  # :nodoc:
  def publish_delete_success_event
    Avram::Events::DeleteSuccessEvent.publish(
      operation_class: self.class.name
    )
  end

  private def delete_or_soft_delete(record : T) : T
    result = if record.is_a?(Avram::SoftDelete::Model)
               record.soft_delete
             else
               record.delete
               record
             end
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
      @_{{ attribute[:name] }} : Avram::Attribute({{ attribute[:type] }})?

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

        @_{{ attribute[:name] }} ||= Avram::Attribute({{ attribute[:type] }}).new(
          name: :{{ attribute[:name].id }},
          param: permitted_params["{{ attribute[:name] }}"]?,
          value: value,
          param_key: self.class.param_key)
      end

      private def default_value_for_{{ attribute[:name] }}
        {% if attribute[:value] || attribute[:value] == false %}
          parse_result = {{ attribute[:type] }}.adapter.parse({{ attribute[:value] }})
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
          parse_result = {{ attribute[:type] }}.adapter.parse([_value])
        {% else %}
          parse_result = {{ attribute[:type] }}.adapter.parse(_value)
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
  end
end
