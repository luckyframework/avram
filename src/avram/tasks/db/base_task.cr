abstract class BaseTask < LuckyCli::Task
  abstract def run_task

  def call
    Avram::Migrator.run do
      run_task
    end
  end
end
