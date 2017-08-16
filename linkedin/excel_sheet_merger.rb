# ruby 2.0.0 must
require 'roo'
require 'roo-xls'
require 'writeexcel'
require 'mechanize'
require 'date'

# append sanitizer method to ruby String class
class String
  def sanitize
    html_tags_regex = /<("[^"]*"|'[^']*'|[^'">])*>/
    self.to_s.gsub(html_tags_regex, '') rescue nil
  end
end

class Sheet
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

  def parse(columns=[])
    rows = [] # final rows - an array of hashes

    count = 0
    row_heads = {} # row heads from sheet
    downcased_columns = columns.map(&:downcase) # for matching
    self.each_row do |es_row|
      hash_mapped_row = {}
      if count.eql? 1 # skip first row(its nil)
        # select rows only with merge columns
        es_row.each_with_index do |es_row_head, index|
          row_heads[es_row_head] = index  if downcased_columns.include? es_row_head.downcase.strip
        end
        puts 'Empty row_head' if row_heads.empty?
      elsif count > 1
        row_heads.each do |head, index|
          hash_mapped_row[head] = es_row[index]
        end
        rows.push hash_mapped_row
      end
      count += 1
    end

    rows
  end
end


class Merger
  attr_reader :rows

  def initialize(options={})
    @columns = options[:columns] || []
    @workbooks = options[:workbooks] || []
    @filename = options[:filename] || "merged-sheet-#{Time.now.to_i}"
    @serial_no = !!options[:serial_no]
    @unique_column = options[:unique_column]
    @rows = []
  end

  def parse_workbooks!
    @workbooks.each do |workbook|
      if !File.exist? workbook
        puts "'#{workbook}' doesn't exist!"
        next
      end
      puts "Parsing #{workbook}..."
      excel_sheet = Sheet.new(workbook)
      @rows += excel_sheet.parse(@columns)
    end
    puts "Total Rows: #{@rows.count}"
    if !!@unique_column # apply uniqueness
      @rows.uniq!{|row| row[@unique_column]}
      puts "Total Unique Rows: #{@rows.count}"
    end
  end

  def merge_workbooks!
    puts "Writing to #{@filename}.xls"
    workbook = WriteExcel.new("#{@filename}.xls")
    worksheet  = workbook.add_worksheet

    # improve visibility(in centimeters)
    #
    # e.g: B:C -> width for column B to column C is 45cm
    #
    alphabets = ('A'..'Z').to_a
    @columns.each_with_index do |column, index|
      next if @serial_no && index.zero? # skip the first row if user wants to add serial no
      worksheet.set_column("#{alphabets[index]}:#{alphabets[index+1]}", (column.size + 30))
    end

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
    format_2.set_align('left')
    format_3.set_text_wrap()

    # write headers
    worksheet.write(0, 0, 'Sno.', format_1) if @serial_no
    @columns.each_with_index do |header, column_index|
      column_index += 1 if @serial_no
      worksheet.write(0, column_index, header, format_1)
    end

    # write body/rows
    @rows.each_with_index do |row, row_index|
      worksheet.write((row_index + 1), 0, (row_index + 1), format_2) if @serial_no

      @columns.each_with_index do |column, column_index|
        column_index += 1 if @serial_no
        worksheet.set_row((row_index + 1), 30) # set fixed height
        worksheet.write_string((row_index + 1), column_index, row[column], format_3)
      end
    end

    # write to file
    workbook.close
  end

  def merge!
    self.parse_workbooks!
    self.merge_workbooks!
  end
end

# Search
# unique_column = 'Short Link'
# columns = ['Name', 'Headline', 'Company', 'Location', 'Industry', 'Short Link', 'Current Heading']

# Profile
unique_column = 'Linkedin Link'
columns = ['Name', 'Current Position', 'Current Company', 'Twitter Link', 'Linkedin Link', 'Websites', 'Location', 'Industry', 'Emails', 'Rails Profile', 'Connection Count', 'Degree', 'Skills', 'Description', 'Companies', 'Headline']

workbooks = Dir.glob("./xls/profiles/*.xls")
excel_merger = Merger.new(columns: columns, workbooks: workbooks, serial_no: true, unique_column: unique_column)
excel_merger.merge!