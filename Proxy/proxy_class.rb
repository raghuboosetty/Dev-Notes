# Example
proxy_class = Net::HTTP::Proxy('free.unblockyoutuber.com', 8080)

proxy_class.start('www.ruby-lang.org') {|http|
  puts "connected"
  # connecting proxy.foo.org:8080
}


name = "ABTS-AP-Static-102.39.175.122.airtelbroadband.in"
name = "122.175.39.102"

# Example
proxy_class = Net::HTTP::Proxy(name, 8080)

proxy_class.start('www.ruby-lang.org') {|http|
  puts "connected"
  # connecting proxy.foo.org:8080
}
