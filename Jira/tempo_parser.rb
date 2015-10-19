# ruby 2.0.0 must

require 'roo'
require 'roo-xls'
require 'writeexcel'
require 'mechanize'
require 'date'

class ExcelSheet
  def initialize(file_path)
    @xls = Roo::Spreadsheet.open(file_path, :extension => :xls)
  end

  def each_sheet
    @xls.sheets.each do |sheet|
      @xls.default_sheet = sheet
      yield sheet
    end
  end

  def each_row
    0.upto(@xls.last_row) do |index|
      yield @xls.row(index)
    end
  end

  def each_column
    0.upto(@xls.last_column) do |index|
      yield @xls.column(index)
    end
  end

  # Prepare a has with key as ticket_id and value hold ticket title and description in array, each string seperated by '$'
  def parse_tickets
    tickets = {}

    # stuff the ticket_id with titles
    self.each_row do |es_row|
      tickets[es_row[0]] = [] if tickets[es_row[0]].nil?
      tickets[es_row[0]] << es_row[1]
    end

    # run uniqueness on the values to get unique titles
    tickets.each do |ticket_key, ticket_value|
      tickets[ticket_key] = ticket_value.uniq
    end

    # stuff the work log/descriptions, dates and logs
    self.each_row do |es_row|
      tickets[es_row[0]] << [es_row[17], es_row[3], es_row[21]].join("$") #17-description, 3-date, 17-logged hours
    end
    tickets
  end
end

# add method to parent class
class WriteExcel
  def generate_sheet(ticket_cluster)

    ticket_cluster.each do |tickets|
      # Add worksheet(s)
      worksheet  = self.add_worksheet

      # improve visibility(in centimeters)
      #
      # e.g: B:C -> width for column B to column C is 45cm
      #
      worksheet.set_column('B:C', 45) # Title
      worksheet.set_column('C:D', 70) # Description
      worksheet.set_column('D:E', 15) # Date
      worksheet.set_column('E:F', 10) # Hours

      # Formats
      #
      # bold and wrap
      format_1 = self.add_format
      format_1.set_bold
      format_1.set_text_wrap()

      # center align and wrap
      format_2 = self.add_format
      format_2.set_align('center')
      format_2.set_text_wrap()

      # only text wrap
      format_3 = self.add_format
      format_3.set_text_wrap()

      # center align and bold
      format_4 = self.add_format
      format_4.set_bold
      format_4.set_align('center')

      headers = ['Sno.', 'Jira Task Link', 'Jira Task', 'Date (mm/dd/yyyy)', 'Time Spent (in hours)']
      headers.each_with_index do |header, index|
        worksheet.write(0, index, header, format_1)
      end

      row_position = 1
      base_url = "https://jira.parkmobile.com/browse"
      tickets.each_with_index do |(ticket_id, ticket_details_arr), ticket_index|
        next if ticket_index < 2

        worksheet.write(row_position, 0, (ticket_index - 1), format_2)     # Sno.
        worksheet.write(row_position, 1, [base_url, ticket_id].join("/"))  # JIRA Ticket URL

        ticket_details_arr.each_with_index do |ticket_details, ticket_details_index|
          ticket_detail = ticket_details.split('$')  # each row is combined in to a single string with '$' as seperator
          description = ticket_detail[0]       # ticket title and description
          log_date = ticket_detail[1]          # date below is formatted date
          log_date = Date.strptime(log_date.to_s, '%Y-%m-%d').strftime('%m/%d/%Y') rescue log_date
          log_hours = ticket_detail[2].to_f rescue ticket_detail[2] # hours logged in float
          log_hours = nil if log_hours == 0
          local_row_position = row_position + ticket_details_index  # inner row position

          if ticket_details_index == 0
            worksheet.write(local_row_position, 2, description, format_1)
          else
            worksheet.write(local_row_position, 2, description, format_3)
          end
          worksheet.write(local_row_position, 3, log_date, format_2)
          worksheet.write(local_row_position, 4, log_hours, format_2)
        end
        row_position = row_position + ticket_details_arr.size + 1 # go to new row(sum inner rows)

        # Total hours
        if tickets.size == (ticket_index + 1)
          worksheet.write(row_position, 2, "Total", format_1)                     # total hours text
          worksheet.write(row_position, 4, "=SUM(E2:E#{row_position})", format_4) # total hours SUM
        end
      end
    end

  end
end

module Jira
  def self.two_weeks(from=nil)
    two_weeks = []
    if from.nil?
      now = DateTime.now
      to = now - now.wday # nearest Sunday
      from = (to - 13) # 2_weeks_before
    end
    two_weeks << { from: from.strftime('%d/%b/%y'), to: (from + 6).strftime('%d/%b/%y') }
    two_weeks << { from: (from + 7).strftime('%d/%b/%y'), to: (from + 13).strftime('%d/%b/%y') }
    two_weeks
  end

  def self.download_url(options={})
    period_type  = options[:period_type]  || 'FLEX'

    # set options based on type
    if period_type == 'FLEX'
      now = DateTime.now
      to = now - now.wday # nearest Sunday
      from = (to - 6) # 1_week_before
      to = to.strftime('%d/%b/%y')
      from = from.strftime('%d/%b/%y')

      period  = "from=#{options[:from] || from}&to=#{options[:to] || to}"
      period_view = "DATES"
    else
      mmyy = Time.now.strftime('%m%y')

      period  = "period=#{options[:period] || mmyy}"
      period_view  = "PERIOD"
    end

    params = [ "v=1",
               "filterIds=-1001",
               "periodType=#{period_type}",
               "periodView=#{period_view}",
               period ].join("&")

    options[:download_url] || "https://jira.parkmobile.com/secure/TempoUserBoard!excel.jspa?#{params}"
  end

  def self.download_sheet(uname, pwd, urls=[])
    login_url = "https://jira.parkmobile.com/login.jsp"

    agent = Mechanize.new
    agent.get(login_url)
    form = agent.page.form_with(:action => "/login.jsp")
    form.field_with(name: 'os_username').value = uname
    form.field_with(name: 'os_password').value = pwd
    form.submit
    agent.pluggable_parser.default = Mechanize::Download

    files = []

    urls.each_with_index do |url, index|
      puts "Downloading Jira tempo timesheet #{index + 1}..."
      puts url
      file = agent.get(url).save
      files << file
    end

    puts "No files downloaded!" if !(files.size > 0)
    files
  end

  def self.ticket_cluster
    jira_download_urls = []
    Jira.two_weeks(FROM).each do |week|
      jira_download_urls << Jira.download_url(week)
    end

    files = Jira.download_sheet(UNAME, PWD, jira_download_urls)

    if files.empty?
      puts 'Download Failed!'
      exit(0)
    end

    # Read from Excel sheet(s)
    ticket_cluster = []
    files.each_with_index do |file, index|
      puts "Parsing #{file}..."
      excel_sheet = ExcelSheet.new(file)
      ticket_cluster << excel_sheet.parse_tickets
      File.delete(file) if File.exist?(file)
    end
    ticket_cluster
  end

  # Write to Excel sheet
  def self.log_sheet(filename="Worklog_#{Time.now.to_i}")
    ticket_cluster = Jira.ticket_cluster
    puts "Writing to '#{filename}.xls'..."

    workbook = WriteExcel.new("#{filename}.xls")
    workbook.generate_sheet(ticket_cluster)

    # write to file
    workbook.close
  end
end

# PRE FETCH DATA
print "From Date(e.g: '28/Sep/15'):"
FROM  = Date.parse(gets) # 28/Sep/15
print "Jira Username:"
UNAME = gets.strip # User.Name
print "Jira Password:"
PWD   = gets.strip # Password

Jira.log_sheet