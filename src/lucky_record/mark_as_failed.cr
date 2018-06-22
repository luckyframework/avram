module LuckyRecord::MarkAsFailed
  def mark_as_failed
    self.save_status = LuckyRecord::Form::SaveStatus::SaveFailed
  end
end
