abstract class BaseModel < Avram::Model
  def self.database
    TestDatabase
  end
end
