require 'socket'
require './libronsolve.rb'

RIGHT = '00'
LEFT  = '01'
PRINT = '10'
WRITE = '11'

host, port = get_host_port()

# Connect to the service
s = TCPSocket.new(host, port)

# Read the instructions
s.gets()

# Skip the part of the tape with boring words
1.upto(40) do
  s.write(RIGHT)
end

# Read each character, move right, and convert it to a character
flag = 1.upto(expected_flag().length).map do
  s.write(PRINT + RIGHT)
  s.read(8).to_i(2).chr
end.join

# Validate
check_flag(flag, terminate: true)
