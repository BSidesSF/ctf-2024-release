import enum
from werkzeug.middleware import proxy_fix
from flask import Flask, render_template, request, redirect, flash
from flask_csp.csp import csp_header

# For the OAuth operations 
from oauth2client.service_account import ServiceAccountCredentials
import google.auth
import traceback
import requests
import json


# Flask App initialization
app = Flask(__name__)
app.wsgi_app = proxy_fix.ProxyFix(app.wsgi_app)

# Spreadsheet related variables
SCOPES = ['https://www.googleapis.com/auth/spreadsheets.readonly']
SERVICE_ACCOUNT_KEY_FILE = 'key.json'
SPREADSHEET_ID = '18hFC6DvTZ-NtbYby7Sej0f8t8-6n0_GL7Uf25acuRk8'

# Set CSP policy for this app 
@app.after_request
def apply_csp(response):
    response.headers["Content-Security-Policy"] = "default-src 'self';" \
        "script-src 'self';" \
        "img-src 'self' data:;" \
        "connect-src *;" \
        "style-src-elem 'self' fonts.googleapis.com fonts.gstatic.com;" \
        "font-src 'self' fonts.gstatic.com fonts.googleapis.com"
    return response

# Home page
@app.route('/', methods=['GET'])
def home():
    return render_template('home.html')

@app.route('/shade', methods=['GET'])
def shade():
    color = request.args.get('color')
    if color == 'pink':
        range_start = 'A2'
        range_end = 'C7'
    elif color == 'purple':
        range_start = 'A8'
        range_end = 'C26'
    elif color == 'red':
        range_start = 'A28'
        range_end = 'C35'
    elif color == 'orange':
        range_start = 'A36'
        range_end = 'C40'
    elif color == 'yellow':
        range_start = 'A41'
        range_end = 'C51'
    elif color == 'green':
        range_start = 'A52'
        range_end = 'C73'
    elif color == 'cyan':
        range_start = 'A74'
        range_end = 'C81'
    elif color == 'blue':
        range_start = 'A82'
        range_end = 'C97'
    elif color == 'brown':
        range_start = 'A98'
        range_end = 'C115'
    elif color == 'white':
        range_start = 'A116'
        range_end = 'C132'
    elif color == 'grey':
        range_start = 'A133'
        range_end = 'C142'
    else:
        range_start = 'A1'
        range_end = 'C142'
    url = "/color?range_start=" + range_start + "&range_end=" + range_end
    return redirect(url, code=302)

@app.route('/color', methods=['GET'])
def color():
    access_token = init_credentials()
    if not access_token:
        return render_template('error.html', error='Something went wrong!')
    try:
        range_start = request.args.get('range_start', default='A1')
        range_end = request.args.get('range_end', default='B1')
        response = requests.get("https://sheets.googleapis.com/v4/spreadsheets/" + SPREADSHEET_ID + "/values/" + range_start + ":" + range_end + "?access_token=" + access_token,)
        response.raise_for_status()
        results = json.loads(response.text)
        colors = results['values']
    except:
        return traceback.format_exc()
    return render_template('color.html', colors=colors)

def init_credentials():
    credentials = ServiceAccountCredentials.from_json_keyfile_name(SERVICE_ACCOUNT_KEY_FILE, SCOPES)
    if not credentials or credentials.invalid:
        print('Unable to authenticate using service account key.')
        return None
    token_info = credentials.get_access_token()
    return token_info.access_token


app.run(host='0.0.0.0', port=8000)
app._static_folder = ''
