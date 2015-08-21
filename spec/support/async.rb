module AsyncHelper
  def eventually
    timeout ||= Time.now + 5.seconds
    yield
  rescue Exception => e
    sleep 0.1
    retry if Time.now < timeout
    raise e
  end
end
