abstract class BaseFactory < Avram::Factory
  def self.build
    new.build
  end

  def build
    build_model
  end

  def build_pair
    [build, build]
  end
end
