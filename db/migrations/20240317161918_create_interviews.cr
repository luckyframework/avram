class CreateInterviews::V20240317161918 < Avram::Migrator::Migration::V1
  def migrate
    create table_for(Interview) do
      primary_key id : Int64
      add_timestamps
      add_belongs_to interviewer : User, on_delete: :cascade
      add_belongs_to interviewee : User, on_delete: :cascade
    end
  end

  def rollback
    drop table_for(Interview)
  end
end
