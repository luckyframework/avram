require "./spec_helper"

class UniquenessSaveOperation < User::SaveOperation
  before_save do
    validate_uniqueness_of name
    validate_uniqueness_of nickname, query: UserQuery.new.nickname.lower
  end
end

class UniquenessWithCustomMessageSaveOperation < User::SaveOperation
  before_save do
    validate_uniqueness_of name, message: "cannot be used"
  end
end

private def attribute(value)
  Avram::Attribute.new(value: value, param: nil, param_key: "fake", name: :fake)
end

describe Avram::Validations do
  describe "validate_at_most_one_filled" do
    it "marks filled attribute as invalid if more than one is filled" do
      filled_attribute = attribute("filled")
      filled_attribute_2 = attribute("filled")
      blank_attribute = attribute("")
      Avram::Validations.validate_at_most_one_filled(filled_attribute, filled_attribute_2, blank_attribute)
      filled_attribute.valid?.should be_true
      blank_attribute.valid?.should be_true
      filled_attribute_2.errors.should eq(["must be blank"])
    end

    it "does not mark any fields as invalid if just one is filled" do
      filled_attribute = attribute("filled")
      blank_attribute = attribute("")

      Avram::Validations.validate_at_most_one_filled(filled_attribute, blank_attribute)

      filled_attribute.valid?.should be_true
      blank_attribute.valid?.should be_true
    end
  end

  describe "validate_exactly_one_filled" do
    it "marks filled attribute as invalid if more than one is filled" do
      filled_attribute = attribute("filled")
      filled_attribute_2 = attribute("filled")
      blank_attribute = attribute("")
      Avram::Validations.validate_exactly_one_filled(filled_attribute, filled_attribute_2, blank_attribute)
      filled_attribute.valid?.should be_true
      blank_attribute.valid?.should be_true
      filled_attribute_2.errors.should eq(["must be blank"])
    end

    it "marks first field as invalid if no attributes are filled" do
      first_blank_attribute = attribute(nil)
      second_blank_attribute = attribute("")

      Avram::Validations.validate_exactly_one_filled(first_blank_attribute, second_blank_attribute)

      first_blank_attribute.errors.should eq(["at least one must be filled"])
      second_blank_attribute.valid?.should be_true
    end

    it "fields are valid if only one is filled" do
      filled_attribute = attribute("filled")
      blank_attribute = attribute("")

      Avram::Validations.validate_exactly_one_filled(filled_attribute, blank_attribute)

      filled_attribute.valid?.should be_true
      blank_attribute.valid?.should be_true
    end
  end

  describe "validate_required" do
    it "validates multiple attributes" do
      empty_attribute = attribute("")
      nil_attribute = attribute(nil)

      Avram::Validations.validate_required(empty_attribute, nil_attribute)

      empty_attribute.errors.should eq ["is required"]
      nil_attribute.errors.should eq ["is required"]
    end

    it "adds no errors if things are present" do
      filled_attribute = attribute("Filled")

      Avram::Validations.validate_required(filled_attribute)

      filled_attribute.valid?.should be_true
    end

    it "adds no error if the value is 'false'" do
      false_attribute = attribute(false)

      Avram::Validations.validate_required false_attribute

      false_attribute.valid?.should be_true
    end
  end

  describe "validate_uniqueness_of" do
    it "validates that a new record is unique with a query or without one" do
      existing_user = UserBox.new.name("Sally").nickname("Sal").create
      operation = UniquenessSaveOperation.new
      operation.name.value = existing_user.name
      operation.nickname.value = existing_user.nickname.not_nil!.downcase

      operation.valid?

      operation.name.errors.should contain "is already taken"
      operation.nickname.errors.should contain "is already taken"
    end

    it "ignores the existing record on update" do
      existing_user = UserBox.new.name("Sally").create
      operation = UniquenessSaveOperation.new(existing_user)
      operation.name.value = existing_user.name

      operation.valid?

      operation.name.errors.should_not contain "is already taken"
    end
  end

  describe "validates with custom messages" do
    it "validates custom message for validates_required" do
      empty_attribute = attribute("")

      Avram::Validations.validate_required empty_attribute, message: "ugh"

      empty_attribute.errors.should eq(["ugh"])
    end

    it "validates custom message for validate_uniqueness_of" do
      existing_user = UserBox.create
      UniquenessWithCustomMessageSaveOperation.create(name: existing_user.name) do |operation, _user|
        operation.name.errors.should eq(["cannot be used"])
      end
    end

    it "validates custom message for validate_inclusion_of" do
      state_attribute = attribute("Iowa")

      Avram::Validations.validate_inclusion_of state_attribute, ["Utah"], message: "nope!"

      state_attribute.errors.should eq(["nope!"])
    end

    it "validates custom message for validate_acceptance_of" do
      false_attribute = attribute(false)

      Avram::Validations.validate_acceptance_of false_attribute, message: "must be accepted"

      false_attribute.errors.should eq(["must be accepted"])
    end

    it "validates custom message for validate_confirmation_of" do
      first = attribute("first")
      second = attribute("second")

      Avram::Validations.validate_confirmation_of first, with: second, message: "not even close"

      second.errors.should eq(["not even close"])
    end
  end

  describe "validate_acceptance_of" do
    it "validates the attribute value is true" do
      false_attribute = attribute(false)
      Avram::Validations.validate_acceptance_of false_attribute
      false_attribute.errors.should eq(["must be accepted"])

      nil_attribute = attribute(nil)
      Avram::Validations.validate_acceptance_of nil_attribute
      nil_attribute.errors.should eq(["must be accepted"])

      accepted_attribute = attribute(true)
      Avram::Validations.validate_acceptance_of accepted_attribute
      accepted_attribute.valid?.should be_true
    end
  end

  describe "validate_confirmation_of" do
    it "validates the attribute values match" do
      first = attribute("first")
      second = attribute("second")
      Avram::Validations.validate_confirmation_of first, with: second
      second.errors.should eq(["must match"])

      first = attribute("same")
      second = attribute("same")
      Avram::Validations.validate_confirmation_of first, with: second
      second.valid?.should be_true
    end
  end

  describe "validate_inclusion_of" do
    it "validates" do
      allowed_name = attribute("Jamie")
      Avram::Validations.validate_inclusion_of(allowed_name, in: ["Jamie"])
      allowed_name.valid?.should be_true

      forbidden_name = attribute("123123123")
      Avram::Validations.validate_inclusion_of(forbidden_name, in: ["Jamie"])
      forbidden_name.errors.should eq(["is invalid"])
    end

    it "can allow nil" do
      nil_name = Avram::Attribute(String?).new(value: nil, param: nil, param_key: "fake", name: :fake)

      Avram::Validations.validate_inclusion_of(nil_name, in: ["Jamie"], allow_nil: true)
      nil_name.valid?.should be_true

      Avram::Validations.validate_inclusion_of(nil_name, in: ["Jamie"], allow_nil: false)
      nil_name.valid?.should be_false

      Avram::Validations.validate_inclusion_of(nil_name, in: ["Jamie"])
      nil_name.valid?.should be_false
    end
  end

  describe "validate_size_of" do
    it "validates" do
      incorrect_size_attribute = attribute("P")
      Avram::Validations.validate_size_of(incorrect_size_attribute, is: 2)
      incorrect_size_attribute.errors.should eq(["is invalid"])

      too_short_attribute = attribute("P")
      Avram::Validations.validate_size_of(too_short_attribute, min: 2)
      too_short_attribute.errors.should eq(["is too short"])

      too_long_attribute = attribute("Supercalifragilisticexpialidocious")
      Avram::Validations.validate_size_of(too_long_attribute, max: 32)
      too_long_attribute.errors.should eq(["is too long"])

      just_right_attribute = attribute("Goldilocks")
      Avram::Validations.validate_size_of(just_right_attribute, is: 10)
      just_right_attribute.valid?.should be_true
    end

    it "raises an error for an impossible condition" do
      does_not_matter = attribute(nil)
      expect_raises(Avram::ImpossibleValidation) do
        Avram::Validations.validate_size_of does_not_matter, min: 4, max: 1
      end
    end

    it "can allow nil" do
      just_nil = attribute(nil)
      Avram::Validations.validate_size_of(just_nil, is: 10, allow_nil: true)
      just_nil.valid?.should be_true

      Avram::Validations.validate_size_of(just_nil, min: 1, max: 2, allow_nil: true)
      just_nil.valid?.should be_true

      Avram::Validations.validate_size_of(just_nil, is: 10)
      just_nil.valid?.should be_false

      Avram::Validations.validate_size_of(just_nil, min: 1, max: 2)
      just_nil.valid?.should be_false
    end
  end
end
