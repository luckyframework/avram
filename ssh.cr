def shell # (command)
  Process.run(
    "docker-compose",
    %w(run --rm app bash), # shell: true,
    # output: STDOUT,
    output: Process::Redirect::Pipe,
    error: STDERR
  ) do |process|
    process.output.gets_to_end
  end
end

# shell("docker-compose run --rm app bash")

shell
