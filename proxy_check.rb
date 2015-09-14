# include HTTParty
require 'rubygems'
require 'httparty'

us_proxies = "206.144.164.146:9602:username:pwd
216.97.19.166:49212:username:pwd
"


url = "http://twitter.com/"
# url = "https://api.stackexchange.com/2.2/questions?site=stackoverflow"
# url = "http://volunteer.ca/"

puts
puts "URL: #{url}"

uri = URI.parse(url)

#if uri.host.include?(".ca")
#  proxies = ca_proxies
#  puts "Country: CA"
#elsif uri.host.include?(".com")
#  proxies = us_proxies
#  puts "Country: US"
#else
#  puts "Country not recognized"
#end

us_proxies.split("\n").sort.each do |proxy|
  options = proxy.split(':')
  http_options = {
    headers: { "User-Agent" => "Googlebot/2.1 (+http://www.google.com/bot.html)" },
    timeout: 20,
    ssl_version: :SSLv3,
    # verify_mode: OpenSSL::SSL::VERIFY_NONE,
    http_proxyaddr: options[0],
    http_proxyport: options[1],
    http_proxyuser: options[2],
    http_proxypass: options[3] }

  begin
    body = HTTParty.get(url, http_options)
    #if  == 200
    	puts "#{proxy}-------- #{body.response.code}"
    #end
  rescue => e
    #puts "#{proxy} - #{e.class}"
  end

end