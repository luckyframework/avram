# This file ensures backward compatibility by re-exporting modules
# The actual Operation class now inherits from Lucky::BaseOperation

require "./nothing"

# Use Avram::Nothing in Lucky operations
alias Lucky::Nothing = Avram::Nothing

# Since Avram::Operation now inherits from Lucky::BaseOperation,
# we need to ensure the modules used by existing code still work
module Avram::NeedyInitializer
  # This module is now provided by Lucky::BaseOperation
end

module Avram::DefineAttribute
  # This module is now provided by Lucky::BaseOperation
end

module Avram::Validations
  # This module is now provided by Lucky::BaseOperation
end

module Avram::OperationErrors
  # This module is now provided by Lucky::BaseOperation
end

module Avram::ParamKeyOverride
  # This module is now provided by Lucky::BaseOperation
end

module Avram::Callbacks
  # This module is now provided by Lucky::BaseOperation
end
