* You need to trigger an error
* You can do this by making a call with an invalid range_start / range_end 
```
/color?range_start=aaaaaaaaaaaaaaaaaaa&range_end=C7
```

* Take the access token from the exception
* Make a call to the [Google Sheets API](https://developers.google.com/sheets/api/guides/concepts) using the access token to fetch the second sheet which has the flag.


For a quick solve run,
```
python solution.py https://color-picker-5861f5ad.challenges.bsidessf.net/
```
