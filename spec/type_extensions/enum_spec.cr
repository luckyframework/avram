require "../spec_helper"

include LazyLoadHelpers

describe Enum do
  it "check enum" do
    issue = IssueFactory.create

    issue.status.should eq(Issue::Status::Opened)
    issue.role.should eq(Issue::Role::Issue)
  end

  it "update enum" do
    issue = IssueFactory.create

    updated_issue = Issue::SaveOperation.update!(issue, status: Issue::Status.new(:closed))

    updated_issue.status.should eq(Issue::Status::Closed)
    updated_issue.role.should eq(Issue::Role::Issue)
  end

  it "access enum methods" do
    issue = IssueFactory.create

    issue.status.opened?.should eq(true)
    issue.status.value.should eq(0)
  end

  it "access enum to_s and to_i" do
    issue = IssueFactory.create

    issue.status.to_s.should eq("Opened")
    issue.status.to_i.should eq(0)
  end
end
