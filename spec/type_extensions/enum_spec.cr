require "../spec_helper"

include LazyLoadHelpers

describe "Enum" do
  it "parses String enum" do
    Issue::Status::Lucky.parse("1").value.should eq(Issue::Status.new(Issue::AvramStatus::Closed))
  end

  it "parses empty String enum" do
    Issue::Status::Lucky.parse("").should be_a(Avram::Type::SuccessfulCast(Nil))
  end

  it "checks enum" do
    issue = IssueBox.create

    issue.status.enum.should eq(Issue::AvramStatus::Opened)
    issue.role.enum.should eq(Issue::AvramRole::Issue)
  end

  it "updates enum" do
    issue = IssueBox.create

    updated_issue = Issue::SaveOperation.update!(issue, status: Issue::Status.new(:closed))

    updated_issue.status.enum.should eq(Issue::AvramStatus::Closed)
    updated_issue.role.enum.should eq(Issue::AvramRole::Issue)
  end

  it "accesses enum methods" do
    issue = IssueBox.create

    issue.status.opened?.should eq(true)
    issue.status.value.should eq(0)
  end

  it "access enum to_s and to_i" do
    issue = IssueBox.create

    issue.status.to_s.should eq("Opened")
    issue.status.to_i.should eq(0)
  end
end
