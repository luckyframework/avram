module Avram::MarkAsFailed
  def mark_as_failed : Nil
    self.save_status = Avram::SaveOperation::OperationStatus::SaveFailed
  end
end
