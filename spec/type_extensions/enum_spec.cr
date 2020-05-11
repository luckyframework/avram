require "../spec_helper"

include LazyLoadHelpers

describe "Enum" do
  it "check enum" do
    issue = IssueBox.create

    issue.status.enum.should eq(Issue::AvramStatus::Opened)
    issue.role.enum.should eq(Issue::AvramRole::Issue)
  end

  it "update enum" do
    issue = IssueBox.create

    updated_issue = Issue::SaveOperation.update!(issue, status: Issue::Status.new(:closed))

    updated_issue.status.enum.should eq(Issue::AvramStatus::Closed)
    updated_issue.role.enum.should eq(Issue::AvramRole::Issue)
  end

  it "access enum methods" do
    issue = IssueBox.create

    issue.status.opened?.should eq(true)
    issue.status.value.should eq(0)
  end
end
