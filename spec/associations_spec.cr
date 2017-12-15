require "./spec_helper"

describe LuckyRecord::Model do
  it "gets the related records" do
    post = PostBox.save
    comment = CommentBox.new.post_id(post.id).save

    post = Post::BaseQuery.new.find(post.id)

    post.comments.to_a.should eq [comment]
    comment.post.should eq post
  end

  it "gets the related records for nilable association that exists" do
    manager = ManagerBox.save
    employee = EmployeeBox.new.manager_id(manager.id).save

    manager = Manager::BaseQuery.new.find(manager.id)

    manager.employees.to_a.should eq [employee]
    employee.manager.should eq manager
  end

  it "returns nil for nilable association that doesn't exist" do
    employee = EmployeeBox.new.save
    employee.manager.should eq nil
  end
end
