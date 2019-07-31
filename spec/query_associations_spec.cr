require "./spec_helper"

# Ensure it works with inherited query classes
class CommentQuery < Comment::BaseQuery
  def body_eq(value)
    body.eq(value)
  end
end

class NamedSpaced::Organization < BaseModel
  table do
    has_many locations : Location
  end
end

class NamedSpaced::Location < BaseModel
  table do
    column name : String
    belongs_to organization : Organization
  end
end

describe "Query associations" do
  it "can query associations" do
    post_with_matching_comment = PostBox.create
    matching_comment = CommentBox
      .new
      .body("matching")
      .post_id(post_with_matching_comment.id)
      .create

    post_without_matching_comment = PostBox.create
    CommentBox
      .new
      .body("not-matching")
      .post_id(post_without_matching_comment.id)
      .create

    posts = Post::BaseQuery.new
      .where_comments(CommentQuery.new.body_eq("matching"))
    posts.results.should eq([post_with_matching_comment])

    posts = Post::BaseQuery.new
      .where_comments(Comment::BaseQuery.new.body("matching"))
    posts.results.should eq([post_with_matching_comment])
  end

  it "can query associations with inner_join specified" do
    post_with_matching_comment = PostBox.create
    matching_comment = CommentBox
      .new
      .body("matching")
      .post_id(post_with_matching_comment.id)
      .create

    post_without_matching_comment = PostBox.create
    CommentBox
      .new
      .body("not-matching")
      .post_id(post_without_matching_comment.id)
      .create

    posts = Post::BaseQuery.new
      .inner_join_comments
      .where_comments(Comment::BaseQuery.new.body.eq("matching"), auto_inner_join: false)
    posts.to_sql[0].should contain "INNER JOIN"
    posts.results.should eq([post_with_matching_comment])
  end

  it "can query associations with left_join specified" do
    post_with_matching_comment = PostBox.create
    matching_comment = CommentBox
      .new
      .body("matching")
      .post_id(post_with_matching_comment.id)
      .create

    post_without_matching_comment = PostBox.create
    CommentBox
      .new
      .body("not-matching")
      .post_id(post_without_matching_comment.id)
      .create

    posts = Post::BaseQuery.new
      .left_join_comments
      .where_comments(Comment::BaseQuery.new.body.eq("matching"), auto_inner_join: false)
    posts.to_sql[0].should contain "LEFT JOIN"
    posts.results.should eq([post_with_matching_comment])
  end

  it "can query associations with right_join specified" do
    post_with_matching_comment = PostBox.create
    matching_comment = CommentBox
      .new
      .body("matching")
      .post_id(post_with_matching_comment.id)
      .create

    post_without_matching_comment = PostBox.create
    CommentBox
      .new
      .body("not-matching")
      .post_id(post_without_matching_comment.id)
      .create

    posts = Post::BaseQuery.new
      .right_join_comments
      .where_comments(Comment::BaseQuery.new.body.eq("matching"), auto_inner_join: false)
    posts.to_sql[0].should contain "RIGHT JOIN"
    posts.results.should eq([post_with_matching_comment])
  end

  it "can query associations with full_join specified" do
    post_with_matching_comment = PostBox.create
    matching_comment = CommentBox
      .new
      .body("matching")
      .post_id(post_with_matching_comment.id)
      .create

    post_without_matching_comment = PostBox.create
    CommentBox
      .new
      .body("not-matching")
      .post_id(post_without_matching_comment.id)
      .create

    posts = Post::BaseQuery.new
      .full_join_comments
      .where_comments(Comment::BaseQuery.new.body.eq("matching"), auto_inner_join: false)
    posts.to_sql[0].should contain "FULL JOIN"
    posts.results.should eq([post_with_matching_comment])
  end

  it "can query associations on namespaced models" do
    orgs = NamedSpaced::Organization::BaseQuery.new
      .where_locations(NamedSpaced::Location::BaseQuery.new.name("Home"))
    orgs.to_sql[0].should contain "INNER JOIN"
  end
end
