class UploadedFile
  include Avram::Uploadable

  def initialize(filename : String)
    @name = "part.name"
    @tempfile = File.tempfile(@name) { |file| File.write(file.path, "tmp") }
    @metadata = HTTP::FormData::FileMetadata.new(filename)
  end
end
