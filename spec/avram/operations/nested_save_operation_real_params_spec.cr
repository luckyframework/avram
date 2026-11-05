require "../../spec_helper"

# The "deeply nested" specs in `nested_save_operation_deeply_nested_spec.cr`
# exercise `Avram::NestedSaveOperation`'s macros against `FakeDeeplyNestedParams`,
# a stand-in `Avram::Paramable` that hands back already-structured data,
# bypassing `Avram::Params` entirely. These specs instead build a real
# `Avram::Params` from a single, flat `Hash(String, String)` -- the same shape
# `has_many` produces for each of its items -- to prove that deeply nested
# `has_one`/`has_many` `SaveOperation`s also work when fed genuinely
# JSON-encoded or URL-encoded/multipart HTML form-encoded values, not just
# pre-structured test doubles.
private class SaveManagerWithCustomers < Manager::SaveOperation
  class SaveEmployee < Employee::SaveOperation
    class SaveCustomer < Customer::SaveOperation
      permit_columns name
    end

    permit_columns name
    has_many customers : SaveCustomer
  end

  permit_columns name
  has_many employees : SaveEmployee
end

private class SavePostWithReactedComments < Post::SaveOperation
  class SaveComment < Comment::SaveOperation
    class SaveCommentReaction < CommentReaction::SaveOperation
      permit_columns emoji
    end

    permit_columns body
    has_one reaction : SaveCommentReaction
  end

  permit_columns title
  has_many comments : SaveComment
end

private class SaveBusinessWithAliases < Business::SaveOperation
  class SaveEmailAddress < EmailAddress::SaveOperation
    class SaveEmailAlias < EmailAlias::SaveOperation
      permit_columns address
    end

    permit_columns address, default
    has_many aliases : SaveEmailAlias
  end

  permit_columns name
  has_one email_address : SaveEmailAddress
end

describe "Avram::SaveOperation with deeply nested operations backed by real Avram::Params" do
  context "has_many nested inside has_many, submitted as a JSON body" do
    it "saves all three levels" do
      params = Avram::Params.new({
        "name"      => "The Manager",
        "employees" => [
          {
            "name"      => "Employee One",
            "customers" => [{"name" => "Customer One"}, {"name" => "Customer Two"}].to_json,
          },
          {"name" => "Employee Two", "customers" => "[]"},
        ].to_json,
      })

      SaveManagerWithCustomers.create(params) do |operation, manager|
        operation.valid?.should be_true
        operation.saved?.should be_true
        manager.should_not be_nil

        employees = Employee::BaseQuery.new.manager_id(manager.as(Manager).id).name.asc_order.results
        employees.map(&.name).should eq(["Employee One", "Employee Two"])

        employee_one = employees.find! { |employee| employee.name == "Employee One" }
        customers = Customer::BaseQuery.new.employee_id(employee_one.id).name.asc_order.results
        customers.map(&.name).should eq(["Customer One", "Customer Two"])
      end
    end
  end

  context "has_many nested inside has_many, submitted as a URL-encoded/multipart HTML form" do
    it "saves all three levels" do
      params = Avram::Params.new({
        "name"                           => "The Manager",
        "employees[0]:name"              => "Employee One",
        "employees[0]:customers[0]:name" => "Customer One",
        "employees[0]:customers[1]:name" => "Customer Two",
        "employees[1]:name"              => "Employee Two",
      })

      SaveManagerWithCustomers.create(params) do |operation, manager|
        operation.valid?.should be_true
        operation.saved?.should be_true
        manager.should_not be_nil

        employees = Employee::BaseQuery.new.manager_id(manager.as(Manager).id).name.asc_order.results
        employees.map(&.name).should eq(["Employee One", "Employee Two"])

        employee_one = employees.find! { |employee| employee.name == "Employee One" }
        customers = Customer::BaseQuery.new.employee_id(employee_one.id).name.asc_order.results
        customers.map(&.name).should eq(["Customer One", "Customer Two"])
      end
    end

    it "rolls back all three levels when a grandchild nested operation is invalid" do
      params = Avram::Params.new({
        "name"                           => "The Manager",
        "employees[0]:name"              => "Employee One",
        "employees[0]:customers[0]:name" => "",
      })

      SaveManagerWithCustomers.create(params) do |operation, manager|
        operation.saved?.should be_false
        manager.should be_nil
      end

      Manager::BaseQuery.new.name("The Manager").results.size.should eq(0)
      Employee::BaseQuery.new.name("Employee One").results.size.should eq(0)
      Customer::BaseQuery.new.results.size.should eq(0)
    end
  end

  context "has_one nested inside has_many, submitted as a URL-encoded/multipart HTML form" do
    it "saves the parent, the nested children, and each child's own nested operation" do
      params = Avram::Params.new({
        "title"                              => "My Post",
        "comments[0]:body"                   => "First",
        "comments[0]:comment_reaction:emoji" => "👍",
        "comments[1]:body"                   => "Second",
        "comments[1]:comment_reaction:emoji" => "😂",
      })

      SavePostWithReactedComments.create(params) do |operation, post|
        operation.valid?.should be_true
        operation.saved?.should be_true
        post.should_not be_nil

        comments = Comment::BaseQuery.new.post_id(post.as(Post).id).body.asc_order.results
        comments.map(&.body).should eq(["First", "Second"])

        first_comment = comments.find! { |comment| comment.body == "First" }
        second_comment = comments.find! { |comment| comment.body == "Second" }

        CommentReaction::BaseQuery.new.comment_id(first_comment.id).first.emoji.should eq("👍")
        CommentReaction::BaseQuery.new.comment_id(second_comment.id).first.emoji.should eq("😂")
      end
    end
  end

  context "has_many nested inside has_one, submitted as a URL-encoded/multipart HTML form" do
    it "saves the parent, the nested has_one child, and its own nested has_many children" do
      # `has_one` reuses the very same `Avram::Params` for its child (rather
      # than wrapping a new one per item, as `has_many` does), so the
      # `aliases` a `has_many` declared on that child reads its keys
      # directly off the top-level params -- not prefixed by "email_address:".
      params = Avram::Params.new({
        "name"                  => "Acme",
        "email_address:address" => "acme@example.com",
        "email_address:default" => "true",
        "aliases[0]:address"    => "alias1@example.com",
        "aliases[1]:address"    => "alias2@example.com",
      })

      SaveBusinessWithAliases.create(params) do |operation, business|
        operation.valid?.should be_true
        operation.saved?.should be_true
        business.should_not be_nil

        email_address = business.as(Business).email_address!
        aliases = EmailAlias::BaseQuery.new.email_address_id(email_address.id).address.asc_order.results
        aliases.map(&.address).should eq(["alias1@example.com", "alias2@example.com"])
      end
    end
  end
end
