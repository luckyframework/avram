class Issue < BaseModel
  COLUMN_SQL = "issues.id, issues.status, issues.role"

  avram_enum Status do
    Opened     = 0
    Closed     = 1
    Duplicated = 2
  end

  avram_enum Role do
    Issue    = 0
    Bug      = 1
    Critical = 2
  end

  table do
    column status : Issue::AvramStatus
    column role : Issue::AvramRole
  end
end

class IssueQuery < Issue::BaseQuery
end
