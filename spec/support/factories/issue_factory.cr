class IssueFactory < BaseFactory
  def initialize
    status Issue::Status::Opened
  end

  def build_model
    Issue.new(
      id: 123_i64,
      status: 0,
      role: 0
    )
  end
end
