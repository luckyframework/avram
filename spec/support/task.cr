class Task < LuckyRecord::Model
  table tasks do
    field title : String
    field body : String?
  end
end
