class IssueBox < BaseBox
  def initialize
    status Issue::AvramStatus.new(0)
    role Issue::AvramRole.new(0)
  end

  def build_model
    Issue.new(
      id: 123_i64,
      status: 0,
      role: 0
    )
  end
end
