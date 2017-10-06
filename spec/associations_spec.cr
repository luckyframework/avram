require "./spec_helper"

describe LuckyRecord::Model do
  it "gets the related records" do
    post = PostBox.save
    comment = CommentBox.new.post_id(post.id).save

    post = Post::BaseQuery.new.find(post.id)

    post.comments.to_a.should eq [comment]
    comment.post.should eq post
  end
end
