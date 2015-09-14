require 'nokogiri'
require 'rubygems'
require 'open-uri'
require 'httparty'
@uri = URI.parse("http://careers.aahanet.org/jobs/")
@doc = Nokogiri::HTML(open(@uri.to_s))
#html = doc.css('body div table tr')
html = @doc.xpath('.//*')
ids = []
classes = []
html.each do |d|
  id_ = d.attr('id') 
  class_ = d.attr('class') 
  unless id_.nil?
    id0 = id_.split(" ")
    ids << id0 unless id0.nil?
  end
  unless class_.nil?
    c0 = class_.split(" ")
    classes << c0 unless c0.nil?
  end
end

cls = {}
classes.flatten.uniq.each do |c|
  begin
    cls[c] = @doc.css("."+c+"").size
    rescue => e
  end
end

id_ = {}
ids.flatten.uniq.each do |i|
  begin
    id_[i] = @doc.css("#"+i+"").size
    rescue => e
  end
end


puts "\nCLASS PRESENT IN THE URL\n"
puts cls
filtered_result = cls.select { |key| key.to_s.match(/(job|Location|area|offices|compensation|pay|salary|type|departments)/i) }
puts "Filtered...\n"
puts filtered_result
result = filtered_result.values.inject(Hash.new(0)){|h,k| k; h[k] += 1;h}
if result.values.length == 1
  rep_count = filtered_result.max_by{|k,v| v}[1]
else
  count = filtered_result.values.delete_if {|v| v == 1}.group_by { |e| e }.values.max_by(&:size)
  rep_count = count.first if !count.nil?
end
puts "Most repeated value\n"
puts rep_count
new_classes = cls.reject{|k,v| v != rep_count }
puts "Classes repeated mostly\n"
puts new_classes
puts"#################################################################"


puts "\nIDS PRESENT IN THE URL\n"
puts id_
filtered_result1 = id_.select { |key| key.to_s.match(/(job|Location|area|offices|compensation|pay|salary|type|departments)/i) }
puts "Filtered...\n"
puts filtered_result1
result1 = filtered_result1.values.inject(Hash.new(0)){|h,k| k; h[k] += 1;h}
if result1.values.length == 1
  rep_count1 = filtered_result1.max_by{|k,v| v}[1]
else
  count1 = filtered_result1.values.delete_if {|v| v == 1}.group_by { |e| e }.values.max_by(&:size)
  rep_count = count1.first if !count1.nil?
end
puts "Most repeated value\n"
puts rep_count1
new_classes = id_.reject{|k,v| v != rep_count1 }
puts "ID's repeated mostly\n"
puts new_classes
puts"#################################################################"
