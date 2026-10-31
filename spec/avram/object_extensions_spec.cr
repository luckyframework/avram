require "spec"

describe Object do
  it "handles objects without empty?" do
    # spec_helper loads Lucky, which overrides Object#blank? and masks this regression.
    source = <<-CRYSTAL
      require "./src/avram/object_extensions"
      object = Exception.new
      puts object.blank?
      puts object.present?
      CRYSTAL
    output = IO::Memory.new
    status = Process.run(
      "crystal",
      ["eval", source],
      chdir: File.expand_path("../..", __DIR__),
      output: output,
      error: output
    )

    status.success?.should be_true, output.to_s
    output.to_s.lines.should eq(["false", "true"])
  end
end
