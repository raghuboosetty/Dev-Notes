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

# parameters
# mandatory - username, password
# optional - keyword, pages, filename
# e.g:
# Linkedin.new('xyz@gmail.com', '123456', { pages: 10, keyword: 'ruby on rails', filename: 'linkedin' })
#
#
class Linkedin
  def initialize(uname, pwd, options={})
    # form the URL
    root = "https://www.linkedin.com"
    path     = ["vsearch", "p"].join("/")
    @base_url = [root, path].join("/")

    # keywords and total pages
    @keyword = options[:keyword] || nil
    @total_pages = options[:pages] || 1

    # write the profiles to excel sheet
    @filename = options[:filename] || "linkedin-#{Time.now.to_i}"

    @client = Mechanize.new
    @client.user_agent_alias = 'Mac Safari' # user agent from Mechanize::AGENT_ALIASES
    @client.get(root) do |page|
      # https://www.linkedin.com/uas/login-submit
      page.form_with( action: [root, 'uas', 'login-submit'].join('/') ) do |f|
        f.session_key  = uname
        f.session_password = pwd
      end.click_button
    end
  end

  # get the URL with params
  # https://www.linkedin.com/vsearch/p?type=people&keywords=ruby%20on%20rails&orig=FCTD&rsid=599131491446707143484&pageKey=nprofile_view_nonself&trkInfo=tarId:1446706964360&search=Search&f_G=in:0&openFacets=N,G,CC,I&f_I=96,4&page_num=2&pt=people
  def url(page=1)
    params   = [ "type=people",
                 "keywords=#{URI.encode(@keyword)}",
                 "orig=FCTD",
                 "rsid=599131491446707143484",
                 "pageKey=nprofile_view_nonself",
                 "trkInfo=tarId:1446706964360",
                 "search=Search",
                 "f_G=in:0",
                 "openFacets=N,G,CC,I",
                 "f_I=96,4",
                 "page_num=#{page}",
                 "pt=people" ].join("&")
    [@base_url, params].join("?")
  end

  # nokogiri parsed object of the URL
  def doc(page=1)
    puts url(page)
    @doc = Nokogiri::HTML(@client.get(URI.parse(url(page)).to_s).body)
  end

  # JSON parsed results array object
  def profile_results(page=1)
    content = doc(page).at_css('#voltron_srp_main-content')
    content = content.children.to_s.gsub('-->', '').gsub('<!--','') rescue ''
    json_data = JSON.parse content rescue []
    json_data['content']['page']['voltron_unified_search_json']['search']['results'] rescue []
  end

  # total number of paginated linkedin profiles
  def profiles
    profiles = []
    begin
      @total_pages.to_i.times do |index|
        profile_results(index + 1).each do |p_r|
          profile = {}
          profile[:name] = p_r['person']['fmt_name'] rescue nil
          if !profile[:name] # join first and last name if fmt_name is absent
            profile[:name] = [p_r['person']['firstName'], p_r['person']['lastName']].join(' ').sanitize rescue nil
          end
          profile[:industry] = p_r['person']['fmt_industry'].sanitize rescue nil
          profile[:headline] = p_r['person']['fmt_headline'].sanitize rescue nil
          profile[:location] = p_r['person']['fmt_location'].sanitize rescue nil
          profile[:link] = p_r['person']['link_nprofile_view_3'] rescue nil

          # get the short URL(extract ID param from it)
          if !profile[:link].nil?
            root_url, params = profile[:link].split('?') rescue [nil, nil]
            cgi = CGI.parse(params) rescue nil
            profile[:short_link] = [root_url, "id=#{cgi['id'].first}"].join('?') rescue nil
          end

          # get the current designation
          snippets = p_r['person']['snippets'] rescue []
          snippets.each do |snippet|
            if snippet['fieldName'].downcase == 'current'
               profile[:current_heading] = snippet['heading'].sanitize rescue nil
               profile[:current_company] = profile[:current_heading].split('at')[1].strip.sanitize rescue nil
            end # if
          end # snippets
          profiles.push profile
        end # profile_results
        sleep_random
      end # 10.times
    rescue => e
      puts "Parsing failed due to unexpected error!!"
      puts e.inspect
    ensure
      puts "Trying to write profiles parsed so far..."
      return profiles
    end
  end # def profiles

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

    profiles.each_with_index do |profile, index|
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

    # write to file
    workbook.close
  end

  # @depricated: works only if the data is loaded without js
  def profiles_old
    profile_urls = []
    1.times do |index|
      profiles = doc(index + 1).css(".main-headline")
      profiles.each do |profile|
        profile_urls.push profile['href']
      end
    end
    profile_urls
  end # profiles_old

  # random sleep intervals
  def sleep_random
    sleep (60..120).to_a.sample
  end

end # Linkedin

# raghu.boos@gmail.com
l = Linkedin.new('raghu@rubyeffect.com', 'nebularag507', { pages: 100, keyword: 'rails OR cucumber OR haml OR rspec OR sass OR mysql' })
l.write_profiles