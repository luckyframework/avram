class IssueFactory < BaseFactory
  def initialize
    status Issue::Status::Opened
    permissions Issue::Permissions::Read
  end

  def build_model
    Issue.new(
      id: 123_i64,
      status: 0,
      role: 0,
      permissions: 3_i64
    )
  end
end
