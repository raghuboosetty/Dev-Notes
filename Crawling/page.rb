require 'nokogiri'
require 'rubygems'
require 'open-uri'
require 'httparty'

def whole_url_pattern_match(url)
  response = HTTParty.get(url)
  puts "\n Response Code: #{response.code.inspect} \n"
  doc = Nokogiri::HTML(response.body) if response.code == 200
  links_array = Array.new
  unless doc.nil?
    links = doc.css("a")
    links.each do |link|
      link_str = link.to_html.to_s
      if link_str =~ /\d/ && link_str.include?(url) && link_str != url
        links_array << link_str
      end
    end
  end

  links_array = links_array.uniq

  puts links_array
  puts links_array.length

  puts "\n Possible pagination urls \n"
  links_array.each do |l|
    nlink = Nokogiri::HTML(l)
    puts "\n #{nlink.at_css('a')['href']} \n"
  end
end

def part_url_pattern_match(url)
  current_page = url.split("/")
  current_page = current_page.last
  current_page = current_page.split("?").first
  response = HTTParty.get(url)
  puts "\n Response Code: #{response.code.inspect} \n"
  doc = Nokogiri::HTML(response.body) if response.code == 200
  links_array = Array.new
  unless doc.nil?
    links = doc.css("a")
    links.each do |link|
      link_str = link.to_html.to_s
      puts link_str
      if link_str =~ /\d/ && link_str.include?(current_page) && link_str != url
        links_array << link_str
      end
    end
  end
  links_array = links_array.uniq
  puts links_array
  puts links_array.length

  puts "\n Possible pagination urls \n"
  links_array.each do |l|
    nlink = Nokogiri::HTML(l)
    puts "\n #{nlink.at_css('a')['href']} \n" if nlink.at_css('a')['href'] =~ /\d/
  end
end

def content_is_number(url)
  response = HTTParty.get(url)
  puts "\n Response Code: #{response.code.inspect} \n"
  doc = Nokogiri::HTML(response.body) if response.code == 200
  links_array = Array.new
  unless doc.nil?
    links = doc.css("a")
    links.each do |link|
      link_str = link.to_html.to_s
      links_array << link_str if link_str =~ /\d/
    end
  end
  links_array = links_array.uniq
  puts links_array
  puts links_array.length

  puts "\n Possible pagination urls \n"
  links_array.each do |l|
    nlink = Nokogiri::HTML(l)
    puts "\n #{nlink.at_css('a')['href']} \n" if (1..50000).include?(nlink.at_css('a').content.to_i)
  end
end

#Method calls here. Please comment out every method call except the one you wish to run.

#whole_url_pattern_match("http://careers.joelonsoftware.com/jobs")
#part_url_pattern_match("http://austintecjobs.hiringhook.com/JobSeeker/SearchResults.aspx?runsearch=1&defaultSearch=1")
#part_url_pattern_match("http://jobs.pizzahut.com/search?q=")
#part_url_pattern_match("http://www.careersingear.com/search?&employer_id=1495")
#content_is_number("http://www.blueskiescareers.co.uk/jobs/all/")
