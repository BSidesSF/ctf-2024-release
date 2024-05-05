import argparse
import random

def encodeSecret(secret: str) -> list:
    ciphertext = []
    for char in secret:
        listMissingChar = list(range(1, 256))
        listMissingChar.remove(ord(char))
        random.shuffle(listMissingChar)
        ciphertext.append(listMissingChar)
    
    return ciphertext

def decodeSecret(secret: list[int]) -> str:
    sumOfAsciiList = int((255 * 256) / 2)
    cleartext = ''
    for char in secret:
        sumOfCharList = sum(char)
        cleartext += chr(sumOfAsciiList - sumOfCharList)

    return cleartext

if __name__ == "__main__":

    # Parse Command Line Arguments
    parser=argparse.ArgumentParser(description="Missing Characters Encoding & Decoding.")
    parser.add_argument("-e", help="Encode Mode", required=False)
    parser.add_argument("-d", help="Decode Mode", required=False, type=argparse.FileType('r'))
    args=parser.parse_args()

    if not (args.e or args.d):
        print("Error: No arguments provided.")
        parser.print_help()
        exit(1)
    elif args.e:
        cleartext = args.e 
        print(encodeSecret(cleartext))
    elif args.d:
        ciphertext = eval(args.d.read())
        print(decodeSecret(ciphertext))


