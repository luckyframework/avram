module Avram::Uploadable
  abstract def tempfile : File
  abstract def metadata : HTTP::FormData::FileMetadata
  # Typically, this should return the filename as found in the `metadata`.
  abstract def filename : String
  # This should test if the filename is a blank string.
  abstract def blank? : Bool

  module Lucky
    extend Avram::Type

    def self.parse(value : Avram::Uploadable)
     Avram::Type::SuccessfulCast(Avram::Uploadable).new(value)
    end

    def self.parse(values : Array(Avram::Uploadable))
     Avram::Type::SuccessfulCast(Array(Avram::Uploadable)).new(values)
    end

    def self.parse(value : String?)
     Avram::Type::FailedCast.new
    end
  end
end
