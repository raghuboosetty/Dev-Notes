require 'savon'
client = Savon.client(wsdl: "http://localhost:3002/apis/wsdl")
puts client.operations
response = client.call(:agent_ping)
puts response.body