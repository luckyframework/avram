require "./spec_helper"

describe "Query associations" do
  it "can query associations" do
    post_with_matching_comment = PostBox.save
    matching_comment = CommentBox
      .new
      .body("matching")
      .post_id(post_with_matching_comment.id)
      .save
    post_without_matching_comment = PostBox.save
    CommentBox
      .new
      .body("not-matching")
      .post_id(post_with_matching_comment.id)
      .save

    posts = Post::BaseQuery.new.join_comments.comments(&.body.is("matching"))
    posts.results.should eq([post_with_matching_comment])

    posts = Post::BaseQuery.new.join_comments.comments(&.body("matching"))
    posts.results.should eq([post_with_matching_comment])
  end
end
