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

    posts = Post::BaseQuery.new.join_comments.comments(&.body.eq("matching"))
    posts.results.should eq([post_with_matching_comment])

    posts = Post::BaseQuery.new.join_comments.comments(&.body("matching"))
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
      .post_id(post_with_matching_comment.id)
      .create

    posts = Post::BaseQuery.new.inner_join_comments.comments(&.body.eq("matching"))
    posts.to_sql[0].should contain "INNER JOIN"
    posts.results.should eq([post_with_matching_comment])

    posts = Post::BaseQuery.new.inner_join_comments.comments(&.body("matching"))
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
      .post_id(post_with_matching_comment.id)
      .create

    posts = Post::BaseQuery.new.left_join_comments.comments(&.body.eq("matching"))
    posts.to_sql[0].should contain "LEFT JOIN"
    posts.results.should eq([post_with_matching_comment])

    posts = Post::BaseQuery.new.left_join_comments.comments(&.body("matching"))
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
      .post_id(post_with_matching_comment.id)
      .create

    posts = Post::BaseQuery.new.right_join_comments.comments(&.body.eq("matching"))
    posts.to_sql[0].should contain "RIGHT JOIN"
    posts.results.should eq([post_with_matching_comment])

    posts = Post::BaseQuery.new.right_join_comments.comments(&.body("matching"))
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
      .post_id(post_with_matching_comment.id)
      .create

    posts = Post::BaseQuery.new.full_join_comments.comments(&.body.eq("matching"))
    posts.to_sql[0].should contain "FULL JOIN"
    posts.results.should eq([post_with_matching_comment])

    posts = Post::BaseQuery.new.full_join_comments.comments(&.body("matching"))
    posts.to_sql[0].should contain "FULL JOIN"
    posts.results.should eq([post_with_matching_comment])
  end
end
