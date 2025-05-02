class InterviewFactory < BaseFactory
  def initialize
    before_save do
      if operation.interviewer_id.value.nil?
        interviewer(UserFactory.create)
      end
      if operation.interviewee_id.value.nil?
        interviewee(UserFactory.create)
      end
    end
  end

  def interviewer(u : User)
    interviewer_id(u.id)
  end

  def interviewee(u : User)
    interviewee_id(u.id)
  end
end
