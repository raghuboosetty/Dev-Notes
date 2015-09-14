require 'httparty'
require 'json'
#response = HTTParty.get("http://localhost:3002/api/1/find_all_brokerages_by_mls_board.json")
response = HTTParty.post("http://localhost:3002/api/create_agent", 
    :body => { :name => 'test agent', 
               :phone => '1234567890', 
               :fax => '1234567890', 
               :email => 'test@agent.com', 
               :domain => 'testagent.com'
             }.to_json,
    :headers => { 'Content-Type' => 'application/json' } )
puts "Response: #{response.body}"