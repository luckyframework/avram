require "../../spec_helper"

include ParamHelper

private class TestSaveIssue < Issue::SaveOperation
  permit_columns role, status, permissions
end

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

  it "can use Int values from params" do
    params = build_params("issue:role=3&issue:status=0&issue:permissions=2")
    TestSaveIssue.create!(params)

    issue = IssueQuery.new.first
    issue.role.should eq(Issue::Role::Critical)
    issue.status.should eq(Issue::Status::Opened)
    issue.permissions.includes?(Issue::Permissions::Read).should eq(false)
    issue.permissions.includes?(Issue::Permissions::Write).should eq(true)
  end

  it "can use String values from params" do
    params = build_params("issue:role=Critical&issue:status=Opened")
    TestSaveIssue.create!(params)

    issue = IssueQuery.new.first
    issue.role.should eq(Issue::Role::Critical)
    issue.status.should eq(Issue::Status::Opened)
  end
end
