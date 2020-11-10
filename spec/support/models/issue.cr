class Issue < BaseModel
  COLUMN_SQL = "issues.id, issues.status, issues.role"

  avram_enum Status do
    Opened
    Closed
    Duplicated
  end

  avram_enum Role do
    Issue    = 1
    Bug      = 2
    Critical = 3
  end

  table do
    column status : Issue::Status
    column role : Issue::Role
  end
end

class IssueQuery < Issue::BaseQuery
end
