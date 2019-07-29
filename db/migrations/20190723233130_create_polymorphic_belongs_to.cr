class CreatePolymorphicBelongsTo::V20190723233130 < Avram::Migrator::Migration::V1
  def migrate
    create table_for(PolymorphicTask) do
      primary_key id : Int64
      add_timestamps
      add title : String
    end

    create table_for(PolymorphicTaskList) do
      primary_key id : Int64
      add_timestamps
      add title : String
    end

    create table_for(PolymorphicEvent) do
      primary_key id : Int64
      add_timestamps
      add_belongs_to task : PolymorphicTask?, on_delete: :cascade
      add_belongs_to task_list : PolymorphicTaskList?, on_delete: :cascade
    end
  end

  def rollback
    drop table_for(PolymorphicEvent)
    drop table_for(PolymorphicTask)
    drop table_for(PolymorphicTaskList)
  end
end
