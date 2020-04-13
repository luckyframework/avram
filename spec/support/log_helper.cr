module LogHelper
  def self.temp_override(log_class)
    io = IO::Memory.new
    original_backend = log_class.backend
    original_level = log_class.level
    begin
      backend = Log::IOBackend.new(io)
      backend.formatter = Dexter::JSONLogFormatter.proc
      log_class.level = Log::Severity::Debug
      log_class.backend = backend
      yield io
    ensure
      log_class.backend = original_backend
      log_class.level = original_level
    end
  end
end
