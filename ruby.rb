# ------------------------------------------------------------------------
# Basic commands/things
# ------------------------------------------------------------------------
# Syntax check in ruby
ruby -c Gemfile

# ------------------------------------------------------------------------
# Program that prints itself
# ------------------------------------------------------------------------
def method;"def method;;end;puts method()[0, 11] + 34.chr + method + 34.chr + method()[11, method.length-11]";end;puts method()[0, 11] + 34.chr + method + 34.chr + method()[11, method.length-11]

# ------------------------------------------------------------------------
# Array summation conditional
# ------------------------------------------------------------------------
# The logic is, if any two array have the first element same then we need to sum up those two array second element and make it as a single array. Could you please let me know if you have any idea on this can be achived
two_dim_array=[[1, 1], [2, 4], [3, 9], [1, 1], [3,1]]
results = Hash.new(0)
two_dim_array.each do |k, v|
	results[k] = results[k] + v
end
results.to_a

# ------------------------------------------------------------------------
# Class Paths
# ------------------------------------------------------------------------
RDF::Reader.instance_methods(false).map { |m|
  RDF::Reader.instance_method(m).source_location.first
}.uniq

# ------------------------------------------------------------------------
# Gets
# ------------------------------------------------------------------------
def test
puts "Continue(Y/N):"
input = gets.chomp
if input == "Y"
  puts "Continuing..."
else
  puts "Stopped!"
end
end

silence_stream(STDOUT) do
  s = Source.all
end

# ------------------------------------------------------------------------
# Host to ip convert
# ------------------------------------------------------------------------
require 'socket'

# returns AddrInfo object or nil
def get_host_ip(host,port)
  socket = Socket.tcp(host,port)
  return nil unless socket
  addr = socket.remote_address
  socket.close
  addr
end

# ------------------------------------------------------------------------
# resuce with ensure
# ------------------------------------------------------------------------
def with_ensure
  count = 3
  yield
rescue => e
  puts "#{e.message}"
  raise e
ensure
  if count > 0
    puts "TEST COUNT - #{count}"
  end
end
with_ensure

# ------------------------------------------------------------------------
# Method Missing
# ------------------------------------------------------------------------
class Sample
  # used for setting default options
  def method_missing(method_sym, *arguments, &block)
    if method_sym.to_s =~ /^default_(.*)_to$/
      tag_name = method_sym.to_s.split("_")[1..-2].join("_").to_sym
      @options[tag_name] = arguments[0] unless @options.has_key?(tag_name)
    else
      super
    end
  end

  def initialize(options = {})
    @options = options
    if @options[:queue_system] == :resque
      default_processing_queue_to               "CobwebProcessJob"
      default_crawl_finished_queue_to           "CobwebFinishedJob"
    else
      default_processing_queue_to               "CrawlProcessWorker"
      default_crawl_finished_queue_to           "CrawlFinishedWorker"
    end
    puts @options
  end
end

puts Sample.new

# ------------------------------------------------------------------------
# Get arrary from string
# ------------------------------------------------------------------------
text.gsub(/(\[\"|\"\])/, '').split('", "')