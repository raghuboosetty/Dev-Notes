#https://www.linkedin.com/recruiter/search?searchHistoryId=2874669273&searchCacheKey=4b282956-a8fc-40d6-bb88-692b59132797,2WLB&linkContext=Controller:peopleSearch,Action:resultsWithFacets,ID:2874669273&page=1&start=0&count=25
#https://www.linkedin.com/recruiter/search?searchHistoryId=2874669273&searchCacheKey=4b282956-a8fc-40d6-bb88-692b59132797,2WLB&linkContext=Controller:peopleSearch,Action:resultsWithFacets,ID:2874669273&page=1&start=0&count=250

require 'nokogiri'
require 'mechanize'
require 'httparty'
require 'writeexcel'
require 'open-uri'
require 'uri'
require 'cgi'
require 'rubygems'

# append sanitizer method to ruby String class
class String
  def sanitize
    html_tags_regex = /<("[^"]*"|'[^']*'|[^'">])*>/
    self.to_s.gsub(html_tags_regex, '') rescue nil
  end
end

class StaticLinkedin

  def initialize(options={})
    @files = options[:files] || Dir.glob("./html/*.html")
    # write the profiles to excel sheet
    @filename = options[:filename] || "static-inkedin-#{Time.now.to_i}"
    @base_url = "https://www.linkedin.com/"
  end

  def static_profiles
    profiles = []
    @files.each do |file|
      puts "Parsing #{file}..."
      @doc = Nokogiri::HTML(File.open(file))
      content = @doc.search("code")[1].inner_html.gsub('-->', '').gsub('<!--','') rescue ''
      json_data = (JSON.parse(content))['data']['result']['searchResults'] rescue []

      json_data.each do |jd|
        profile = {}
        profile[:headline] = jd['headline'].sanitize rescue nil
        profile[:name] = jd['fullName'].sanitize rescue nil
        profile[:industry] = jd['industry'].sanitize rescue nil
        profile[:location] = jd['location'].sanitize rescue nil
        profile[:short_link] = "#{@base_url}profile/view?id=#{jd['findAuthInputModel']['profileId'] rescue nil}"
        profile[:link] = profile[:short_link]
        profile[:current_heading] = jd['currentPositions'][0]['title'].sanitize rescue nil
        profile[:current_company] = jd['currentPositions'][0]['companyName'].sanitize rescue nil
        profiles.push profile
      end
    end
    profiles
  end

  def write_profiles
    workbook = WriteExcel.new("#{@filename}.xls")
    worksheet  = workbook.add_worksheet

    # improve visibility(in centimeters)
    #
    # e.g: B:C -> width for column B to column C is 45cm
    #
    worksheet.set_column('B:C', 35) # Name
    worksheet.set_column('C:D', 55) # Headline
    worksheet.set_column('D:E', 30) # Current Company
    worksheet.set_column('E:F', 30) # Location
    worksheet.set_column('F:G', 20) # Industry
    worksheet.set_column('G:H', 70) # Short Link
    worksheet.set_column('H:I', 200) # Full Link
    worksheet.set_column('I:J', 60) # Current Heading

    # Formats
    #
    # bold and wrap
    format_1 = workbook.add_format
    format_1.set_bold
    format_1.set_text_wrap()

    # center align and wrap
    format_2 = workbook.add_format
    format_2.set_align('center')
    format_2.set_text_wrap()

    # only text wrap
    format_3 = workbook.add_format
    format_3.set_text_wrap()

    headers = ['Sno.', 'Name', 'Headline', 'Company', 'Location', 'Industry', 'Short Link', 'Full Link', 'Current Heading']
    headers.each_with_index do |header, index|
      worksheet.write(0, index, header, format_1)
    end

    static_profiles.each_with_index do |profile, index|
      worksheet.write((index + 1), 0, (index + 1), format_2)
      worksheet.write((index + 1), 1, profile[:name], format_3)
      worksheet.write((index + 1), 2, profile[:headline], format_3)
      worksheet.write((index + 1), 3, profile[:current_company], format_3)
      worksheet.write((index + 1), 4, profile[:location], format_3)
      worksheet.write((index + 1), 5, profile[:industry], format_3)
      worksheet.write((index + 1), 6, profile[:short_link], format_3)
      worksheet.write((index + 1), 7, profile[:link], format_3)
      worksheet.write((index + 1), 8, profile[:current_heading], format_3)
    end

    puts "Written to #{@filename}.xls"

    # write to file
    workbook.close
  end

end
l = StaticLinkedin.new
l.write_profiles