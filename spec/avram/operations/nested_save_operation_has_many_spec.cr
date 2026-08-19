require "../../spec_helper"

private class SavePostWithComments < Post::SaveOperation
  class SaveComment < Comment::SaveOperation
    permit_columns body

    before_save :ensure_body_present

    private def ensure_body_present
      body.add_error("is required") if body.value.try(&.blank?)
    end
  end

  permit_columns title
  has_many comments : SaveComment
end

private class SavePostWithDestroyableComments < Post::SaveOperation
  class SaveComment < Comment::SaveOperation
    permit_columns body
  end

  permit_columns title
  has_many comments : SaveComment, allow_destroy: true
end

private class FakeManyNestedParams
  include Avram::Paramable
  @post : Hash(String, String)
  @comments : Array(Hash(String, String))

  def initialize(@post = {} of String => String, @comments = [] of Hash(String, String))
  end

  def nested(key : String) : Hash(String, String)
    nested?(key)
  end

  def nested?(key : String) : Hash(String, String)
    key == "post" ? @post : ({} of String => String)
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
    key == "comments" ? @comments : ([] of Hash(String, String))
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

describe "Avram::SaveOperation with has_many nested operation" do
  context "when creating" do
    it "saves the parent and all of the nested children" do
      params = FakeManyNestedParams.new(
        post: {"title" => "My Post"},
        comments: [{"body" => "First"}, {"body" => "Second"}]
      )

      SavePostWithComments.create(params) do |operation, post|
        operation.valid?.should be_true
        operation.saved?.should be_true
        post.should_not be_nil
        post = post.not_nil!

        comments = Comment::BaseQuery.new.post_id(post.id).body.asc_order.results
        comments.map(&.body).should eq(["First", "Second"])
        comments.each { |comment| comment.post_id.should eq(post.id) }
      end
    end

    it "creates zero children when none are given" do
      params = FakeManyNestedParams.new(post: {"title" => "No Comments"})

      SavePostWithComments.create(params) do |operation, post|
        operation.valid?.should be_true
        operation.saved?.should be_true
        post.should_not be_nil

        Comment::BaseQuery.new.post_id(post.not_nil!.id).results.size.should eq(0)
      end
    end

    it "rolls back everything when a nested child is invalid" do
      params = FakeManyNestedParams.new(
        post: {"title" => "My Post"},
        comments: [{"body" => "First"}, {"body" => ""}]
      )

      SavePostWithComments.create(params) do |operation, post|
        operation.valid?.should be_false
        operation.saved?.should be_false
        post.should be_nil
      end

      Post::BaseQuery.new.title("My Post").results.size.should eq(0)
      Comment::BaseQuery.new.body("First").results.size.should eq(0)
    end
  end

  context "when updating" do
    it "updates existing children (matched by id) and creates new ones" do
      post = PostFactory.create &.title("Original")
      existing_comment = CommentFactory.create &.post_id(post.id).body("Existing")

      params = FakeManyNestedParams.new(
        post: {"title" => "Updated"},
        comments: [
          {"id" => existing_comment.id.to_s, "body" => "Updated Existing"},
          {"body" => "Brand New"},
        ]
      )

      SavePostWithComments.update(post, params) do |operation, updated_post|
        operation.valid?.should be_true
        operation.saved?.should be_true
        updated_post.title.should eq("Updated")
      end

      comments = Comment::BaseQuery.new.post_id(post.id).body.asc_order.results
      comments.map(&.body).should eq(["Brand New", "Updated Existing"])
      comments.map(&.id).should contain(existing_comment.id)
    end

    it "rolls back everything when a nested child is invalid" do
      post = PostFactory.create &.title("Original")
      existing_comment = CommentFactory.create &.post_id(post.id).body("Existing")

      params = FakeManyNestedParams.new(
        post: {"title" => "Updated"},
        comments: [
          {"id" => existing_comment.id.to_s, "body" => ""},
        ]
      )

      SavePostWithComments.update(post, params) do |operation, updated_post|
        operation.valid?.should be_false
        operation.saved?.should be_false
      end

      post.reload.title.should eq("Original")
      existing_comment.reload.body.should eq("Existing")
    end
  end

  context "with allow_destroy" do
    it "deletes children marked with a truthy _destroy" do
      post = PostFactory.create &.title("Original")
      comment_to_keep = CommentFactory.create &.post_id(post.id).body("Keep me")
      comment_to_delete = CommentFactory.create &.post_id(post.id).body("Delete me")

      params = FakeManyNestedParams.new(
        post: {"title" => "Original"},
        comments: [
          {"id" => comment_to_keep.id.to_s, "body" => "Keep me"},
          {"id" => comment_to_delete.id.to_s, "_destroy" => "true"},
        ]
      )

      SavePostWithDestroyableComments.update(post, params) do |operation, _updated_post|
        operation.valid?.should be_true
        operation.saved?.should be_true
      end

      remaining = Comment::BaseQuery.new.post_id(post.id).results
      remaining.map(&.id).should eq([comment_to_keep.id])
      Comment::BaseQuery.new.custom_id(comment_to_delete.id).results.size.should eq(0)
    end
  end
end
