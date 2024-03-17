class Interview < BaseModel
  table do
    belongs_to interviewer : User
    belongs_to interviewee : User
  end
end

class InterviewQuery < Interview::BaseQuery
end
