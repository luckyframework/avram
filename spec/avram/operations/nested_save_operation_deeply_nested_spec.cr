require "../../spec_helper"

# These specs verify that nested `SaveOperation`s can be nested arbitrarily
# deep -- i.e. a `has_one`/`has_many` nested operation can itself declare
# its own `has_one`/`has_many` nested operation, for every combination of
# `has_one`/`has_many` at each level.

private class SaveBusinessWithDomainRecord < Business::SaveOperation
  class SaveEmailAddress < EmailAddress::SaveOperation
    class SaveEmailDomainRecord < EmailDomainRecord::SaveOperation
      permit_columns verified
    end

    permit_columns address, default
    has_one domain_record : SaveEmailDomainRecord
  end

  permit_columns name
  has_one email_address : SaveEmailAddress
end

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

# A generic, reusable fake `Avram::Paramable` implementation for exercising
# any combination of nested `has_one` (via `nested`/`nested?`) and nested
# `has_many` (via `many_nested`/`many_nested?`) associations, keyed by the
# same param key each level's `SaveOperation` looks itself up by (for
# `has_one`, that's the child model's underscored name; for `has_many`,
# that's the declared association name -- see
# `Avram::NestedSaveOperation`).
private class FakeDeeplyNestedParams
  include Avram::Paramable

  def initialize(
    @nested_data = {} of String => Hash(String, String),
    @many_nested_data = {} of String => Array(Hash(String, String)),
  )
  end

  def nested(key : String) : Hash(String, String)
    nested?(key)
  end

  def nested?(key : String) : Hash(String, String)
    @nested_data[key]? || ({} of String => String)
  end

  def nested_arrays(key : String) : Hash(String, Array(String))
    nested_arrays?(key)
  end

  def nested_arrays?(key : String) : Hash(String, Array(String))
    {} of String => Array(String)
  end

  def nested_file(key : String) : Hash(String, String)
    nested(key)
  end

  def nested_file?(key : String) : Hash(String, String)
    nested?(key)
  end

  def many_nested(key : String) : Array(Hash(String, String))
    many_nested?(key)
  end

  def many_nested?(key : String) : Array(Hash(String, String))
    @many_nested_data[key]? || ([] of Hash(String, String))
  end

  def get(key : String)
    get?(key)
  end

  def get?(key : String)
    nil
  end

  def get_all(key : String)
    get_all?(key)
  end

  def get_all?(key : String)
    nil
  end
end

describe "Avram::SaveOperation with deeply nested operations" do
  context "has_one nested inside has_one nested inside has_one" do
    it "saves all three levels" do
      params = FakeDeeplyNestedParams.new(nested_data: {
        "business"            => {"name" => "Acme"},
        "email_address"       => {"address" => "acme@example.com", "default" => "true"},
        "email_domain_record" => {"verified" => "true"},
      })

      SaveBusinessWithDomainRecord.create(params) do |operation, business|
        operation.valid?.should be_true
        operation.saved?.should be_true
        business.should_not be_nil

        email_address = business.as(Business).email_address!
        email_address.address.should eq("acme@example.com")

        domain_record = EmailDomainRecord::BaseQuery.new.email_address_id(email_address.id).first
        domain_record.verified.should be_true
      end
    end

    it "rolls back all three levels when the deepest nested operation is invalid" do
      params = FakeDeeplyNestedParams.new(nested_data: {
        "business"      => {"name" => "Acme"},
        "email_address" => {"address" => "acme@example.com", "default" => "true"},
        # missing "verified" is fine (has a default), so force a failure manually below
      })

      operation = SaveBusinessWithDomainRecord.new(params)
      operation.email_address.domain_record.verified.add_error("failed on purpose")
      operation.save

      operation.saved?.should be_false
      Business::BaseQuery.new.name("Acme").results.size.should eq(0)
      EmailAddress::BaseQuery.new.address("acme@example.com").results.size.should eq(0)
      EmailDomainRecord::BaseQuery.new.results.size.should eq(0)
    end
  end

  context "has_many nested inside has_many nested inside has_many" do
    it "saves all three levels" do
      params = FakeDeeplyNestedParams.new(nested_data: {
        "manager" => {"name" => "The Manager"},
      }, many_nested_data: {
        "employees" => [
          {
            "name"      => "Employee One",
            "customers" => [{"name" => "Customer One"}, {"name" => "Customer Two"}].to_json,
          },
          {
            "name"      => "Employee Two",
            "customers" => "[]",
          },
        ],
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
      params = FakeDeeplyNestedParams.new(nested_data: {
        "manager" => {"name" => "The Manager"},
      }, many_nested_data: {
        "employees" => [
          {
            "name"      => "Employee One",
            "customers" => [{"name" => ""}].to_json,
          },
        ],
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

  context "has_one nested inside has_many" do
    it "saves the parent, the nested children, and each child's own nested operation" do
      params = FakeDeeplyNestedParams.new(many_nested_data: {
        "comments" => [
          {
            "body"             => "First",
            "comment_reaction" => {"emoji" => "👍"}.to_json,
          },
          {
            "body"             => "Second",
            "comment_reaction" => {"emoji" => "😂"}.to_json,
          },
        ],
      }, nested_data: {
        "post" => {"title" => "My Post"},
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

    it "rolls back everything when a comment's own nested reaction is invalid" do
      params = FakeDeeplyNestedParams.new(many_nested_data: {
        "comments" => [
          {
            "body"             => "First",
            "comment_reaction" => {"emoji" => ""}.to_json,
          },
        ],
      }, nested_data: {
        "post" => {"title" => "My Post"},
      })

      SavePostWithReactedComments.create(params) do |operation, post|
        operation.saved?.should be_false
        post.should be_nil
      end

      Post::BaseQuery.new.title("My Post").results.size.should eq(0)
      Comment::BaseQuery.new.body("First").results.size.should eq(0)
      CommentReaction::BaseQuery.new.results.size.should eq(0)
    end
  end

  context "has_many nested inside has_one" do
    it "saves the parent, the nested has_one child, and its own nested has_many children" do
      params = FakeDeeplyNestedParams.new(nested_data: {
        "business"      => {"name" => "Acme"},
        "email_address" => {"address" => "acme@example.com", "default" => "true"},
      }, many_nested_data: {
        "aliases" => [{"address" => "alias1@example.com"}, {"address" => "alias2@example.com"}],
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

    it "rolls back everything when a nested alias is invalid" do
      params = FakeDeeplyNestedParams.new(nested_data: {
        "business"      => {"name" => "Acme"},
        "email_address" => {"address" => "acme@example.com", "default" => "true"},
      }, many_nested_data: {
        "aliases" => [{"address" => ""}],
      })

      SaveBusinessWithAliases.create(params) do |operation, business|
        operation.saved?.should be_false
        business.should be_nil
      end

      Business::BaseQuery.new.name("Acme").results.size.should eq(0)
      EmailAddress::BaseQuery.new.address("acme@example.com").results.size.should eq(0)
      EmailAlias::BaseQuery.new.results.size.should eq(0)
    end
  end
end
