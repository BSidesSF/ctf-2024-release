* Every pair you flip over, must match.
* If you have two that don't match, the game state will be set to `INVALID` and you cannot fetch the flag. 
* Thankfully, the HTML source will reveal the card values. 
```
<div class="memory-card" data-id="0" data-value="5">
                            <img class="front-face" src="/static/images/5.png" alt="BSidesSF" />
                            <img class="back-face" src="/static/images/back.png" alt="5" />
                        </div>
```
* You can use this to create valid matches. 
```
/match?first_val=5&first_pos=0&second_val=3&second_pos=1
```

For a quick solve run, 
`python solution.py https://match-one-625a6392.challenges.bsidessf.net/ <username>`
`python solution.py https://match-one-625a6392.challenges.bsidessf.net/ corgi`
