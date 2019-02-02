module Avram::MarkAsFailed
  def mark_as_failed
    self.save_status = Avram::Form::SaveStatus::SaveFailed
  end
end
