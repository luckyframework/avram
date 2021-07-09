require "../spec_helper"

include LazyLoadHelpers

describe "models using enums" do
  it "can be created" do
    issue = IssueFactory.create

    issue.status.should eq(Issue::Status::Opened)
    issue.role.should eq(Issue::Role::Issue)
  end

  it "can be updated" do
    issue = IssueFactory.create

    updated_issue = Issue::SaveOperation.update!(issue, status: Issue::Status.new(:closed))

    updated_issue.status.should eq(Issue::Status::Closed)
    updated_issue.role.should eq(Issue::Role::Issue)
  end

  it "can be queried" do
    issue = IssueFactory.create
    query = IssueQuery.new

    query.status(Issue::Status::Opened).first.should eq(issue)
    query.status("Opened").first.should eq(issue)
    query.status(0).first.should eq(issue)
  end

  it "handles other queries" do
    IssueFactory.create &.role(Issue::Role::Issue)
    IssueFactory.create &.role(Issue::Role::Critical)

    IssueQuery.new.role.select_max.should eq(Issue::Role::Critical)
    IssueQuery.new.role.select_min.should eq(Issue::Role::Issue)
  end
end
