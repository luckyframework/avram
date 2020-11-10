abstract class BaseModel < Avram::Model
  def self.database : Avram::Database.class
    TestDatabase
  end
end
