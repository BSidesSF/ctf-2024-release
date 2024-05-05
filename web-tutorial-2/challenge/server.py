from flask import Flask, render_template, request, redirect, send_from_directory
from flask_csp.csp import csp_header
import requests
import urllib
from werkzeug.middleware import proxy_fix
from flask_talisman import Talisman

app = Flask(__name__)
app.wsgi_app = proxy_fix.ProxyFix(app.wsgi_app)

# csp two (Base uri) use cookie 35b962711bba81642996a3b3336523c0afd4660b


csp = { 'default-src': ['\'self\''], \
        'script-src':['\'self\''], \
        'connect-src': '*', \
        'style-src-elem': ['\'self\'','fonts.googleapis.com fonts.gstatic.com'], \
        'font-src': ['\'self\'','fonts.gstatic.com fonts.googleapis.com']
    }

nonce_list = ['script-src','script-src-elem']

# Note swapping proxy fix for Talisman, needed for CSP nonce
Talisman(app, content_security_policy=csp, content_security_policy_nonce_in=nonce_list, force_https=False)

@app.route('/')
@app.route('/xss-two')
def xssTwo():
    return render_template('xss-two.html')


@app.route('/xss-two-result', methods=['POST', 'GET'])
def xssTwoResult():
    payload = "None"
    if request.method == 'POST':
        payload = request.form['payload']
        r = requests.post('http://127.0.0.1:3000/submit', data={
                          'url': request.base_url + "?payload=" + urllib.parse.quote(payload)})
    if request.method == 'GET' and 'admin' in request.cookies and request.cookies.get("admin") == u"35b962711bba81642996a3b3336523c0afd4660b":
        payload = request.args.get('payload')
    elif request.method == 'GET':
        app.logger.warning('GET request without valid admin cookie.')
    return render_template('xss-two-result.html', payload=payload)


@app.route('/xss-two-flag', methods=['GET'])
def xssTwoFlag():
    if 'admin' in request.cookies and request.cookies.get("admin") == u"35b962711bba81642996a3b3336523c0afd4660b":
        return "CTF{a11-bas3-b3l0ng-t0-u5}"
    else:
        return "Sorry, admins only!"


app.run(host='0.0.0.0', port=8000)
