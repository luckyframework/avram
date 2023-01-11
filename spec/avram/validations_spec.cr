require "../spec_helper"

class UniquenessSaveOperation < User::SaveOperation
  before_save do
    validate_uniqueness_of name
    validate_uniqueness_of nickname, query: UserQuery.new.nickname.lower
    validate_uniqueness_of age, query: UserQuery.new.name.nilable_eq(name.value)
  end
end

class UniquenessWithCustomMessageSaveOperation < User::SaveOperation
  before_save do
    validate_uniqueness_of name, message: "cannot be used"
  end
end

struct TestI18nBackend < Avram::I18nBackend
  def get(key : String | Symbol) : String
    case key
    when :validate_required
      "is terribly missed"
    else
      "is totally wrong"
    end
  end
end

private def attribute(value : T) : Avram::Attribute(T) forall T
  Avram::Attribute.new(value: value, param: nil, param_key: "fake", name: :fake)
end

private def nil_attribute(type : T.class) : Avram::Attribute(T) forall T
  Avram::Attribute(T).new(value: nil, param: nil, param_key: "fake", name: :fake)
end

describe Avram::Validations do
  describe "validate_at_most_one_filled" do
    it "marks filled attribute as invalid if more than one is filled" do
      filled_attribute = attribute("filled")
      filled_attribute_2 = attribute("filled")
      blank_attribute = attribute("")
      result = Avram::Validations.validate_at_most_one_filled(filled_attribute, filled_attribute_2, blank_attribute)
      result.should eq(false)
      filled_attribute.valid?.should be_true
      blank_attribute.valid?.should be_true
      filled_attribute_2.errors.should eq(["must be blank"])
    end

    it "does not mark any fields as invalid if just one is filled" do
      filled_attribute = attribute("filled")
      blank_attribute = attribute("")

      result = Avram::Validations.validate_at_most_one_filled(filled_attribute, blank_attribute)
      result.should eq(true)

      filled_attribute.valid?.should be_true
      blank_attribute.valid?.should be_true
    end
  end

  describe "validate_exactly_one_filled" do
    it "marks filled attribute as invalid if more than one is filled" do
      filled_attribute = attribute("filled")
      filled_attribute_2 = attribute("filled")
      blank_attribute = attribute("")
      result = Avram::Validations.validate_exactly_one_filled(filled_attribute, filled_attribute_2, blank_attribute)
      result.should eq(false)
      filled_attribute.valid?.should be_true
      blank_attribute.valid?.should be_true
      filled_attribute_2.errors.should eq(["must be blank"])
    end

    it "marks first field as invalid if no attributes are filled" do
      first_blank_attribute = nil_attribute(String)
      second_blank_attribute = attribute("")

      result = Avram::Validations.validate_exactly_one_filled(first_blank_attribute, second_blank_attribute)
      result.should eq(false)
      first_blank_attribute.errors.should eq(["at least one must be filled"])
      second_blank_attribute.valid?.should be_true
    end

    it "fields are valid if only one is filled" do
      filled_attribute = attribute("filled")
      blank_attribute = attribute("")

      result = Avram::Validations.validate_exactly_one_filled(filled_attribute, blank_attribute)
      result.should eq(true)
      filled_attribute.valid?.should be_true
      blank_attribute.valid?.should be_true
    end
  end

  describe "validate_required" do
    it "validates multiple attributes" do
      empty_attribute = attribute("")
      nil_attribute = nil_attribute(String)

      result = Avram::Validations.validate_required(empty_attribute, nil_attribute)
      result.should eq(false)
      empty_attribute.errors.should eq ["is required"]
      nil_attribute.errors.should eq ["is required"]
    end

    it "adds no errors if things are present" do
      filled_attribute = attribute("Filled")

      result = Avram::Validations.validate_required(filled_attribute)
      result.should eq(true)
      filled_attribute.valid?.should be_true
    end

    it "adds no error if the value is 'false'" do
      false_attribute = attribute(false)

      result = Avram::Validations.validate_required false_attribute
      result.should eq(true)
      false_attribute.valid?.should be_true
    end

    it "can use a custom backend" do
      Avram.temp_config(i18n_backend: TestI18nBackend.new) do
        empty_attribute = attribute("")

        Avram::Validations.validate_required(empty_attribute)
        empty_attribute.errors.should eq ["is terribly missed"]
      end
    end
  end

  describe "validate_uniqueness_of" do
    it "validates that a new record is unique with a query or without one" do
      existing_user = UserFactory.new.name("Sally").nickname("Sal").create
      operation = UniquenessSaveOperation.new
      operation.name.value = existing_user.name
      operation.nickname.value = existing_user.nickname.to_s.downcase
      operation.age.value = existing_user.age

      operation.save

      operation.valid?.should be_false
      operation.name.errors.should contain "is already taken"
      operation.nickname.errors.should contain "is already taken"
      operation.age.errors.should contain "is already taken"
    end

    it "ignores the existing record on update" do
      existing_user = UserFactory.new.name("Sally").nickname("Sal").create
      operation = UniquenessSaveOperation.new(existing_user)
      operation.name.value = existing_user.name
      operation.nickname.value = existing_user.nickname.to_s.downcase
      operation.age.value = existing_user.age

      operation.save

      operation.name.errors.should be_empty
      operation.nickname.errors.should be_empty
      operation.age.errors.should be_empty
    end
  end

  describe "validates with custom messages" do
    it "validates custom message for validates_required" do
      empty_attribute = attribute("")

      result = Avram::Validations.validate_required empty_attribute, message: "ugh"
      result.should eq(false)
      empty_attribute.errors.should eq(["ugh"])
    end

    it "validates custom message for validate_uniqueness_of" do
      existing_user = UserFactory.create
      UniquenessWithCustomMessageSaveOperation.create(name: existing_user.name) do |operation, _user|
        operation.name.errors.should eq(["cannot be used"])
      end
    end

    it "validates custom message for validate_inclusion_of" do
      state_attribute = attribute("Iowa")

      result = Avram::Validations.validate_inclusion_of state_attribute, ["Utah"], message: "nope!"
      result.should eq(false)
      state_attribute.errors.should eq(["nope!"])
    end

    it "validates custom message for validate_acceptance_of" do
      false_attribute = attribute(false)

      result = Avram::Validations.validate_acceptance_of false_attribute, message: "must be accepted"
      result.should eq(false)
      false_attribute.errors.should eq(["must be accepted"])
    end

    it "validates custom message for validate_confirmation_of" do
      first = attribute("first")
      second = attribute("second")

      result = Avram::Validations.validate_confirmation_of first, with: second, message: "not even close"
      result.should eq(false)
      second.errors.should eq(["not even close"])
    end

    it "validates custom message for validate_numeric" do
      too_small_attribute = attribute(1)

      result = Avram::Validations.validate_numeric too_small_attribute, at_least: 2, message: "number is too small"
      result.should eq(false)
      too_small_attribute.errors.should eq(["number is too small"])
    end
  end

  describe "validate_acceptance_of" do
    it "validates the attribute value is true" do
      false_attribute = attribute(false)
      result = Avram::Validations.validate_acceptance_of false_attribute
      result.should eq(false)
      false_attribute.errors.should eq(["must be accepted"])

      nil_attribute = nil_attribute(Bool)
      result = Avram::Validations.validate_acceptance_of nil_attribute
      result.should eq(false)
      nil_attribute.errors.should eq(["must be accepted"])

      accepted_attribute = attribute(true)
      result = Avram::Validations.validate_acceptance_of accepted_attribute
      result.should eq(true)
      accepted_attribute.valid?.should be_true
    end
  end

  describe "validate_confirmation_of" do
    it "validates the attribute values match" do
      first = attribute("first")
      second = attribute("second")
      result = Avram::Validations.validate_confirmation_of first, with: second
      result.should eq(false)
      second.errors.should eq(["must match"])

      first = attribute("same")
      second = attribute("same")
      result = Avram::Validations.validate_confirmation_of first, with: second
      result.should eq(true)
      second.valid?.should be_true
    end

    it "can use a custom backend" do
      Avram.temp_config(i18n_backend: TestI18nBackend.new) do
        first = attribute("first")
        second = attribute("second")
        Avram::Validations.validate_confirmation_of first, with: second
        second.errors.should eq(["is totally wrong"])
      end
    end
  end

  describe "validate_inclusion_of" do
    it "validates" do
      allowed_name = attribute("Jamie")
      result = Avram::Validations.validate_inclusion_of(allowed_name, in: ["Jamie"])
      result.should eq(true)
      allowed_name.valid?.should be_true

      allowed_number = attribute(4)
      result = Avram::Validations.validate_inclusion_of(allowed_number, in: 0..5)
      result.should eq(true)
      allowed_number.valid?.should eq(true)

      forbidden_name = attribute("123123123")
      result = Avram::Validations.validate_inclusion_of(forbidden_name, in: ["Jamie"])
      result.should eq(false)
      forbidden_name.errors.should eq(["is not included in the list"])
    end

    it "can allow nil" do
      nil_name = Avram::Attribute(String).new(value: nil, param: nil, param_key: "fake", name: :fake)

      result = Avram::Validations.validate_inclusion_of(nil_name, in: ["Jamie"], allow_nil: true)
      result.should eq(true)
      nil_name.valid?.should be_true

      result = Avram::Validations.validate_inclusion_of(nil_name, in: ["Jamie"], allow_nil: false)
      result.should eq(false)
      nil_name.valid?.should be_false

      result = Avram::Validations.validate_inclusion_of(nil_name, in: ["Jamie"])
      result.should eq(false)
      nil_name.valid?.should be_false
    end
  end

  describe "validate_size_of" do
    it "validates" do
      incorrect_size_attribute = attribute("P")
      result = Avram::Validations.validate_size_of(incorrect_size_attribute, is: 2)
      result.should eq(false)
      incorrect_size_attribute.errors.should eq(["must be exactly 2 characters long"])

      too_short_attribute = attribute("P")
      result = Avram::Validations.validate_size_of(too_short_attribute, min: 2)
      result.should eq(false)
      too_short_attribute.errors.should eq(["must have at least 2 characters"])

      too_long_attribute = attribute("Supercalifragilisticexpialidocious")
      result = Avram::Validations.validate_size_of(too_long_attribute, max: 32)
      result.should eq(false)
      too_long_attribute.errors.should eq(["must not have more than 32 characters"])

      just_right_attribute = attribute("Goldilocks")
      result = Avram::Validations.validate_size_of(just_right_attribute, is: 10)
      result.should eq(true)
      just_right_attribute.valid?.should be_true
    end

    it "raises an error for an impossible condition" do
      expect_raises(Avram::ImpossibleValidation) do
        Avram::Validations.validate_size_of nil_attribute(String), min: 4, max: 1
      end
    end

    it "can allow nil" do
      just_nil = nil_attribute(String)
      result = Avram::Validations.validate_size_of(just_nil, is: 10, allow_nil: true)
      result.should eq(true)
      just_nil.valid?.should be_true

      just_nil = nil_attribute(String)
      result = Avram::Validations.validate_size_of(just_nil, min: 1, max: 2, allow_nil: true)
      result.should eq(true)
      just_nil.valid?.should be_true

      just_nil = nil_attribute(String)
      result = Avram::Validations.validate_size_of(just_nil, is: 10)
      result.should eq(false)
      just_nil.valid?.should be_false

      just_nil = nil_attribute(String)
      result = Avram::Validations.validate_size_of(just_nil, min: 1, max: 2)
      result.should eq(false)
      just_nil.valid?.should be_false
    end
  end

  describe "validate_numeric" do
    it "validates" do
      too_small_attribute = attribute(1)
      result = Avram::Validations.validate_numeric(too_small_attribute, at_least: 2)
      result.should eq(false)
      too_small_attribute.errors.should eq(["must be at least 2"])

      too_large_attribute = attribute(38)
      result = Avram::Validations.validate_numeric(too_large_attribute, no_more_than: 32)
      result.should eq(false)
      too_large_attribute.errors.should eq(["must be no more than 32"])

      just_right_attribute = attribute(10)
      result = Avram::Validations.validate_numeric(just_right_attribute, at_least: 9, no_more_than: 11)
      result.should eq(true)
      just_right_attribute.valid?.should be_true

      exactly = attribute(4)
      result = Avram::Validations.validate_numeric(exactly, at_least: 4)
      result.should eq(true)
      exactly.valid?.should be_true
    end

    it "raises an error for an impossible condition" do
      expect_raises(Avram::ImpossibleValidation) do
        Avram::Validations.validate_numeric attribute(100), at_least: 4, no_more_than: 1
      end
    end

    it "can allow nil" do
      just_nil = nil_attribute(Int32)
      result = Avram::Validations.validate_numeric(just_nil, at_least: 1, no_more_than: 2, allow_nil: true)
      result.should eq(true)
      just_nil.valid?.should be_true

      just_nil = nil_attribute(Int32)
      result = Avram::Validations.validate_numeric(just_nil, at_least: 1, no_more_than: 2)
      result.should eq(false)
      just_nil.valid?.should be_false
    end

    it "handles different types of numbers" do
      attribute = attribute(10.9)
      result = Avram::Validations.validate_numeric(attribute, at_least: 9, no_more_than: 11)
      result.should eq(true)
      attribute.valid?.should be_true

      attribute = attribute(10)
      result = Avram::Validations.validate_numeric(attribute, at_least: 9.8, no_more_than: 10.9)
      result.should eq(true)
      attribute.valid?.should be_true

      attribute = attribute(10_i64)
      result = Avram::Validations.validate_numeric(attribute, at_least: 9, no_more_than: 11)
      result.should eq(true)
      attribute.valid?.should be_true
    end
  end

  describe "validate_format_of" do
    it "validates" do
      invalid_attribute = attribute("hi AT hey DOT com")
      result = Avram::Validations.validate_format_of(
        invalid_attribute,
        /[^@]+@[^\.]+\..+/
      )
      result.should eq(false)
      invalid_attribute.errors.should eq ["is invalid"]

      valid_attribute = attribute("hi@hey.com")
      result = Avram::Validations.validate_format_of(
        valid_attribute,
        /[^@]+@[^\.]+\..+/
      )
      result.should eq(true)
      valid_attribute.valid?.should be_true
    end

    it "validates negatively" do
      invalid_attribute = attribute("hi AT hey DOT com")
      result = Avram::Validations.validate_format_of(
        invalid_attribute,
        with: /DOT/,
        match: false
      )
      result.should eq(false)
      invalid_attribute.errors.should eq ["is invalid"]
    end

    it "can allow nil" do
      nil_attribute = nil_attribute(String)
      result = Avram::Validations.validate_format_of(
        nil_attribute,
        with: /[^@]+@[^\.]+\..+/,
        allow_nil: true
      )
      result.should eq(true)
      nil_attribute.valid?.should be_true
    end
  end
end
