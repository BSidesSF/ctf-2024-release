package main

import (
    "bufio"
    "fmt"
    "io/ioutil"
    "os"
    "path"
    "strings"
    "syscall"
    "math/big"
    cryptor "crypto/rand"
    "strconv"
)

type fullkey struct {
	censor_type int
    fname, lname string
    messages []string
    p, q, n, e, d *big.Int
}


var (
    flag1 string
	flag2 string
    keylist []*fullkey
)


const prog_name = "truthescrow"

const help_text = `

Commands:
    help                 // Prints this help

    help types           // Display help about the censorship types

    listkeys             // Display all current private keys
    genkey               // Generate a new keypair

    listtruth            // Get a list of unread truth
    sendtruth            // Speak truth to a citizen
    readtruth            // Read truth from citizens

    exit                 // Exit the keyservice
`


const help_types_text = `
At the ministry of truth we believe in choice. Your private key
can be censored by masking half of p and q or masking half of d.

Choose "pq" or "d" to select between these.

WAR IS PEACE
FREEDOM IS SLAVERY
IGNORANCE IS STRENGTH
PRIVATE KEYS ARE PUBLIC KEYS
`



func main() {

    startup()

    input := bufio.NewScanner(os.Stdin)
    scanbuffer := make([]byte, 65536)
    input.Buffer(scanbuffer, 65536)


    // Make admin 1 key
    a1key := gen_new_key(1)

    a1key.fname = "Nicholas"
    a1key.lname = "Howgrave-Graham"
    a1key.messages = make([]string, 0)

    a1key.messages = append(a1key.messages, fmt.Sprintf("Nick, don't fight it, you know it to be true %s", flag1))
    keylist = append(keylist, a1key)

	// Make admin 2 key
    a2key := gen_new_key(2)

    a2key.fname = "Nadia Heninger"
    a2key.lname = "Hovav Shacham"
    a2key.messages = make([]string, 0)

    a2key.messages = append(a2key.messages, fmt.Sprintf("Coppersmith has nothing on Nadia and Hovav %s", flag2))
    keylist = append(keylist, a2key)

    fmt.Fprint(os.Stdout, "\nTry \"help\" for a list of commands\n")

    exit := false

    for !exit {
        fmt.Fprintf(os.Stdout, "\n%s> ", prog_name)
        ok := input.Scan()
        if !ok {
            fmt.Fprintln(os.Stdout, "")
            break
        }

        text := input.Text()

        if len(text) == 0 {
            continue
        }

        tokens := strings.Split(text, " ")

        switch tokens[0] {

        case "help":
            if len(tokens) > 1 {
                switch tokens[1] {
                    case "types":
                    fmt.Fprintf(os.Stdout, "%s", help_types_text)

                }
            } else {
                print_help()
            }

        case "h":
            print_help()

        case "?":
            print_help()

        case "listkeys":
            for i, k := range keylist {
                fmt.Fprintf(os.Stdout, "\nCitizen %2d. (%s %s)\n", i, k.fname, k.lname)
				fmt.Fprintf(os.Stdout, "Public n: 0x%s\n", (k.n).Text(16))
				fmt.Fprintf(os.Stdout, "Public e: 0x%s\n", (k.e).Text(16))
				if k.censor_type == 1 {
					cp := new(big.Int).Div(k.p, new(big.Int).Exp(big.NewInt(2), big.NewInt(512), nil))
					cq := new(big.Int).Mod(k.q, new(big.Int).Exp(big.NewInt(2), big.NewInt(512), nil))

					fmt.Fprintf(os.Stdout, "Private p: 0x%s[...]\n", (cp).Text(16))
					fmt.Fprintf(os.Stdout, "Private q: 0x[...]%s\n", (cq).Text(16))
				} else {
					// fmt.Fprintf(os.Stdout, "DEBUG true d: 0x%s\n", (k.d).Text(16))
					cd := new(big.Int).Mod(k.d, new(big.Int).Exp(big.NewInt(2), big.NewInt(1024 + 32), nil))

					fmt.Fprintf(os.Stdout, "Private d: 0x[...]%s\n", (cd).Text(16))
				}
            }

        case "listtruth":
            for i, k := range keylist {
                fmt.Fprintf(os.Stdout, "Citizen %2d. (%s, %s): %d unread truth\n", i, k.fname, k.lname, len(k.messages))
            }

        case "sendtruth":
            fmt.Fprint(os.Stdout, "\nEnter citizen (by number) to send truth? ")
            ok = input.Scan()
            if !ok {
                fmt.Fprintln(os.Stdout, "Error reading input!")
                break
            }
            unum := input.Text()

            intin, err := strconv.Atoi(unum)

            if err != nil {
                fmt.Fprintln(os.Stdout, "Error, could not interpret input as number!")
                break
            }

            if intin < 0 && intin >= len(keylist) {
                fmt.Fprintf(os.Stdout, "Error, citizen %d does not exist!", intin)
                break
            }

            fmt.Fprintf(os.Stdout, "\nTruth for citizen %d? ", intin)
            ok = input.Scan()
            if !ok {
                fmt.Fprintln(os.Stdout, "Error reading input!")
                break
            }
            umsg := input.Text()

            keylist[intin].messages = append(keylist[intin].messages, umsg)

            fmt.Fprintln(os.Stdout, "Truth sent!")


        case "readtruth":
            fmt.Fprint(os.Stdout, "\nEnter citizen (by number) to read unread truth? ")
            ok = input.Scan()
            if !ok {
                fmt.Fprintln(os.Stdout, "Error reading input!")
                break
            }
            unum := input.Text()

            intin, err := strconv.Atoi(unum)

            if err != nil {
                fmt.Fprintln(os.Stdout, "Error, could not interpret input as number!")
                break
            }

            if intin < 0 || intin >= len(keylist) {
                fmt.Fprintf(os.Stdout, "Error, citizen %d does not exist!", intin)
                break
            }

            chal, err := cryptor.Int(cryptor.Reader, new(big.Int).Exp(big.NewInt(2), big.NewInt(128), nil))

            if err != nil {
                fmt.Fprintln(os.Stdout, "Unable to generate random message!")
                os.Exit(1);
            }

            fmt.Fprintf(os.Stdout, "\nWelcome %s(?), before we continue, you must prove it's you\n", keylist[intin].fname)
            fmt.Fprintf(os.Stdout, "\nPlease provide the signature for %s : ", chal.Text(10))
            ok = input.Scan()
            if !ok {
                fmt.Fprintln(os.Stdout, "Error reading input!")
                break
            }

            chal_sig, ok := new(big.Int).SetString(input.Text(), 10)
            if !ok || chal_sig == nil {
                fmt.Fprintln(os.Stdout, "Error parsing provided signature!")
                break
            }

            verify := new(big.Int).Exp(chal_sig, keylist[intin].e, keylist[intin].n)
            if chal.Cmp(verify) != 0 {
                fmt.Fprintln(os.Stdout, "Signature validation failed!")
                //fmt.Fprintln(os.Stdout, "debug: using n: %s\n", keylist[intin].n.Text(10))
                //fmt.Fprintln(os.Stdout, "debug: using e: %s\n", keylist[intin].e.Text(10))
                //fmt.Fprintln(os.Stdout, "debug: got verify of %s\n", verify.Text(10))
                break
            }

            if len(keylist[intin].messages) == 0 {
                fmt.Fprintf(os.Stdout, "%s doesn't have any unread truth\n", keylist[intin].fname)
                break
            }

            for i, m := range keylist[intin].messages {
                fmt.Fprintf(os.Stdout, "Truth %d: %s\n", i + 1, m)
            }
            // clear messages
            keylist[intin].messages = make([]string, 0)


        case "genkey":
            fmt.Fprint(os.Stdout, "\nFirst name? ")
            ok = input.Scan()
            if !ok {
                fmt.Fprintln(os.Stdout, "Error reading input!")
                break
            }
            ufname := input.Text()

            fmt.Fprint(os.Stdout, "\nLast name? ")
            ok = input.Scan()
            if !ok {
                fmt.Fprintln(os.Stdout, "Error reading input!")
                break
            }
            ulname := input.Text()

            gotyn := false
            var censor_type int
            for !gotyn {
                fmt.Fprint(os.Stdout, "\nMask which part of private key (pq / d)? ")
                ok = input.Scan()
                if !ok {
                    fmt.Fprintln(os.Stdout, "Error reading input!")
                    break
                }
                yn := input.Text()

                switch yn {
                case "pq":
                    censor_type = 1
                    gotyn = true
                case "d":
                    censor_type = 2
                    gotyn = true
                default:
                    fmt.Fprint(os.Stdout, "\nAnswer must be either `pq` or `d`. See `help types` for an explanation.")
                }
            }

            fmt.Fprintf(os.Stdout, "\nGenerating key for %s...", ufname)
            ukey := gen_new_key(censor_type)

            ukey.fname = ufname
            ukey.lname = ulname
            ukey.messages = make([]string, 0)
            ukey.messages = append(ukey.messages, fmt.Sprintf("Welcome %s, Big Brother is watching you!", ufname))

            keylist = append(keylist, ukey)

            fmt.Fprintf(os.Stdout, "\n%s, your key is ready!\n", ufname)
            fmt.Printf("Public modulus: %s\n", (ukey.n).Text(10))
            fmt.Printf("Public exponent: %s\n", (ukey.e).Text(10))
            fmt.Printf("Private exponent: %s\n", (ukey.d).Text(10))
			fmt.Printf("Private p: %s\n", (ukey.p).Text(10))
			fmt.Printf("Private q: %s\n", (ukey.q).Text(10))
            fmt.Fprint(os.Stdout, "\n!PRIVATE KEYS ARE PUBLIC KEYS!\n")


        case "exit":
            exit = true

        case "quit":
            exit = true

        case "flag":
            fmt.Fprintf(os.Stdout, "lolz you typed 'flag' but that isn't a command. You didn't really think that was going to work, did you?\n")
            exit = true

        case "^d":
            fmt.Fprintf(os.Stdout, "Uhmmm... You do realize that the '^' in '^d' isn't a literal '^' right??")

        default:
            fmt.Fprintf(os.Stdout, "%s: `%s` command not found. Try \"help\" for a list of commands.", prog_name, tokens[0])

        }
    }

}




func print_help() {
    fmt.Fprintf(os.Stdout, "\n%s help:\n%s", prog_name, help_text)
}


func startup() {

    changeBinDir()
    limitTime(5)

    bannerbuf, err := ioutil.ReadFile("./banner.txt")

    if err != nil {
        fmt.Fprintf(os.Stderr, "Unable to read banner: %s\n", err.Error())
        os.Exit(1)
    }
    fmt.Fprint(os.Stdout, string(bannerbuf))

    fbuf1, err := ioutil.ReadFile("./flag_1.txt")
    if err != nil {
        fmt.Fprintf(os.Stderr, "Unable to read flag 1: %s\n", err.Error())
        os.Exit(1)
    }
    flag1 = string(fbuf1)

	fbuf2, err := ioutil.ReadFile("./flag_2.txt")
    if err != nil {
        fmt.Fprintf(os.Stderr, "Unable to read flag 2: %s\n", err.Error())
        os.Exit(1)
    }
    flag2 = string(fbuf2)

}


// Change to working directory
func changeBinDir() {
    // read /proc/self/exe
    if dest, err := os.Readlink("/proc/self/exe"); err != nil {
        fmt.Fprintf(os.Stderr, "Error reading link: %s\n", err)
        return
    } else {
        dest = path.Dir(dest)
        if err := os.Chdir(dest); err != nil {
            fmt.Fprintf(os.Stderr, "Error changing directory: %s\n", err)
        }
    }
}


// Limit CPU time to certain number of seconds
func limitTime(secs int) {
    lims := &syscall.Rlimit{
        Cur: uint64(secs),
        Max: uint64(secs),
    }
    if err := syscall.Setrlimit(syscall.RLIMIT_CPU, lims); err != nil {
        if inner_err := syscall.Getrlimit(syscall.RLIMIT_CPU, lims); inner_err != nil {
            fmt.Fprintf(os.Stderr, "Error getting limits: %s\n", inner_err)
        } else {
            if lims.Cur > 0 {
                // A limit was set elsewhere, we'll live with it
                return
            }
        }
        fmt.Fprintf(os.Stderr, "Error setting limits: %s", err)
        os.Exit(-1)
    }
}


func gen_new_key(censor_type int) *fullkey {

    key := new(fullkey)

    fails := 0
retry_key:
    p, err := cryptor.Prime(cryptor.Reader, 1024)

    if err != nil {
        fmt.Fprintf(os.Stderr, "Error: unable to generate prime p\n")
        os.Exit(1)
    }

    q, err := cryptor.Prime(cryptor.Reader, 1024)

    if err != nil {
        fmt.Fprintf(os.Stderr, "Error: unable to generate prime q\n")
        os.Exit(1)
    }

    // Check p < q < 2p
    if p.Cmp(q) < 0 {
        if q.Cmp(new(big.Int).Mul(p, big.NewInt(2))) > 0 {
            goto retry_key
        }
    }

    // Now check q < p < 2q
    if q.Cmp(p) < 0 {
        if p.Cmp(new(big.Int).Mul(q, big.NewInt(2))) > 0 {
            goto retry_key
        }
    }

    n := new(big.Int).Mul(p, q)

    pm1 := new(big.Int).Add(p, big.NewInt(-1))
    qm1 := new(big.Int).Add(q, big.NewInt(-1))
    // Carmichael totient function
    // carm := new(big.Int).Div(new(big.Int).Mul(pm1, qm1), new(big.Int).GCD(nil, nil, pm1, qm1))
	// Euler totient function
	euler := new(big.Int).Mul(pm1, qm1)

    var e, d *big.Int

	// make a more traditional key
	e = big.NewInt(65537)

	// d = new(big.Int).ModInverse(e, carm)
	d = new(big.Int).ModInverse(e, euler)

    if d == nil || e == nil {
        if (fails > 5) {
            fmt.Fprintf(os.Stderr, "Error: unable to generate d! Probably (p - 1) or (q - 1) was a multiple of e or d\n")
            os.Exit(1)
        } else {
            fails++
            goto retry_key
        }
    }

    //fmt.Fprintf(os.Stdout, "debug: d: %s\n", d.Text(10))
    //fmt.Fprintf(os.Stdout, "debug: carm: %s\n", carm.Text(10))

	key.p = p
	key.q = q
    key.n = n
    key.e = e
	key.d = d
	key.censor_type = censor_type

    return key
}
