* The app will display "It is not the right time!" unless the system date and time is `1615212000L`
* The date/time `Monday, March 8, 2021 6:00:00 AM GMT-08:00` is a reference to the release date of Evangelion: 3.0+1.0 Thrice Upon a Time
* The code for flag computation in kotlin is, 
```
fun flagDisplay(): String {
        var string = getString(R.string.app_string)
        // Magic String that they need to match
        val magicString = "75b1d234851cdc94899eae8c97adce769e8ddb26"
        // Prefix applied before hashing
        val prefixString = "shinji-"
        val sb = StringBuilder()
        // Get the current time in seconds
        val seconds = System.currentTimeMillis() / 1000
        // Check if it is within the acceptable range
        if (seconds < 1577865600L) return string
        if (seconds > 1735718400L) return string
        val secondsString = seconds.toString()
        var tempString = prefixString + secondsString
        val md5Digest = MessageDigest.getInstance("MD5")
        val md5Result = md5Digest.digest(tempString.toByteArray(Charsets.UTF_8))
        for (b in md5Result) {
            sb.append(String.format("%02X", b))
        }
        val md5String = sb.toString().lowercase()
        val sha1Digest = MessageDigest.getInstance("SHA-1")
        val sha1Result = sha1Digest.digest(md5String.toByteArray(Charsets.UTF_8))
        val sb2 = StringBuilder()
        for (b in sha1Result) {
            sb2.append(String.format("%02X", b))
        }
        val sha1String = sb2.toString().lowercase()
        if (sha1String == magicString)
        {
            string = getString(R.string.part_one)
            string += secondsString
            string += getString(R.string.part_three)
        }
        return string
    }

```
* Players can reverse the app, using APKtool or android Studio. 
* The relevant smali section for the magic string 
```  
	.line 25
	.local v1, "string":Ljava/lang/String;
 	const-string v3, "75b1d234851cdc94899eae8c97adce769e8ddb26"
```
 * Relevant smali section for the prefix "shinji-"
```
    .line 27
    .local v3, "magicString":Ljava/lang/String;
    const-string v4, "shinji-"

    .line 28
    .local v4, "prefixString":Ljava/lang/String;
    new-instance v5, Ljava/lang/StringBuilder;

    invoke-direct {v5}, Ljava/lang/StringBuilder;-><init>()V
```
 * Relevant smali section for the timestamp range (1577865600L and 1735718400L)
 ```
 	.line 32
    .local v6, "seconds":J
    const-wide/32 v8, 0x5e0c5180

    cmp-long v8, v6, v8

    if-gez v8, :cond_26

    return-object v1

    .line 33
    :cond_26
    const-wide/32 v8, 0x6774f600

    cmp-long v8, v6, v8

    if-lez v8, :cond_2e

 ```
 * If the current timestamp in seconds is within the range, the app computes `SHA1(MD5("shinji-" + unixtimestamp))`
 * If this matches the magic string then the flag is printed as `CTF{unixtimestamp}` in this case,`CTF{1615212000}`
 * The solution.py will bruteforce the right timestamp within the range and display the flag
 * It takes about 5 mins on a laptop 
