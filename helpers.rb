module Helpers

  def self.waiting_op(message, seconds = 1, &block)
    print "#{message}."

    myThread = Thread.new do
      loop do
        print "."
        sleep seconds
      end
    end

    myThread.run
    result = block.call
    myThread.kill
    puts ""
    result
  end

  def self.wait_while(message, seconds = 1, &block)
    Helpers.waiting_op(message, seconds) do
      loop do
        result = block.call
        break if !result
        sleep seconds
      end
    end
  end
end