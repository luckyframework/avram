# Exit if any subcommand fails
$ErrorActionPreferences = "Stop"

Write-Host "\nRunning tasks\n\n"

crystal tasks.cr db.drop
crystal tasks.cr db.create
crystal tasks.cr db.migrate

# If there were no errors, continue the test
if ($?) {
    # Integration test various tasks
    Write-Host "\nRolling back to 20180802180356\n"
    crystal tasks.cr db.rollback_to 20180802180356
    crystal tasks.cr db.migrations.status
    Write-Host "\nRolling back remainder\n"
    crystal tasks.cr db.rollback_all
    crystal tasks.cr db.migrate.one
    crystal tasks.cr db.migrate
    crystal tasks.cr db.reset
    crystal tasks.cr db.drop
    crystal tasks.cr db.setup
}
