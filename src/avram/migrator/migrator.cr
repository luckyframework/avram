module Avram::Migrator
  def self.run(&)
    yield
  rescue e
    puts e.inspect_with_backtrace
    exit 1
  end
end
