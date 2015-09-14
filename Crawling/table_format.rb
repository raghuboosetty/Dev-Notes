require 'nokogiri'
require 'httparty'

# To extract the job details from the urls which are in table format
module TableFormat
  KEYWORDS = [
      "Title", "Job Title", "Posting Title",
      
      "ID", "Job ID", "Requisition Number", "Job Tracking ID", "Tracking Code", 
      "Requisition", "Job Requisition",
      
      "Description", "Job Description", "Position Summary", "Work Hours",
      
      "Date", "Posted", "Post Date", "Posted Date", "Posted On", "Date Updated", 
      "Closing Date", "Date Opened",
      
      "Location", "Job Location", "City", "State", "Company", 
      
      "Job Type", "Job Category", "Position Type", "Employment Type", "Department", 
      "Functional Area", "Category", "Classification Type", "Organizational Unit",
      
      "Qualifications", "Physical Demands", "Requirements", "Education", 
      "Experience", "Experience and Skills", 
      
      "Responsibilities", "Key Accountabilities", "Duties and Responsibilities", 
      "Required Skills", "Education and Experience", "Knowledge and Skills",
      "Essential Functions and Responsibilities", "Experience Required", "Reorganization",
      
      "Work Environment", "Benefits", "Additional Information", "Language",
      
      "Job Opportunity", "of openings", "Position Status",
      
      "Apply", "Apply Now", "Apply for this position", "To Apply", 
        
      "Salary"
      ]
      
  def parse(url)
    Rails.logger.debug "hello...........#{url}."
    keywords = KEYWORDS.map{|s| s.downcase}

    puts "URL : " + url #remove later
    response = HTTParty.get(url)
    puts "Status Code : " + response.code.to_s
    exit(0) if response.code != 200
    body = response.body
    doc = Nokogiri::HTML(body)
    jobs = []
    links = doc.css("a")
    nav_links = []
    links.each do |link|
      ret = link.text.strip =~ /^[0-9]+$/
      nav_links << link.attr("href") if (ret == 0) #link.text.strip.scan(/\d+/).last
    end
    nav_links.uniq.each do |href|
     if href.include?("http")
       url = href
     else
       page_url = (href[0] == "/") ? href : "/" + href
       url = @uri.scheme + "://" + @uri.host + page_url
     end
     puts "NAV LINKS...................#{url}"
     respon = HTTParty.get(@uri.to_s)
     puts "Status Code : " + respon.code.to_s
     exit(0) if respon.code != 200
     docu = Nokogiri::HTML(respon.body)
     jobs = jobs_list(jobs, docu)
    end
    jobs
  end
  
  def jobs_list(jobs, docu)
    keywords = KEYWORDS.map{|s| s.downcase}
    table_hash = Hash.new(0) #contains table obj and its keyword match count
    table_content_hash = Hash.new(0) #contains table obj and 

    tables_doc = docu.css('table')

    puts "Tables Found : " + tables_doc.count.to_s #remove later

    tables_doc.each do |table|
      job_header_nth_row = nil
      next if !table.css('table').empty? # avoid nesting
      table_rows = table.css('tr')
      # take only first 3 rows(as the header is expected to have in those)
      match_count = 0
      table_rows[0..3].each_with_index do |table_row, index|
        match_count_buffer = 0
        table_row.css("th, td").each do |table_header|
          header_text = table_header.text.gsub(/\P{ASCII}/, ' ').gsub(/[^0-9a-z]/i, ' ').downcase.strip
          break if header_text.size > 40 # lengthy words - avoid un-necessary loop
          if keywords.include?(header_text)
            match_count_buffer += 1
          end
        end
        if match_count_buffer > match_count
          match_count = match_count_buffer
          job_header_nth_row = index + 1
        end
      end
      table_hash[table] = match_count
      table_content_hash[table] = job_header_nth_row
    end

    jobs ||= []
    if tables_doc.count > 0 && !table_hash.empty?
      table_hash_sorted = table_hash.sort{|a,b| a[1]<=>b[1]}
      puts "Max Match Count : " + table_hash_sorted.last[1].to_s #remove later
      table = table_hash_sorted.last[0] #table with jobs
      row_with_header = table_content_hash[table] #tr having job headers
      
      job_headers = table.at_css("tr:nth-child(" + row_with_header.to_s + ")").css("th, td")
      job_headers_array = []
      job_headers.each do |job_header|
        job_headers_array.push(job_header.text.gsub(/\P{ASCII}/, ' ').downcase.strip)
      end
      
      table.css("tr").each_with_index do |tr, index|
        next if (((index + 1) <= row_with_header) || (tr.css("td").size != job_headers_array.size))
        job = {}
        tr.css("td").each_with_index do |td, index|
          job[job_headers_array[index]] = td.text.gsub(/\P{ASCII}/, ' ').strip
        end
        jobs.push(job)
      end
      
      puts #remove later
      puts "Jobs found: #{jobs.size}" #remove later
     # puts jobs #remove later
      jobs
    end
    jobs
  end    
end
