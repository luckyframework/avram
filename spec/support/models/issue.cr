class Issue < BaseModel
  COLUMN_SQL = "issues.id, issues.status, issues.role"

  enum Status
    Opened
    Closed
    Duplicated
  end

  enum Role
    Issue    = 1
    Bug      = 2
    Critical = 3
  end

  @[Flags]
  enum Permissions : Int64
    Read
    Write
  end

  table do
    column status : Issue::Status
    column role : Issue::Role = Issue::Role::Issue
    column permissions : Issue::Permissions = Issue::Permissions::Read | Issue::Permissions::Write
  end
end

class IssueQuery < Issue::BaseQuery
end
