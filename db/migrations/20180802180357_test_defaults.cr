class TestDefaults::V20180802180357 < Avram::Migrator::Migration::V1
  def migrate
    create :test_defaults do
      primary_key id : Int64
      add_timestamps
      add greeting : String, default: "Hello there!"
      add drafted_at : Time, default: :now
      add published_at : Time, default: 1.day.from_now
      add admin : Bool, default: false
      add age : Int32, default: 30
      add money : Float64, default: 3.5
    end
  end

  def rollback
    drop :test_defaults
  end
end
