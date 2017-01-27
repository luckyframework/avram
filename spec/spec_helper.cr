require "spec"
require "../src/lucky_record"

run("lucky db.drop")
run("lucky db.create")
run("lucky db.migrate")

private def run(command)
  Process.run(command, shell: true, output: true, error: true)
end
