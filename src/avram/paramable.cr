require "../lucky/paramable"

module Avram::Paramable
  include Lucky::Paramable

  def has_key_for?(operation : Avram::Operation.class | Avram::SaveOperation.class) : Bool
    !nested?(operation.param_key).empty?
  end
end
