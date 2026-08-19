require "../../spec_helper"
include ContextHelper

# These specs verify the *rendering* side of nested (`has_one`/`has_many`)
# `SaveOperation`s: that each nested operation instance carries the
# correct instance-level `Avram::ParamKeyOverride#param_key` (and
# `#nested_param_key_prefix`), so the Lucky form helpers (`text_input`,
# etc.) generate the exact `name=`/`id=` that
# `Avram::Params`/`Lucky::Params` already know how to decode back on
# submission -- with values correctly pre-filled for both a brand-new
# operation and an edit operation seeded from persisted associations.
#
# This complements (and is intentionally separate from) the
# parsing-focused `nested_save_operation_*_spec.cr` files, which don't
# assert on any rendered HTML.

private class SaveBusinessWithEmail < Business::SaveOperation
  class SaveEmailAddress < EmailAddress::SaveOperation
    permit_columns address
  end

  permit_columns name
  has_one email_address : SaveEmailAddress
end

private class SavePostWithComments < Post::SaveOperation
  class SaveComment < Comment::SaveOperation
    permit_columns body
  end

  permit_columns title
  has_many comments : SaveComment
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

private class RenderingTestPage
  include Lucky::HTMLPage

  def render
  end
end

private def view(&)
  RenderingTestPage.new(build_context).tap do |page|
    yield page
  end.view.to_s
end

describe "rendering nested SaveOperations" do
  context "has_one" do
    it "renders a blank/new operation's field under the model-derived key" do
      operation = SaveBusinessWithEmail.new(Avram::Params.new)

      html = view(&.text_input(operation.email_address.address))
      html.should contain %(name="email_address:address")
      html.should contain %(id="email_address_address")
      html.should contain %(value="")
    end

    it "pre-fills from the existing associated record on an edit operation" do
      business = BusinessFactory.create
      EmailAddressFactory.create &.business_id(business.id).address("existing@example.com")

      operation = SaveBusinessWithEmail.new(business)

      html = view(&.text_input(operation.email_address.address))
      html.should contain %(name="email_address:address")
      html.should contain %(id="email_address_address")
      html.should contain %(value="existing@example.com")
    end
  end

  context "has_many" do
    it "renders each submitted item under its own indexed key" do
      params = Avram::Params.new({
        "title"             => "My Post",
        "comments[0]:body" => "First",
        "comments[1]:body" => "Second",
      })
      operation = SavePostWithComments.new(params)
      comments = operation.comments
      comments.size.should eq(2)

      html0 = view(&.text_input(comments[0].body))
      html0.should contain %(name="comments[0]:body")
      html0.should contain %(id="comments_0_body")
      html0.should contain %(value="First")

      html1 = view(&.text_input(comments[1].body))
      html1.should contain %(name="comments[1]:body")
      html1.should contain %(id="comments_1_body")
      html1.should contain %(value="Second")
    end

    it "pre-fills one item per existing associated record on an edit operation with no submitted params" do
      post = PostFactory.create &.title("Original")
      CommentFactory.create &.post_id(post.id).body("Existing One")
      CommentFactory.create &.post_id(post.id).body("Existing Two")

      operation = SavePostWithComments.new(post)
      comments = operation.comments
      comments.size.should eq(2)
      comments.map(&.body.value).to_set.should eq(Set{"Existing One", "Existing Two"})

      comments.each_with_index do |comment, index|
        html = view(&.text_input(comment.body))
        html.should contain %(name="comments[#{index}]:body")
        html.should contain %(id="comments_#{index}_body")
        html.should contain %(value="#{comment.body.value}")
      end
    end

    it "renders a blank hidden nested_id_input for a brand-new (unpersisted) item" do
      params = Avram::Params.new({
        "title"            => "My Post",
        "comments[0]:body" => "First",
      })
      operation = SavePostWithComments.new(params)
      comment = operation.comments.first

      html = view(&.nested_id_input(comment))
      html.should contain %(type="hidden")
      html.should contain %(name="comments[0]:id")
      html.should contain %(value="")
    end

    it "renders a populated hidden nested_id_input for an existing associated record" do
      post = PostFactory.create &.title("Original")
      comment = CommentFactory.create &.post_id(post.id).body("Existing")

      operation = SavePostWithComments.new(post)
      rendered_comment = operation.comments.first

      html = view(&.nested_id_input(rendered_comment))
      html.should contain %(type="hidden")
      html.should contain %(name="comments[0]:id")
      html.should contain %(value="#{comment.id}")
    end
  end

  context "has_one nested inside has_many" do
    it "renders each item's own nested field under a combined key" do
      params = Avram::Params.new({
        "title"                              => "My Post",
        "comments[0]:body"                   => "First",
        "comments[0]:comment_reaction:emoji" => "👍",
        "comments[1]:body"                   => "Second",
        "comments[1]:comment_reaction:emoji" => "😂",
      })
      operation = SavePostWithReactedComments.new(params)
      comments = operation.comments

      html0 = view(&.text_input(comments[0].reaction.emoji))
      html0.should contain %(name="comments[0]:comment_reaction:emoji")
      html0.should contain %(id="comments_0_comment_reaction_emoji")
      html0.should contain %(value="👍")

      html1 = view(&.text_input(comments[1].reaction.emoji))
      html1.should contain %(name="comments[1]:comment_reaction:emoji")
      html1.should contain %(id="comments_1_comment_reaction_emoji")
      html1.should contain %(value="😂")
    end

    it "pre-fills each item's nested field from its existing associated record on an edit operation" do
      post = PostFactory.create &.title("Original")
      comment = CommentFactory.create &.post_id(post.id).body("Existing")
      CommentReactionFactory.create &.comment_id(comment.id).emoji("🎉")

      operation = SavePostWithReactedComments.new(post)
      comments = operation.comments
      comments.size.should eq(1)

      html = view(&.text_input(comments[0].reaction.emoji))
      html.should contain %(name="comments[0]:comment_reaction:emoji")
      html.should contain %(id="comments_0_comment_reaction_emoji")
      html.should contain %(value="🎉")
    end
  end

  context "has_many nested inside has_many" do
    it "renders each grandchild item under a fully combined indexed key" do
      params = Avram::Params.new({
        "name"                            => "The Manager",
        "employees[0]:name"               => "Employee One",
        "employees[0]:customers[0]:name"  => "Customer One",
        "employees[0]:customers[1]:name"  => "Customer Two",
        "employees[1]:name"               => "Employee Two",
        "employees[1]:customers[0]:name"  => "Customer Three",
      })
      operation = SaveManagerWithCustomers.new(params)
      employees = operation.employees
      employees.size.should eq(2)

      employee0_customers = employees[0].customers
      html0 = view(&.text_input(employee0_customers[0].name))
      html0.should contain %(name="employees[0]:customers[0]:name")
      html0.should contain %(id="employees_0_customers_0_name")
      html0.should contain %(value="Customer One")

      html1 = view(&.text_input(employee0_customers[1].name))
      html1.should contain %(name="employees[0]:customers[1]:name")
      html1.should contain %(id="employees_0_customers_1_name")
      html1.should contain %(value="Customer Two")

      employee1_customers = employees[1].customers
      html2 = view(&.text_input(employee1_customers[0].name))
      html2.should contain %(name="employees[1]:customers[0]:name")
      html2.should contain %(id="employees_1_customers_0_name")
      html2.should contain %(value="Customer Three")
    end

    it "pre-fills every level from existing associated records on an edit operation" do
      manager = ManagerFactory.create &.name("The Manager")
      employee = EmployeeFactory.create &.manager_id(manager.id).name("Employee One")
      CustomerFactory.create &.employee_id(employee.id).name("Customer One")

      operation = SaveManagerWithCustomers.new(manager)
      employees = operation.employees
      employees.size.should eq(1)

      customers = employees[0].customers
      customers.size.should eq(1)

      html = view(&.text_input(customers[0].name))
      html.should contain %(name="employees[0]:customers[0]:name")
      html.should contain %(id="employees_0_customers_0_name")
      html.should contain %(value="Customer One")
    end
  end
end
