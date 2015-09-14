# Electricity Bill

require 'rubygems'
require 'mechanize'
require 'logger'

agent = Mechanize.new
agent.max_history = nil # unlimited history

# agent.log = Logger.new $stderr
# agent.agent.http.debug_output = $stderr
#
# url = "https://www.billdesk.com/APCPDCL/apcpdcl.htm"
# page = agent.get(url)
# form = page.form_with name: 'form1'
# puts form.uscno
# form.uscno = "101892479"
# puts form.uscno
# puts form.button_with(name: 'verify').inspect
# page = form.submit form.button_with(name: 'verify')


url = "https://www.tssouthernpower.com/Billdesk/OnlineBill.jsp"
page = agent.get(url)
form = page.form_with name: 'onlineBillEnquiryForm'
# form.field_with(name: 'circle').options[2].click
form.field_with(name: 'circle').value = "RRN"
# puts form.field_with(name: 'circle').value
form.field_with(name: 'ero').value = "311"
# puts form.field_with(name: 'ero').value
form.uscno = "101892479"
# puts form.uscno
page = form.submit
html = (page.body).force_encoding("ISO-8859-1").encode("utf-8", replace: nil)
doc = Nokogiri::HTML(html)
bill_doc = doc.at_css(".top-message table.Table_Border1")
values = bill_doc.css(".style7").map{ |v| v.text.gsub(/\P{ASCII}/, ' ').strip! }
result = {
  "Name" => values[0],
  "Unique Service No." => values[1],
  "Service No." => values[2],
  "ERO Name" => values[3],
  "Address" => [values[4], values[5]].join(", "),
  "Your arrears as on Date" => values[6],
  "Your arrears as on Amount" => values[7],
  "Current Month Bill Date" => values[8],
  "Current Month Bill Amount" => values[9],
  "Total Amount Payable Date" => values[10],
  "Total Amount Payable Amount" => values[11],
  "Payment Details Paid Date" => values[12],
  "Amount Paid for Current Month" => values[13]
}
result.each_pair do |k, v|
  puts "#{k} : #{v}"
end