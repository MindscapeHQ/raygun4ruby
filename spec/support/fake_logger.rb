class FakeLogger
  def initialize
    @logger = StringIO.new
  end

  def info(message)
    @logger.write(message)
  end

  def reset
    @logger.string = ""
  end

  def get
    @logger.string
  end
end
