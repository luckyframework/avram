class Avram::UploadedFile
  include Avram::Uploadable

  getter name : String
  getter tempfile : File
  getter metadata : HTTP::FormData::FileMetadata

  def initialize(filename : String)
    @name = "part.name"
    @tempfile = File.tempfile(@name) { |file| File.write(file.path, "tmp") }
    @metadata = HTTP::FormData::FileMetadata.new(filename)
  end

  def filename : String
    metadata.filename.to_s
  end

  def blank? : Bool
    filename.blank?
  end
end
