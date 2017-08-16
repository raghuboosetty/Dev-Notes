require 'rubygems'
require 'httparty'
require 'nokogiri'
require "addressable/uri"
require "awesome_print"
require "./crawl_base"

class FiveHundred < CrawlBase
  def initialize(url, options={})
    @options = {}
    super(url)
  end

  def options
    @options
  end

  def parse!
    @url = @base_url
    page
  end

  def parse_page(url)
  end
end

yts = FiveHundred.new("https://500px.com/seaver1", {})
yts.parse!