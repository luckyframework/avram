require "./spec_helper"

# Ideas for save operation callbacks

class User < BaseModel
  table do
    column name : String
  end

  # Maybe we should only allow after_init?
  # And others raise with a helpful error, but can be included
  #
  #     allow_after_commit!, allow_after_save!
  #
  # That kind of thing
  class SaveOperation
    after_init do
      # Valdiations that should always run
      validate_somethihng
    end

    # Or maybe
    after_init :run_default_validations

    def run_default_validations
    end

    # Another
    after_init do
      validate_required name, email
      validate_email email
      validate_size_of age, min: 18
    end
  end
end

class SignUpUser < User::SaveOperation
  after_init :run_password_validations
  after_init :normalize_name
  after_init :normalize_email
  after_commit :send_welcome_email

  # Maybe
  on_initialize do
  end

  before_save
  after_save
  after_commit
end

# src/operations/mixins/default_user_validations.cr
module User::DefaultValidations
  after_init do
    validate_size_of age, min: 18
  end
end

# Or do we have a mixin?
class SignUpUser < User::SaveOperation
  include User::DefaultValidations
end

# Maybe...don't worry about it. Some stuff doesn't need tons of defaults
#
# So only needed for things that need to be shared...but  how to let people know...

# Maybe the Auth stuff inherits from SaveUser???

# But what about validations or something for tests? I guess they can be included in the Box?
# Maybe box inherits from SaveOperation and just adds some methods.
# That way you can include validations!!!

class UserBox < User::BoxOperation
  include NormalizeStuff
end
