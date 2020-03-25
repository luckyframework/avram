class Issue < BaseModel
  COLUMN_SQL = "issues.id, issues.status, issues.role"

  avram_enum Status do
    Opened     = 0
    Closed     = 1
    Duplicated = 2
  end

  avram_enum Role do
    Issue    = 1
    Bug      = 2
    Critical = 3
  end

  table do
    column status : Issue::AvramStatus
    column role : Issue::AvramRole
  end
end

class IssueQuery < Issue::BaseQuery
end
