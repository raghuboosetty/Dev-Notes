# ------------------------------------------------------------------------
# Daemonizing
# ------------------------------------------------------------------------
require 'tweetstream'

TweetStream.configure do |config|
  config.consumer_key       = "cuIZDNUsfRTDUwBbdW5neA"
  config.consumer_secret    = "gps8Ec7hKqO9I2aIItukRlpE43jGp25nt8JV89Xc80"
  config.oauth_token        = "71282191-npJUQ0bckbW1hXNxxhpqEXbGhTxUouDeOrIC4c0Jz"
  config.oauth_token_secret = "8gSYiuGIVZT7XDviOdyqHmXbfINX59YNfQBU737KItfKE"
  config.auth_method        = :oauth
end

# The third argument is an optional process name
TweetStream::Daemon.new('tracker').track('term1', 'term2') do |status|
  # do something in the background
end