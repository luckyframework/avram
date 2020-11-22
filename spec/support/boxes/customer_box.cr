class CustomerBox < Avram::Box
  def initialize
    name sequence("test-customer")
  end
end
