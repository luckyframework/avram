class TaskFactory < BaseFactory
  def initialize
    title sequence("title")
  end
end
