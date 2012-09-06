require 'pp'
class SimpleRunHandler < Chef::Handler
  def report()
    pp [:run_handler_called]
  end
end
