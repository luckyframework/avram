require "../spec_helper"

include LazyLoadHelpers

describe "Enum" do
  it "check enum" do
    issue = IssueBox.create

    issue.status.value.should eq(Issue::Status::Opened)
    issue.role.value.should eq(Issue::Role::Issue)
  end

  it "update enum" do
    issue = IssueBox.create

    updated_issue = Issue::SaveOperation.update!(issue, status: Issue::AvramStatus.new(:closed))

    updated_issue.status.value.should eq(Issue::Status::Closed)
    updated_issue.role.value.should eq(Issue::Role::Issue)
  end
end
