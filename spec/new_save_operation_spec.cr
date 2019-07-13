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
  step :run_password_validations
  step :normalize_name
  step :normalize_email
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
  step do
    validate_size_of age, min: 18
  end
end

# Or do we have a mixin?
class SignUpUser < User::SaveOperation
  include User::DefaultValidations
end

# Maybe call 'after_init' just 'step' and the others are 'after_save_step'
# Since we mostly use regular steps and callbacks are more rare
#
# Examples of before_save: https://github.com/search?p=1&q=before_save+NOT+callbacks+NOT+class_eval+NOT+describe+language%3ARuby&type=Code
class SignUpUser < User::SaveOperation
  permit_columns name, email
  attribute password : String
  attribute password_confirmation : String

  step do
    validate_confirmation_of password, with: password_confirmation
    validate_size age, min: 18
  end

  step :run_password_validations # Runs right before save when calling 'call'
  step :normalize_email
  step :calculate_new_total
  # And probably remove 'before_save' instead to 'after_save' or 'step'
  after_commit_step :send_welcome_email
  after_save_step :touch_associations

  def touch_associations(user)
    Company::SaveOperation.update!(user: user, updated_at: Time.utc)
  end
end

class RequestPasswordReset < Avram::VirtualOperation
  # You can modify this in src/operations/mixins/user_from_email.cr
  include UserFromEmail

  attribute email : String

  step validate_email

  def result
    user_from_email
  end

  def result_when_invalid
    nil
  end

  # Run validations and yield the form and the user if valid
  # def submit
  #   user = user_from_email
  #   validate(user)

  #   if valid?
  #     yield self, user
  #   else
  #     yield self, nil
  #   end
  # end

  def validate_email
    validate_required email
    if user_from_email.nil?
      email.add_error "is not in our system"
    end
  end
end

# Maybe...don't worry about it. Some stuff doesn't need tons of defaults
#
# So only needed for things that need to be shared...but  how to let people know...

# Maybe the Auth stuff inherits from SaveUser???

# But what about validations or something for tests? I guess they can be included in the Box?
# Maybe box inherits from SaveOperation and just adds some methods.
# That way you can include validations!!!

class UserBox < User::SaveOperation
  # Adds shortcut methods
  # Adds instance method callbacks
  include Avram::Box
  include NormalizeStuff

  step do
    name "Paul"
  end

  def with_comments(body : Array(String))
    after_commit_step()
  end
end

class CreateTeam < User::SaveOperation
  include Audited

  permit_columns name, age, email

  step do
    some_validations
  end

  after_commit_step send_invitation_emails
end

class DestroyTeam < Lucky::Operation
  needs team : Team

  def execute
    @team.delete
    clear_cache
    do_something_else
  end
end

class ImportCsv < Lucky::Operation
  needs csv_rows : Array(String)

  def execute
    AppDatabase.transaction do
      @csv_rows.each do |row|
      end
    end
  end
end

UserQuery.new.where { name == "Paul" }
UserQuery.new.name("Paul")
UserQuery.new.where { name.lower == "something else" }
UserQuery.new.where { name.ilike == "something else" }
UserQuery.new.where { name("Paul") }
UserQuery.new.where { name.not.eq("Paul") }
UserQuery.new.name.not.eq("Paul")

UserQuery.new.where({name.not.eq("Paul")}).order({name.asc})
