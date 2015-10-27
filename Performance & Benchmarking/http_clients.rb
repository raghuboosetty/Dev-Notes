# Author: https://github.com/joshsz

require 'rubygems'
require 'httparty'
require 'curb'
require 'net/http'
require 'benchmark'
include Benchmark # we need the CAPTION and FMTSTR constants

RUNS = 10

url = 'http://en.parkopedia.com/parking/brooklyn/'
puts "Measuring GETs"
Benchmark.benchmark(" "*10 + CAPTION, 10, FORMAT) do |x|
  x.report("Net::HTTP") do 
    RUNS.times do 
      # NOTE: This works slightly faster without URI.parse, but I'm trying to make this a little more real-world.
      Net::HTTP.get URI.parse(url)
    end
  end

  x.report("HTTParty") do
    RUNS.times do
      HTTParty.get(url)
    end
  end

  x.report("Curb") do
    RUNS.times do
      Curl::Easy.perform(url)
    end
  end

  # NOTE: This situation might not be typical, but it is a lot faster.
  x.report("Curb-reuse") do
    c = Curl::Easy.new
    RUNS.times do
      c.url = url
      c.perform
    end
  end

  x.report("curl") do
    RUNS.times do
      `curl "#{url}" 2>/dev/null`
    end
  end
end


# params = {'q' => 'test'}
#
# puts "Measuring POSTs"
# Benchmark.benchmark(" "*10 + CAPTION, 10, FMTSTR) do |x|
#   x.report("Net::HTTP") do
#     RUNS.times do
#       Net::HTTP.post_form URI.parse(url), params
#     end
#   end
#
#   x.report("HTTParty") do
#     RUNS.times do
#       HTTParty.post(url, :body => params)
#     end
#   end
#
#   x.report("Curb") do
#     curb_params = params.collect{|(k,v)| Curl::PostField.content(k, v) }
#     RUNS.times do
#       Curl::Easy.http_post(url, curb_params)
#     end
#   end
#
#   x.report("Curb-reuse") do
#     c = Curl::Easy.new
#     curb_params = params.collect{|(k,v)| Curl::PostField.content(k, v) }
#     RUNS.times do
#       c.url = url
#       c.http_post curb_params
#     end
#   end
#
#   x.report("curl") do
#     curl_params = params.collect{|(k,v)| "-F \"#{k}=#{v}\"" }.join(" ")
#     RUNS.times do
#       `curl -X POST -s #{curl_params} "#{url}" 2>/dev/null`
#     end
#   end
# end