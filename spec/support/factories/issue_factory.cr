class IssueFactory < BaseFactory
  def initialize
    status Issue::Status.new(:opened)
    role Issue::Role.new(:issue)
  end

  def build_model
    Issue.new(
      id: 123_i64,
      status: 0,
      role: 0
    )
  end
end
