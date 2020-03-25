class IssueBox < BaseBox
  def initialize
    status Issue::AvramStatus.new(:opened)
    role Issue::AvramRole.new(:issue)
  end

  def build_model
    Issue.new(
      id: 123_i64,
      status: 0,
      role: 0
    )
  end
end
