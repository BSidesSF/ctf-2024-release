from bs4 import BeautifulSoup
import requests
import sys

if len(sys.argv) != 3:
    print("Please specify challenge URL and username")
    print("python solution.py <challenge-url> <username>")
    print("E.g, python solution.py http://127.0.0.1:8000 corgi123")
    exit()

# Variables 
url = sys.argv[1]
username = sys.argv[2]
password = "P0aA9rSkogS!!"

# Set-up your main user
with requests.Session() as s:
    regParam = {'username':username,'password':password,'confirm':password,'submit':'Register'}
    response = s.post(url + '/register',json=regParam)
    loginParam = {'username':username,'password':password,'submit':'Login'}
    response = s.post(url + '/login', json=loginParam)

	# Fetch the game board 
    response = s.get(url + '/home')
    text = response.text

	# Use BeautifulSoup to parse the HTML
    soup = BeautifulSoup(text, 'html.parser')

    # Find all div tags
    div_tags = soup.find_all('div', class_='memory-card')
    match_url = url + "/match?"
    matches = {}

    # Process or print the div tags
    for div in div_tags:
    	# Access attributes or text content of each div
    	matches[div.attrs['data-id']] = div.attrs['data-value']

    # Match the cards
    for i in range(1,9):
    	matching_keys = [key for key, value in matches.items() if value == str(i)]
    	value_args = 'first_val=' + str(i) + '&second_val=' + str(i)
    	pos_args = '&first_pos=' + str(matching_keys[0]) + '&second_pos=' + str(matching_keys[1])
    	match_url = url + '/match?' + value_args + pos_args
    	response = s.get(match_url)
    	print(response.text)

    # Get the flag
    response = s.get(url + '/flag')
    print(response.text)


