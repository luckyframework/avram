require "./validations"
require "./callbacks/delete_callbacks"
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
  include Avram::DeleteCallbacks
  include Avram::InheritColumnAttributes
  include Avram::AddColumnAttributes

  enum OperationStatus
    Deleted
    DeleteFailed
    Unperformed
  end

  macro inherited
    @@permitted_param_keys = [] of String

    @record : T
    @params : Avram::Paramable
    getter :record, :params
    property delete_status : OperationStatus = OperationStatus::Unperformed
  end

  def self.param_key : String
    T.name.underscore
  end

  delegate :write_database, :table_name, :primary_key_name, to: T

  # A helper method to backfill accesing the database
  # before they were split in to read/write methods
  def database : Avram::Database.class
    write_database
  end

  def delete : Bool
    before_delete

    if valid?
      transaction_committed = write_database.transaction do
        @record = delete_or_soft_delete(record)
        after_delete(record)
        true
      end

      if transaction_committed
        mark_as_deleted
        after_commit(record)
        publish_delete_success_event
        true
      else
        mark_as_failed
        publish_delete_failed_event
        false
      end
    else
      mark_as_failed
      publish_delete_failed_event
      false
    end
  end

  def delete!
    if delete
      @record
    else
      raise Avram::InvalidOperationError.new(operation: self)
    end
  end

  # :nodoc:
  def default_validations : Nil
  end

  # Returns `true` if all attributes are valid,
  # and there's no custom errors
  def valid? : Bool
    default_validations
    custom_errors.empty? && attributes.all?(&.valid?)
  end

  def mark_as_deleted : Bool
    self.delete_status = OperationStatus::Deleted
    true
  end

  # Returns true if the operation has run and saved the record successfully
  def deleted? : Bool
    delete_status == OperationStatus::Deleted
  end

  def mark_as_failed : Bool
    self.delete_status = OperationStatus::DeleteFailed
    false
  end

  def before_delete; end

  def after_delete(_record : T); end

  def after_commit(_record : T); end

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
    if record.is_a?(Avram::SoftDelete::Model)
      record.soft_delete
    else
      record.delete
      record
    end
  end
end
