# Missing Characters Writeup

Structured as a relatively easy challenge, the idea of missing characters is to 
identify missing elements from multiple arrays to string together the flag. 

The ciphertext contains a 2-Dimensional Array where each sub-array contains 254 elements. 
As the name suggests, 254 elements is just 1 less than the total 255 elements of an ASCII table. 

We can whip up a quick script in any programming language to iterate over each subarray 
and identify the missing element. Once identified, simply convert the numerical value
to its corresponding value in an ASCII table to reveal the flag. 
