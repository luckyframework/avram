require "../spec_helper"

include LazyLoadHelpers

describe "Enum" do
  it "check enum" do
    issue = IssueBox.create

    issue.status.value.should eq(Issue::AvramStatus::Opened)
    issue.role.value.should eq(Issue::AvramRole::Issue)
  end

  it "update enum" do
    issue = IssueBox.create

    updated_issue = Issue::SaveOperation.update!(issue, status: Issue::Status.new(:closed))

    updated_issue.status.value.should eq(Issue::AvramStatus::Closed)
    updated_issue.role.value.should eq(Issue::AvramRole::Issue)
  end
end
