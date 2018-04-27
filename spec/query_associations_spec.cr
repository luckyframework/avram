require "./spec_helper"

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
      .post_id(post_with_matching_comment.id)
      .create

    posts = Post::BaseQuery.new.join_comments.comments(&.body.is("matching"))
    posts.results.should eq([post_with_matching_comment])

    posts = Post::BaseQuery.new.join_comments.comments(&.body("matching"))
    posts.results.should eq([post_with_matching_comment])
  end
end
