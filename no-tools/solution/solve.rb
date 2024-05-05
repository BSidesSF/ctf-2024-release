require 'socket'
require 'timeout'
require './libronsolve'

HOST, PORT = get_host_port()
s = TCPSocket.new(HOST, PORT)
puts "Connected! #{s}"
s.write("read FLAG < /home/ctf/flag.txt && echo \"FLAG\"$FLAG\"ENDFLAG\"\n")

buffer = ''
begin
  Timeout.timeout(10) do
    loop do
      buffer += s.gets()
      if buffer =~ /FLAG(CTF.*)ENDFLAG/
        check_flag($1, terminate: true)
        exit 0
      end
    end
  end
rescue StandardError => e
  puts "Failed to get the flag: #{e}"
  puts
  puts "Received:"
  puts "---"
  puts buffer
  puts "---"
  exit 1
end
