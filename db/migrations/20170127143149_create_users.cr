class CreateUsers::V20170127143149 < Avram::Migrator::Migration::V1
  def migrate
    create :users do
      primary_key id : Int64
      add_timestamps
      add name : String
      add nickname : String?
      add age : Int32
      add year_born : Int16?
      add joined_at : Time
      add total_score : Int64?
      add average_score : Float64?
      add available_for_hire : Bool?
    end
  end

  def rollback
    drop :users
  end
end
