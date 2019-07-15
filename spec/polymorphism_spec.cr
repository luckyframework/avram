require "./spec_helper.cr"

private class CommentForm < Comment::SaveOperation
end

describe "Avram::Polymorphism" do
  it "allows to create (and return) polymorphic relationships" do
    post = PostBox.create
    company = CompanyBox.create
    employee = EmployeeBox.create

    comment1 = CommentBox.create &.post_id(post.id).body("Comment 1")
    CommentForm.update!(comment1, commentable_type: "Company", commentable_id: company.id)

    comment2 = CommentBox.create &.post_id(post.id).body("Comment 2")
    CommentForm.update!(comment2, commentable_type: "Company", commentable_id: company.id)

    comment3 = CommentBox.create &.post_id(post.id).body("Comment 3")
    CommentForm.update!(comment3, commentable_type: "Employee", commentable_id: employee.id)

    company.comments.map(&.id).each do |id|
      [comment1.id, comment2.id].should contain(id)
    end
    employee.comments.map(&.id).should eq([comment3.id])
  end

  it "returns error for invalid comment_type" do
    post = PostBox.create
    company = CompanyBox.create

    comment1 = CommentBox.create &.post_id(post.id).body("Comment 1")

    expect_raises Avram::InvalidSaveOperationError, "commentable_type: is invalid" do
      CommentForm.update!(comment1, commentable_type: "Foo", commentable_id: 1)
    end

    expect_raises Avram::InvalidSaveOperationError, "commentable_type: is required, is invalid" do
      CommentForm.update!(comment1, commentable_type: "", commentable_id: 1)
    end
  end

  it "returns the right models for the collection" do
    post = PostBox.create
    company = CompanyBox.create
    employee = EmployeeBox.create

    comment1 = CommentBox.create &.post_id(post.id).body("Comment 1")
    CommentForm.update!(comment1, commentable_type: "Company", commentable_id: company.id)

    comment2 = CommentBox.create &.post_id(post.id).body("Comment 2")
    CommentForm.update!(comment2, commentable_type: "Company", commentable_id: company.id)

    comment3 = CommentBox.create &.post_id(post.id).body("Comment 3")
    CommentForm.update!(comment3, commentable_type: "Employee", commentable_id: employee.id)

    expected_commentables = [
      {comment_id: comment1.id, klass: "Company", id: company.id},
      {comment_id: comment2.id, klass: "Company", id: company.id},
      {comment_id: comment3.id, klass: "Employee", id: employee.id},
    ]

    result = Comment::BaseQuery.all.map do |comment|
      el = nil
      if commentable = comment.commentable
        if commentable.responds_to?(:id)
          el = {comment_id: comment.id, klass: commentable.class.to_s, id: commentable.id}
        end
      end
      el
    end

    result.should eq(expected_commentables)
  end

  it "can be optional or not" do
    post = PostBox.create

    # Optional Allows Nil Values
    comment = CommentForm.create!(
      post_id: post.id.to_i64, body: "Comment 1",
      commentable_id: 1_i64, commentable_type: "Company",
      optional_commentable_id: nil, optional_commentable_type: nil
    )
    comment.optional_commentable.class.should eq(Nil)
  end
end
