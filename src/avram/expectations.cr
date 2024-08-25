module Avram::Expectations
  # Tests that an operation or attribute has an error
  #
  # ```
  # CreateReceipt.create(params) do |operation, receipt|
  #   receipt.should be_nil
  #
  #   operation.should have_error
  #   operation.should have_error("is required")
  #   operation.should have_error(/\srequired/)
  #
  #   operation.user_id.should have_error
  #   operation.user_id.should have_error("is required")
  #   operation.user_id.should have_error(/\srequired/)
  # end
  # ```
  def have_error(message = nil)
    HaveErrorExpectation.new(message)
  end

  # Tests that an operation has a custom error
  #
  # ```
  # CreateUser.create(params) do |operation, user|
  #   user.should be_nil
  #
  #   operation.should have_error(:roles)
  #   operation.should have_error(:roles, "is empty")
  #   operation.should have_error(:roles, /\sempty/)
  # end
  # ```
  def have_error(name : Symbol, message = nil)
    HaveCustomErrorExpectation.new(name, message)
  end
end
