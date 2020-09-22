module Avram::OperationSaveStatus
  macro included
    enum SaveStatus
      Saved
      SaveFailed
      Unperformed
    end

    property save_status : SaveStatus = SaveStatus::Unperformed

    # Returns true if the operation has run and saved the record successfully
    def saved?
      save_status == SaveStatus::Saved
    end

    # Return true if the operation has run and the record failed to save
    def save_failed?
      save_status == SaveStatus::SaveFailed
    end
  end

  # Sets the `save_status` to `SaveFailed`
  def mark_as_failed
    self.save_status = Avram::SaveOperation::SaveStatus::SaveFailed
  end

  # Sets the `save_status` to `Saved`
  def mark_as_saved
    self.save_status = Avram::SaveOperation::SaveStatus::Saved
  end
end
