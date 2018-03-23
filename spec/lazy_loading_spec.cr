require "./spec_helper"

include LazyLoadHelpers

describe "Lazy loading associations" do
  it "can lazy load has_many and has_many through" do
    post = PostBox.save
    comment = CommentBox.new.post_id(post.id).save
    tag = TagBox.save
    tagging = TaggingBox.new.post_id(post.id).tag_id(tag.id).save

    post.comments!.should eq([comment])
    post.tags!.should eq([tag])
  end

  it "can lazy load has_one" do
    admin = AdminBox.save
    sign_in_credential = SignInCredentialBox.new.user_id(admin.id).save
    admin.sign_in_credential!.should eq(sign_in_credential)
  end

  it "can lazy load optional has_one" do
    user = UserBox.save
    user.sign_in_credential!.should be_nil
  end

  it "can lazy load belongs_to" do
    post = PostBox.save
    comment = CommentBox.new.post_id(post.id).save
    comment.post!.should eq(post)
  end

  it "can lazy load optional belongs_to" do
    employee = EmployeeBox.save
    employee.manager!.should be_nil
  end
end
