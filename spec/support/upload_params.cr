class UploadParams < Avram::Params
  include Avram::Paramable

  @uploads : Hash(String, UploadedFile) = {} of String => UploadedFile

  def initialize(@uploads)
  end

  def nested_file?(key) : Hash(String, UploadedFile)
    @uploads
  end

  def nested_file(key) : Hash(String, UploadedFile)
    @uploads
  end
end
