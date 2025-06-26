class TokenFactory < BaseFactory
  def initialize
    name "Secret"
    scopes ["email"]
    next_id 0
  end
end
