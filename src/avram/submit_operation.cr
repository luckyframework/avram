require "./operation"
require "./needy_initializer_and_save_methods"

abstract class Avram::SubmitOperation < Avram::Operation
  include Avram::NeedySubmitOperationInitializer

  def self.run(params : Avram::Paramable, **needs)
    inst = self.new(params, **needs)
    result = inst.submit
    yield(inst, result)
  end

  abstract def submit
end
