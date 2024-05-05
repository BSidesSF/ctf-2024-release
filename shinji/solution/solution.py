import hashlib
import time

i = 1577865600
while i < 1735718400:
    string_to_hash = "shinji-" + str(i)
    md5_hash = hashlib.md5(string_to_hash.encode()).hexdigest()
    sha1_hash = hashlib.sha1(md5_hash.encode()).hexdigest()
    if sha1_hash == "75b1d234851cdc94899eae8c97adce769e8ddb26":
        print("CTF{"+ str(i) + "}")
        break
    i = i + 1