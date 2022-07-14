class Avram::UploadParams < Avram::Params
  include Avram::Paramable

  @uploads : Hash(String, Avram::UploadedFile) = {} of String => Avram::UploadedFile

  def initialize(@uploads)
    @hash = {} of String => Array(String)
  end

  def nested_file?(key) : Hash(String, Avram::UploadedFile)
    @uploads
  end

  def nested_file(key) : Hash(String, Avram::UploadedFile)
    @uploads
  end
end
