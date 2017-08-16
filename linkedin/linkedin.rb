require 'nokogiri'
require 'mechanize'
require 'httparty'
require 'writeexcel'
require 'open-uri'
require 'uri'
require 'cgi'
require 'rubygems'
require './constants'
require './arr'

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

    # profile URLs
    @profile_urls = options[:profile_urls] || []

    # write the profiles to excel sheet
    @filename = options[:filename] || "linkedin-profiles-#{Time.now.to_i}"

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

  # nokogiri parsed object of the URL
  def doc(url)
    @doc = Nokogiri::HTML(@client.get(URI.parse(url).to_s).body)
    # @doc = Nokogiri::HTML(File.open('./sample.html'))
  end

  # parse total number of linkedin profiles
  def profiles
    profiles = []
    begin
      @profile_urls.each_with_index do |profile_url, index|
        profile = {}
        puts "#{index + 1}-#{profile_url}"
        doc(profile_url)
        contact_links_hash = {
          ims: '#im-view li',
          phones: '#phone-view li',
          addresses: '#address-view li',
          emails: '#email-view a',
          twitter: '#twitter-view a',
          websites: '#website-view a',
          linkedin: '.view-public-profile'
        }

        contact_links_hash.each do |category, css_id|
          links_css = @doc.css(css_id)
          links = []
          links_css.each do |link_css|
            link = link_css['href']
            link = link.split("url=").last rescue link
            link = link.split("&urlhash=").first rescue link
            link = link.split("mailto:").last rescue link
            link = URI.decode(link) rescue link
            links << link
          end
          profile[category] = links
        end

        contact_info_hash = {
          degree: '.degree-icon',
          name: '.full-name',
          title: '.title',
          location: '.locality a',
          industry: '.industry a',
          description: '#summary-item-view .description',
          connection_count: '.member-connections strong',
          current_position: '.current-position h4 a',
          current_company: '.current-position .new-miniprofile-container a'
        }

        contact_info_hash.each do |category, css_id|
          profile[category] = @doc.at_css(css_id).text.sanitize rescue nil
        end

        profile[:connection_count] = (profile[:connection_count].gsub(/\D/, '') rescue nil).to_i
        if profile[:connection_count] > 500
          profile[:follower_count] = profile[:connection_count]
          profile[:connection_count] = 0
        end

        profile[:companies] = @doc.css('.profile-overview-content .new-miniprofile-container a').map{|c| c.text}
        profile[:skills] = @doc.css('.endorse-item-name-text').map{|c| c.text}

        profile[:rails_profile] = rails_profile?(profile[:skills])

        profiles << profile

        sleep_random
      end
    rescue => e
      puts "Parsing failed due to unexpected error!!"
      puts e.inspect
    ensure
      puts "Trying to write profiles parsed so far..."
      puts "PROFILES-START"
      puts profiles.inspect
      puts "PROFILES-END"
      return profiles
    end
  end # def profiles

  def rails_profile?(skills=[])
    profile = false
    skills.each do |skill|
      if ['ruby', 'rails', 'ruby on rails'].include? skill.downcase
        profile = true
        break
      end
    end
    profile
  end

  def write_profiles
    workbook = WriteExcel.new("#{@filename}.xls")
    worksheet  = workbook.add_worksheet

    # improve visibility(in centimeters)
    #
    # e.g: B:C -> width for column B to column C is 45cm
    #
    worksheet.set_column('A:B', 8) # SNo.
    worksheet.set_column('B:C', 30) # Name
    worksheet.set_column('C:D', 35) # Current Position
    worksheet.set_column('D:E', 30) # Current Company
    worksheet.set_column('E:F', 30) # Twitter Link
    worksheet.set_column('F:G', 40) # Linkedin Link
    worksheet.set_column('G:H', 50) # Websites
    worksheet.set_column('H:I', 30) # Location
    worksheet.set_column('I:J', 20) # Industry
    worksheet.set_column('J:K', 25) # Emails
    worksheet.set_column('K:L', 25) # Phones
    worksheet.set_column('L:M', 20) # IMs
    worksheet.set_column('M:N', 8) # Connection Count
    worksheet.set_column('N:O', 5) # Degree
    worksheet.set_column('O:P', 50) # Skills
    worksheet.set_column('P:Q', 50) # Description
    worksheet.set_column('Q:R', 40) # Companies
    worksheet.set_column('R:S', 5) # Rails Profile
    worksheet.set_column('S:T', 40) # Headline

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
    format_3.set_align('left')
    format_3.set_text_wrap()

    headers = ['Sno.', 'Name', 'Current Position', 'Current Company', 'Twitter Link', 'Linkedin Link', 'Websites', 'Location', 'Industry', 'Emails', 'Phones', 'IMs', 'Connection Count', 'Degree', 'Skills', 'Description', 'Companies', 'Rails Profile', 'Headline']
    headers.each_with_index do |header, index|
      worksheet.write(0, index, header, format_1)
    end

    profiles.each_with_index do |profile, index|
      worksheet.set_row((index + 1), 30) # set fixed height
      worksheet.write((index + 1), 0, (index + 1), format_2)
      worksheet.write((index + 1), 1, profile[:name], format_3)
      worksheet.write((index + 1), 2, profile[:current_position], format_3)
      worksheet.write((index + 1), 3, profile[:current_company], format_3)
      worksheet.write((index + 1), 4, profile[:twitter], format_3)
      worksheet.write((index + 1), 5, profile[:linkedin], format_3)
      worksheet.write((index + 1), 6, profile[:websites].join(', '), format_3)
      worksheet.write((index + 1), 7, profile[:location], format_3)
      worksheet.write((index + 1), 8, profile[:industry], format_3)
      worksheet.write((index + 1), 9, profile[:emails].join(', '), format_3)
      worksheet.write((index + 1), 10, profile[:phones].join(', '), format_3)
      worksheet.write((index + 1), 11, profile[:ims].join(', '), format_3)
      worksheet.write((index + 1), 12, profile[:connection_count], format_3)
      worksheet.write((index + 1), 13, profile[:degree], format_3)
      worksheet.write((index + 1), 14, profile[:skills].join(', '), format_3)
      worksheet.write_string((index + 1), 15, profile[:description], format_3) # fix for Racc::ParseError
      worksheet.write((index + 1), 16, profile[:companies].join(', '), format_3)
      worksheet.write((index + 1), 17, profile[:rails_profile], format_3)
      worksheet.write((index + 1), 18, profile[:title], format_3)
    end

    # write to file
    workbook.close
  end

  # random sleep intervals
  def sleep_random
    sleep (60..120).to_a.sample
  end

end # Linkedin

# email = 'raghu@rubyeffect.com'
# pwd = 'nebularag507'

email = 'raghu.boos@gmail.com'
pwd = 'nebularag507'

# profile_urls = [
#   'https://www.linkedin.com/profile/view?id=ADEAAAw5uSoB6RI6ktuVjI9DxV68w-VxnLQ0A1I',
#   'https://www.linkedin.com/profile/view?id=ADEAABH8D-wB5BpuD3nGXMMuAKRASIIfpj2XbK0'
# ]

l = Linkedin.new(email, pwd, {profile_urls: Constants::URLS[1110..1200]})
l.write_profiles