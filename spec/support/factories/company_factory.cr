class CompanyFactory < BaseFactory
  def initialize
    sales Int64::MAX
    earnings 1.0
  end
end
