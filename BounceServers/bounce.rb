# Custom ruby script to bounce servers
#
# Bounces servers in a loop
# The script calls 'bounce' script on server
# 'bounce' is an executable command on server, it has 'stop' and 'start' commands with a 3 seconds delay
# this script loops over all the production servers and tries to bounce

require 'rubygems'
require 'net/ssh'

class Bounce
  def initialize(uname, password, command="bounce")
    @command  = command
    @uname    = uname
    @password = password
    @options  = {
                  port: 2222,
                  keys: [ "~/.ssh/id_rsa_cnp" ] }
    @ips      = {  }
  end

  def confirm!
    print "You sure to bounce cape servers(Y/N):"
    sure = gets.strip
    exit(0) if sure.downcase != 'y'
  end

  def start
    @ips.each do |name, ip|
      puts name
      result = []
      Net::SSH.start(ip, @uname, @options) do |ssh|
         ssh.open_channel do |channel|
           channel.request_pty do |c, success|
             raise "could not request pty" unless success
             channel.exec @command
             channel.on_data do |c_, data|
               if data =~ /\[sudo\]/ || data =~ /Password/i
                 channel.send_data "#{@password}\n"
               else
                 result << data
                 puts result
               end
             end
           end
         end
         ssh.loop
         ssh.close
      end # Net::SSH
    end # loop
  end # def start

end # Bounce

bounce = Bounce.new("uname", "password", "sudo free -m | grep Mem:")
bounce.confirm!
bounce.start