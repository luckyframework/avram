class Issue < BaseModel
  COLUMN_SQL = "issues.id, issues.status, issues.role"

  enum Status : Int64
    Opened
    Closed
    Duplicated
  end

  enum Role
    Issue    = 1
    Bug      = 2
    Critical = 3
  end

  table do
    column status : Issue::Status
    column role : Issue::Role = Issue::Role::Issue
  end
end

class IssueQuery < Issue::BaseQuery
end
