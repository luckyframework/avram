module Avram
  enum TableLockMode
    ACCESS_SHARE
    ROW_SHARE
    ROW_EXCLUSIVE
    SHARE_UPDATE_EXCLUSIVE
    SHARE
    SHARE_ROW_EXCLUSIVE
    EXCLUSIVE
    ACCESS_EXCLUSIVE

    def to_s
      member_name.to_s.gsub("_", " ")
    end
  end
end
