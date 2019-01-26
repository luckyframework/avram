class Db::Create < LuckyCli::Task
  summary "Create the database"

  def initialize(@quiet : Bool = false)
  end

  def call
    LuckyRecord::Migrator.run do
      LuckyRecord::Migrator::Runner.create_db(@quiet)
    end
  end
end
