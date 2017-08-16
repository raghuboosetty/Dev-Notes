#!/usr/bin/env ruby

require "bundler/setup"
require "excel_merge"


unique_column = 'Linkedin Link'
columns = ['Name', 'Current Position', 'Current Company', 'Twitter Link', 'Linkedin Link', 'Websites', 'Location', 'Industry', 'Emails', 'Rails Profile', 'Connection Count', 'Degree', 'Skills', 'Description', 'Companies', 'Headline']

workbooks = Dir.glob("./xls/profiles/*.xls")
excel_merger = ExcelMerge::Merger.new(columns: columns, workbooks: workbooks, serial_no: true, unique_column: unique_column)
excel_merger.merge!

puts ExcelMerge::Merger

