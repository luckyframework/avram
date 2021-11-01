module Avram::MarkAsFailed
  def mark_as_failed
    self.save_status = Avram::SaveOperation::OperationStatus::SaveFailed
  end
end
