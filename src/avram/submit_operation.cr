require "./operation"
require "./needy_initializer_and_save_methods"

abstract class Avram::SubmitOperation < Avram::Operation
  include Avram::NeedySubmitOperationInitializer

  # Yields a block passing in the `operation`, and the
  # return value of the `submit` method.
  def self.run(params : Avram::Paramable, **needs) : Nil
    operation = self.new(params, **needs)
    result = operation.submit
    if operation.valid?
      yield(operation, result)
    else
      yield(operation, nil)
    end
  end

  # This method should return `nil` if your operation fails
  # otherwise return any value you want to be yield to your
  # `Operation.run` block.
  abstract def submit
end
