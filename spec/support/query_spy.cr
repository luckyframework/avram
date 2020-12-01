# NOTE: This is only for testing if this is called during a query
# TODO: Remove once a proper mocking shard is built
module QuerySpy
  macro included
    class_property times_called : Int32 = 0

    def database : Avram::Database.class
      self.class.times_called += 1
      super
    end
  end
end
