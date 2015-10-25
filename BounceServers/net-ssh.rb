# ruby Net/SSH Samples

ssh = Net::SSH.start(ip, uname, port: 2222, keys: [ "~/.ssh/id_rsa"])
ssh.exec "sudo free -m"
--------------------------------------------------------------------------------
cmd = "sudo free -m"
password = ''

ssh.open_channel do |channel|
   channel.request_pty do |c, success|
     raise "could not request pty" unless success

     channel.exec "sudo free -m"
     channel.on_data do |c_, data|
       if data =~ /\[sudo\]/ || data =~ /Password/i
         channel.send_data password
       else
         result << data
       end
     end
     puts result
   end
 end
ssh.loop
--------------------------------------------------------------------------------
Net::SSH.start(ip, uname, port: 2222, keys: [ key1 ]) do |ssh|
  ssh.open_channel do |ch|
    ch.exec "sudo free -m" do |ch, success|
      abort "could not execute sudo free -m" unless success
      puts success.inspect
      puts ch.on_data.inspect
      ch.on_data do |ch, data|
        print data
        if data =~ /sudo password: /
          ch.send_data("password\n")
        else
          puts data
        end
      end
    end
  end
  ssh.loop
end
--------------------------------------------------------------------------------
result = []
command = 'sudo free -m | grep Mem:'
password = ''

Net::SSH.start(ip, uname, port: 2222, keys: [ key1 ]) do |ssh|
   ssh.open_channel do |channel|
     channel.request_pty do |c, success|
       raise "could not request pty" unless success
       channel.exec command
       channel.on_data do |c_, data|
         puts data
         if data =~ /\[sudo\]/ || data =~ /Password/i
           channel.send_data "#{password}\n"
         else
           result << data
           if result.size > 0
             # free_memory = result[1].scan(/\d+/)[2].to_i
             # puts "Free Memory: #{(free_memory/1024).round(2)}GB of 8GB" # if free_memory < 1000
             puts result[1]
           end
         end
       end
     end
   end
   ssh.loop
   ssh.close
end
--------------------------------------------------------------------------------
ssh.closed?
ssh.busy?
ssh.close