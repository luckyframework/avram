require "../../../spec_helper"

include CleanupHelper
include GeneratorHelper

describe Gen::Model do
  it "generates a model" do
    with_cleanup do
      io = generate Gen::Model, "Customer"

      should_create_files_with_contents io,
        "./src/models/customer.cr": "table"
      should_create_files_with_contents io,
        "./src/operations/save_customer.cr": "# permit_columns column_1, column_2"
      should_create_files_with_contents io,
        "./src/models/customer.cr": "class Customer < BaseModel",
        "./src/operations/save_customer.cr": "class SaveCustomer < Customer::SaveOperation",
        "./src/operations/delete_customer.cr": "class DeleteCustomer < Customer::DeleteOperation",
        "./src/queries/customer_query.cr": "class CustomerQuery < Customer::BaseQuery"
      should_generate_migration named: "create_customers.cr"
    end
  end

  it "generates a model with columns" do
    with_cleanup do
      io = generate Gen::Model, "ContactInfo", "name:String", "notes:String?", "contacted_at:Time"

      should_create_files_with_contents io,
        "./src/models/contact_info.cr": "table"
      should_create_files_with_contents io,
        "./src/models/contact_info.cr": "column name : String",
        "./src/operations/save_contact_info.cr": "# permit_columns name, notes, contacted_at"
      should_create_files_with_contents io,
        "./src/models/contact_info.cr": "column notes : String?"
      should_create_files_with_contents io,
        "./src/models/contact_info.cr": "class ContactInfo < BaseModel",
        "./src/operations/save_contact_info.cr": "class SaveContactInfo < ContactInfo::SaveOperation",
        "./src/operations/delete_contact_info.cr": "class DeleteContactInfo < ContactInfo::DeleteOperation",
        "./src/queries/contact_info_query.cr": "class ContactInfoQuery < ContactInfo::BaseQuery"
      should_generate_migration named: "create_contact_infos.cr",
        with: "add notes : String?"
      should_generate_migration named: "create_contact_infos.cr",
        with: "add contacted_at : Time"
    end
  end

  describe "error messages for unsupported column types" do
    it "contains each unsupported type passed in the arguments" do
      with_cleanup do
        bad_int_column = "int_column:integer"
        bad_text_column = "text_column:text"
        good_string_column = "good_column:String"
        good_optional_string_column = "good_optional_column:String?"

        io = generate Gen::Model, "ModelName", bad_int_column, bad_text_column, good_string_column, good_optional_string_column

        io.to_s.should contain("Unable to generate model ModelName")
        io.to_s.should contain("the following columns are using types not supported by the generator")
        io.to_s.should contain(bad_int_column)
        io.to_s.should contain(bad_text_column)
        io.to_s.should_not contain(good_string_column)
        io.to_s.should_not contain(good_optional_string_column)
      end
    end

    it "displays an error when given a more complex type" do
      io = generate Gen::Model, "Alphabet", "a:BigDecimal"
      io.to_s.should contain("For more complex types that can be added to your migrations manually")
    end
  end

  it "displays an error if given no arguments" do
    io = generate Gen::Model
    io.to_s.should contain("Model name is required.")
  end

  it "displays an error if argument is not camelcase" do
    with_cleanup do
      io = generate Gen::Model, "invalid_name"
      io.to_s.should contain("Model name should be camel case")
    end
  end

  it "displays an error if the name contains weird characters" do
    with_cleanup do
      io = generate Gen::Model, ":-)sillyame"
      io.to_s.should contain("Model name should only contain letters")
    end
  end

  it "displays an error if the model has already been generated" do
    with_cleanup do
      generate Gen::Model, "User"
      io = generate Gen::Model, "User"
      io.to_s.should contain("'User' model already exists at ./src/models/user.cr")
    end
  end
end

private def generate(generator : Class, *options) : IO
  task = generator.new
  task.output = IO::Memory.new
  # HACK: Some tasks are still using a legacy task format with ARGV
  options.each { |opt| ARGV.push(opt) }
  task.print_help_or_call(args: ARGV)
  ARGV.clear
  task.output
end
