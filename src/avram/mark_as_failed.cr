module Avram::MarkAsFailed
  def mark_as_failed
    self.save_status = Avram::SaveOperation::SaveStatus::SaveFailed
  end
end
