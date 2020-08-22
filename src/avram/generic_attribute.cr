# A generic version of `Avram::Attribute` that is used for reporting and metrics.
#
# This is a data only version of an `Avram::Atribute`. It is purely for
# retrieving and reporting on data. For example, `Avram::GenericAttribute` is
# used by `Avram::Events::SaveFailedEvent` so that subscribers can
# get information about attributes that failed to save.
class Avram::GenericAttribute
  getter :name, :param, :original_value, :value, :param_key, :errors

  def initialize(
    @name : Symbol,
    @param : String?,
    @original_value : String?,
    @value : String?,
    @param_key : String,
    @errors : Array(String)
  )
  end

  def valid?
    errors.empty?
  end
end
