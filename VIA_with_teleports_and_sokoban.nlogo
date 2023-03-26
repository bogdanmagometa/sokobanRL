extensions [ table ]

breed [
  agens agen
]

breed [
  hidden-agens hidden-agen
]

breed [
  teleports teleport
]

breed [
  boxes box
]

breed [
  hidden-boxes hidden-box
]

breed [
  box-exits box-exit
]

turtles-own [
  my-box
]

agens-own [
  my-box
]

hidden-agens-own [
  my-box
]

teleports-own [
  is-to-right?
  opposite
  the-other
]

globals [
  u
  actions
  cumulative-reward
  total-cumulative-reward
  no-expers
]

to calc-expected-discounted-sum
  set total-cumulative-reward 0
  set no-expers 0
  foreach (range 1 (num-experiments + 1)) [
    [no-exper] ->
;    setup
    reset-ticks
    ask agens [
      setxy 0 0
      set heading 0
    ]
    set cumulative-reward 0
    repeat num-transitions-per-experiment [
      go
    ]
    set total-cumulative-reward total-cumulative-reward + cumulative-reward
    set no-expers no-exper
  ]
end

to setup
  clear-all
  ;plot 0

  set-default-shape agens "turtle"
  set-default-shape boxes "box"
  set-default-shape box-exits "x"

  ; setup white patches (walls)
  repeat num-red-patches [
    create-white-patch
  ]
  ; setup red patches (game finishes when we go there, reward -10)
  repeat num-red-patches [
    create-red-patch
  ]
  ; setup blue patch (win when go there, reward +10)
  ask patch max-pxcor max-pycor [
    set pcolor blue
    set plabel blue-reward ;"+ 10  "
    set plabel-color black
  ]
  create-agens 1 [
    set color green
    set size 0.7
    ;set shape "turtle"
    setxy 0 0
    set heading 0
    ask patch-here [
      set pcolor black
      set plabel-color white
    ]
  ]

  repeat num-teleport-pairs [
    create-teleport-pair
  ]

  set actions ["left" "right" "forward"]

  ;if abs(main-action-prob + other-actions-prob - 1) > 0.000000001
  ;[ error "The sum of all action probabilities should be equals to 1!" ]

  set u table:make

  set cumulative-reward 0

  ask patches [
    ;if pcolor = red [put-utility pxcor pycor red-reward]
    ;if pcolor = blue [put-utility pxcor pycor blue-reward]
  ]

  reset-ticks
end

to create-white-patch
  let x -1
  let y -1
  ask patches with [pcolor = black and (pxcor != 0 or pycor != 0)] [
    set x pxcor
    set y pycor
    stop
  ]
  if x = -1 and y = -1 [
    error "can't create red patch"
  ]
  ask patch x y [
    set pcolor white
    set plabel "wall  "
    set plabel-color black
  ]
end

to create-red-patch
  let x -1
  let y -1
  ask patches with [pcolor = black and (pxcor != 0 or pycor != 0)] [
    set x pxcor
    set y pycor
    stop
  ]
  if x = -1 and y = -1 [
    error "can't create red patch"
  ]
  ask patch x y [
    set pcolor red
    set plabel red-reward ;" - 10  "
    set plabel-color black
  ]
end

to create-teleport-pair
  let tel-in create-teleport true
  let tel-out create-teleport false
  let c (random 14) * 10 + 6
  ask tel-in [
    set the-other tel-out
    create-link-with tel-out [
      set shape "tunnel"
    ]
    set color c
  ]
  ask tel-out [
    set the-other tel-in
    set color c
  ]
end

to-report create-teleport [is-teleport-to-right?]
  let x -1
  let y -1
  ask patches with [pcolor = black and (count turtles-here with [breed = teleports]) = 0] [
    set x pxcor
    set y pycor
    stop
  ]
  if x = -1 and y = -1 [
    error "can't create teleport"
  ]
  ifelse is-teleport-to-right? [
    set-default-shape teleports "teleport-in"
  ] [
    set-default-shape teleports "teleport-out"
  ]
  let tel 0
  create-teleports 1 [
    setxy x y
    set is-to-right? is-teleport-to-right?
    set tel self
  ]
  report tel
end

to go
  tick
  let my-turtle 0
  ask hidden-agens [die]
  ask hidden-boxes [die]
  create-hidden-agens 1 [
    set my-turtle self
    set hidden? true
  ]
  create-hidden-boxes 1 [
    ask my-turtle [
      set my-box myself
    ]
    set hidden? true
  ]
  ask agens [
    let best-action 0
    ask my-turtle [
      set heading [heading] of myself
      set xcor [xcor] of myself
      set ycor [ycor] of myself
    ]
    ask [my-box] of my-turtle [
      set xcor ([xcor] of ([my-box] of myself))
      set ycor ([ycor] of ([my-box] of myself))
    ]
    ask my-turtle [
      set best-action first get-best-action
      let util item 1 get-best-action
    ]
    let reward run-action best-action
    set cumulative-reward cumulative-reward + ((gamma) ^ (ticks - 1)) * reward
  ]
  ask [my-box] of my-turtle [die]
  ask my-turtle [die]
  ;wait 1
end

to-report check-constraints [x y]
  let f true

  ifelse (x > max-pxcor) or (x < min-pxcor) or (y > max-pycor) or (y < min-pycor) [
    set f false
  ] [
    let pat patch x y
    if ([pcolor] of pat = white) [
      set f false
    ]
  ]
  report f
end

; This function was not used
;to-report get-actions-and-utilities
;  let x xcor
;  let y ycor
;  let best-action 0
;  let best-utility -10000
;  let possible-actions actions
;
;  let action-and-utilities table:make
;
;  foreach possible-actions [
;    [a] ->
;    run-action-deterministic a  ; take action
;    let utility get-utility xcor ycor
;    if (utility > best-utility)[
;      set best-action a
;      set best-utility utility
;    ]
;    setxy x y
;    table:put action-and-utilities a utility
;  ]
;  report action-and-utilities
;end

to-report run-action [ action ]
  let r random-float 1
  if action = "forward" [
    if r < p [
      report run-action-deterministic action
    ]
    report run-action-deterministic "stay"
  ]

  if action = "right" [
    ifelse r < q [
      report run-action-deterministic "right"
    ] [
      report run-action-deterministic "left"
    ]
  ]

  if action = "left" [
    ifelse r < q [
      report run-action-deterministic "left"
    ] [
      report run-action-deterministic "right"
    ]
  ]
  error "This should not be called: "
end

to-report box-move-forward [my-agen]
    if (count box-exits > 1) [
      error "There should be only one exit"
    ]

    let tel one-of (turtles-here with [breed = teleports])
    if tel != nobody [
      if ([is-to-right?] of tel and heading = 90) or ((not [is-to-right?] of tel and heading = 270)) [
        ; we teleport
        let the-othr ([the-other] of tel)
        ifelse (member? my-agen (turtles-on [patch-here] of the-othr)) [
          ;report false
          report 0
        ] [
          setxy [xcor] of the-othr [ycor] of the-othr
          ;report true
          ifelse member? one-of box-exits ([turtles-here] of patch-here) [
            report box-exit-reward
          ] [
            report 0
          ]
        ]
      ]
    ]
    ;no teleport
    let new-x xcor + dx
    let new-y ycor + dy
    ;print "box moving forward"
    ifelse (check-constraints new-x new-y) [
      fd 1
      ;report true
      ifelse (member? one-of box-exits ([turtles-here] of patch-here)) [
        report box-exit-reward
      ] [
        report 0
      ]
    ] [
      report 0
    ]
end

to-report agen-move-forward
    let tel one-of (turtles-here with [breed = teleports])
    if tel != nobody [
      if ([is-to-right?] of tel and heading = 90) or ((not [is-to-right?] of tel and heading = 270)) [
        ; we teleport
        let the-othr ([the-other] of tel)
        ifelse (member? my-box (turtles-on [patch-here] of the-othr)) [
          report -1
        ] [
          setxy [xcor] of the-othr [ycor] of the-othr
          report teleport-reward
        ]
      ]
    ]
    ;no teleport
    let new-x xcor + dx
    let new-y ycor + dy
    ifelse (check-constraints new-x new-y and not member? my-box (turtles-on patch new-x new-y)) [
      fd 1
      if pcolor = black [
        report black-reward
      ]
      if pcolor = red [
        report red-reward
      ]
      if pcolor = blue [
        report blue-reward
      ]
    ] [
      report -1
    ]
end

to-report get-patch-ahead
  let tel one-of (turtles-here with [breed = teleports])
  if tel != nobody [
    if ([is-to-right?] of tel and heading = 90) or ((not [is-to-right?] of tel and heading = 270)) [
      ; we teleport
      let the-othr ([the-other] of tel)
      report [patch-here] of the-othr
    ]
  ]
  ;no teleport
  let new-x xcor + dx
  let new-y ycor + dy
  ifelse (check-constraints new-x new-y) [
    report patch new-x new-y
  ] [
    report patch-here
  ]
end

to-report run-action-deterministic [ action ]
  if (action = "left") [
    left 90
    report -1
  ]
  if (action = "right") [
    right 90
    report -1
  ]
  if (action = "forward") [
    let patch-ahed get-patch-ahead
    let reward-from-box 0
    if patch-ahed != patch-here and member? my-box turtles-on patch-ahed [
      ask my-box [
        set heading [heading] of myself
        set reward-from-box box-move-forward myself
      ]
    ]
    let reward-from-agen agen-move-forward
    report reward-from-box + reward-from-agen
  ]
  if (action = "stay") [
    report -1
  ]
  error "This should not be called"
end

to-report get-reward
  let reward 0
  if (pcolor = red) [set reward red-reward]
  if (pcolor = blue) [set reward blue-reward]
  if (pcolor = black) [set reward black-reward]
 ; if (pcolor = white) [report -100]
  ;if any? neighbors with [pcolor = red] [
  ;  set reward reward - 10
  ;]
  report reward
end

to value-iteration
  let delta 10000
  let my-turtle 0
  let my-box-of-my-turtle 0
  ask hidden-boxes [die]
  ask hidden-agens [die]
  create-hidden-boxes 1 [
    set my-box-of-my-turtle self
    set hidden? true
  ]
  create-hidden-agens 1 [
    set my-turtle self
    set hidden? true
    set my-box my-box-of-my-turtle
  ]
  let new-values table:make
  while [delta > epsilon * (1 - gamma) / gamma][
    set delta 0
    ask patches with [pcolor = black or pcolor = red or pcolor = blue][ ;TODO: should i include red?
      foreach (list 90 180 270 0) [
        [cur_heading] ->
        foreach (range min-pxcor (max-pxcor + 1)) [
          [cur_box_xcor] ->
          foreach (range min-pycor (max-pycor + 1)) [
            [cur_box_ycor] ->
            let cur_box_patch patch cur_box_xcor cur_box_ycor
            if (((pxcor != [pxcor] of cur_box_patch) or (pycor != [pycor] of cur_box_patch)) and ([pcolor] of cur_box_patch = black or [pcolor] of cur_box_patch = red or [pcolor] of cur_box_patch = blue)) [
              let x pxcor
              let y pycor
              let best-action 0
              ask my-turtle [
                setxy x y
                set heading cur_heading
                ask my-box [
                  set xcor cur_box_xcor
                  set ycor cur_box_ycor
                ]
                let best-utility item 1 get-best-action
                let current-utility get-utility x y cur_heading cur_box_xcor cur_box_ycor
                table:put new-values (list x y cur_heading cur_box_xcor cur_box_ycor) best-utility
                ;             put-utility x y cur_heading best-utility
                if (abs (current-utility - best-utility) > delta)[
                  set delta abs (current-utility - best-utility)
                ]
                ;set plabel (precision best-utility 1)
              ]
            ]
          ]
        ]
      ]
    ]
    set u new-values
    plot delta
  ]
  ask [my-box] of my-turtle [die]
  ask my-turtle [die]
end

to-report get-reward-plus-utility-for-deteministic-action [a]
  let x xcor
  let y ycor
  let init-heading heading
  let box-x [xcor] of my-box
  let box-y [ycor] of my-box

  let reward run-action-deterministic a
  let new-utility get-utility xcor ycor heading [xcor] of my-box [ycor] of my-box

  set xcor x
  set ycor y
  set heading init-heading
  ask my-box [
    set xcor box-x
    set ycor box-y
  ]

  report reward + gamma * new-utility

end

to-report get-best-action
  ;let x xcor
  ;let y ycor
  ;let initial-heading heading
  ;let box-x [xcor] of my-box
  ;let box-y [ycor] of my-box

  let best-action 0
  let best-utility -10000
  foreach actions [
    [a] ->

    let opposite-action 0
    if a = "left" [
      set opposite-action "right"
    ]
    if a = "right" [
      set opposite-action "left"
    ]
    if a = "forward" [
      set opposite-action "stay"
    ]

    let first-det-action-utility (get-reward-plus-utility-for-deteministic-action a)
    let second-det-action-utility (get-reward-plus-utility-for-deteministic-action opposite-action)
    let utility-of-action 0
    ifelse a = "forward" [
      set utility-of-action p * first-det-action-utility + (1 - p) * second-det-action-utility
    ] [
      set utility-of-action q * first-det-action-utility + (1 - q) * second-det-action-utility
    ]


    if (utility-of-action > best-utility)[
      set best-action a
      set best-utility utility-of-action
    ]
    ;setxy x y
   ]
  report (list best-action best-utility)
end

to take-best-action
  let best-action first get-best-action
  let reward run-action best-action
end

to put-utility [x y headin box_xcor box_ycor utility]
  let state (list x y headin box_xcor box_ycor)
  table:put u state utility
end

to-report get-utility [x y headin box_xcor box_ycor]
  let state (list x y headin box_xcor box_ycor)
  if (table:has-key? u state) [
    report table:get u state
  ]
  put-utility x y headin box_xcor box_ycor 0
  report table:get u state
end

to update-box
  let sx box-start-xcor
  let sy box-start-ycor
  let ex box-exit-xcor
  let ey box-exit-ycor
  let sp patch sx sy
  let ep patch ex ey
  if sp = nobody [
    error ( word "No patch with such coordinates exists: " sx " " sy )
  ]
  if ep = nobody [
    error ( word "No patch with such coordinates exists: " ex " " ey )
  ]
  if [pcolor] of sp = white or [pcolor] of sp = red or [pcolor] of ep = blue [
    error ( word "Box start position cannot be white, blue or red patch" )
  ]
  if [pcolor] of ep = white or [pcolor] of ep = red or [pcolor] of ep = blue [
    error ( word "Box exit position cannot be white, blue or red patch" )
  ]
  ask boxes [ die ]
  ask box-exits [ die ]
  create-boxes 1 [
    setxy sx sy
    ask turtle 0 [
      set my-box myself
    ]
  ]
  create-box-exits 1 [
    setxy ex ey
  ]
end

; THESE ARE FOR BEHAVIOR SPACE ONLY
to-report get-patches-representation
  let l []
  foreach sort patches [
    [a] ->
    ask a [
      let c -1
      if pcolor = white [
        set c "white"
      ]
      if pcolor = black [
        set c "black"
      ]
      if pcolor = red [
        set c "red"
      ]
      if pcolor = blue [
        set c "blue"
      ]
      set l lput (list pxcor pycor c) l
    ]
  ]
  report l
end
to-report get-teleports-representation
  let tels []
  ask teleports [
    let tel1 self
    let tel2 the-other
    if [is-to-right?] of tel1 [
      set tels lput (list [xcor] of tel1 [ycor] of tel1 [xcor] of tel2 [ycor] of tel2) tels
    ]
  ]
  report tels
end
to-report get-params-representation
  let lst (list
    (list "blue-reward" blue-reward)
    (list "red-reward" red-reward)
    (list "black-reward" black-reward)
    (list "teleport-reward" teleport-reward)
    (list "p" p)
    (list "q" q)
    (list "epsilon" epsilon)
    (list "gamma" gamma)
  )
  report lst
end
@#$#@#$#@
GRAPHICS-WINDOW
338
10
1003
676
-1
-1
32.85
1
10
1
1
1
0
0
0
1
0
19
0
19
0
0
1
ticks
30.0

BUTTON
42
63
115
96
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
124
63
195
96
go once
if count boxes = 0 or count box-exits = 0 [\n  error \"Please, use update-box button to set correct box and box exit positions\"\n]\ngo
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
58
289
157
349
blue-reward
10.0
1
0
Number

INPUTBOX
164
420
268
480
q
0.7
1
0
Number

INPUTBOX
164
352
266
412
p
0.8
1
0
Number

INPUTBOX
58
353
156
413
red-reward
-10.0
1
0
Number

INPUTBOX
59
420
159
480
black-reward
-1.0
1
0
Number

INPUTBOX
1119
66
1280
126
epsilon
1.0
1
0
Number

INPUTBOX
1119
141
1280
201
gamma
0.95
1
0
Number

BUTTON
1118
27
1272
60
value-iteration
if count boxes = 0 or count box-exits = 0 [\n  error \"Please, use update-box button to set correct box and box exit positions\"\n]\nvalue-iteration
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
1062
208
1382
414
delta
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"pen-0" 1.0 0 -16777216 true "" ""

BUTTON
207
63
270
96
go
if count boxes = 0 or count box-exits = 0 [\n  error \"Please, use update-box button to set correct box and box exit positions\"\n]\ngo
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1087
615
1338
648
calc-expected-discounted-sum
if count boxes = 0 or count box-exits = 0 [\n  error \"Please, use update-box button to set correct box and box exit positions\"\n]\ncalc-expected-discounted-sum
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1081
659
1363
704
expected discounted (cumulative) reward
total-cumulative-reward / no-expers
17
1
11

SLIDER
20
721
201
754
num-teleport-pairs
num-teleport-pairs
0
10
4.0
1
1
NIL
HORIZONTAL

SLIDER
20
642
200
675
num-red-patches
num-red-patches
0
30
30.0
1
1
NIL
HORIZONTAL

SLIDER
20
681
201
714
num-white-patches
num-white-patches
0
30
30.0
1
1
NIL
HORIZONTAL

INPUTBOX
166
288
266
348
teleport-reward
-2.0
1
0
Number

INPUTBOX
1114
551
1295
611
num-transitions-per-experiment
1000.0
1
0
Number

INPUTBOX
1114
485
1275
545
num-experiments
1000.0
1
0
Number

MONITOR
1115
713
1307
758
NIL
cumulative-reward
17
1
11

SLIDER
16
119
165
152
box-start-xcor
box-start-xcor
min-pxcor
max-pxcor
6.0
1
1
NIL
HORIZONTAL

SLIDER
15
152
165
185
box-start-ycor
box-start-ycor
min-pycor
max-pycor
18.0
1
1
NIL
HORIZONTAL

SLIDER
178
119
311
152
box-exit-xcor
box-exit-xcor
min-pxcor
max-pxcor
19.0
1
1
NIL
HORIZONTAL

SLIDER
177
152
311
185
box-exit-ycor
box-exit-ycor
min-pycor
max-pycor
0.0
1
1
NIL
HORIZONTAL

BUTTON
18
192
131
225
update-box
let sx box-start-xcor\nlet sy box-start-ycor\nlet ex box-exit-xcor\nlet ey box-exit-ycor\nlet sp patch sx sy\nlet ep patch ex ey\nif count agens = 0 [\n  error \"Please run setup first to set up the field\"\n]\nif member? (one-of agens) (turtles-on sp) [\n  error \"You can't place box on the same patch with agent\"\n]\nif sp = nobody [\n  error ( word \"No patch with such coordinates exists: \" sx \" \" sy )\n]\nif ep = nobody [\n  error ( word \"No patch with such coordinates exists: \" ex \" \" ey )\n]\nif [pcolor] of sp = white or [pcolor] of sp = red or [pcolor] of ep = blue [\n  error ( word \"Box start position cannot be white, blue or red patch\" )\n]\nif [pcolor] of ep = white or [pcolor] of ep = red or [pcolor] of ep = blue [\n  error ( word \"Box exit position cannot be white, blue or red patch\" )\n]\nupdate-box
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
1301
29
1546
179
NOTE:\nAfter performing value-iteration for a fixed distribution of red, white, blue patches, teleports and a fixed box exit, the model learns how to efficiently move the box for any position of the box, so feel free to update box-start-xcor, and box-start-ycor arbitrarily after running value-iteration
12
0.0
1

TEXTBOX
135
192
319
222
update-box updates positions of box and box-exit
12
0.0
1

TEXTBOX
10
102
411
120
------------------------------------------------------------------------------
12
0.0
1

TEXTBOX
321
110
336
260
|\n|\n|\n|\n|\n|\n|\n|
12
0.0
1

TEXTBOX
10
222
384
240
------------------------------------------------------------------------------
12
0.0
1

TEXTBOX
7
110
22
260
|\n|\n|\n|\n|\n|\n|\n|
12
0.0
1

INPUTBOX
58
486
158
596
box-exit-reward
1000.0
1
0
Number

TEXTBOX
168
491
265
604
box-exit-reward is a reward given when the position of box becomes the position of box-exit
12
0.0
1

TEXTBOX
214
658
306
775
These values are used when running setup command
12
0.0
1

TEXTBOX
1069
450
1425
496
------------------------------------------------------------------------------
12
0.0
1

TEXTBOX
1381
457
1407
772
|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|
12
0.0
1

TEXTBOX
1067
457
1086
772
|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|
12
0.0
1

TEXTBOX
1070
765
1418
806
------------------------------------------------------------------------------
12
0.0
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

teleport-in
false
9
Polygon -13791810 true true 195 225 270 300 270 75 195 0 195 225
Rectangle -13791810 true true 180 30 180 30
Polygon -13345367 true false 195 0 225 0 300 75 300 300 270 300 270 75 195 0
Polygon -955883 true false 120 120 120 180 180 180 180 225 240 150 180 75 180 120 135 120

teleport-in-outdated
false
8
Polygon -13791810 true false 210 225 270 270 270 75 210 30 210 225
Polygon -955883 true false 180 135 180 165 225 165 225 180 255 150 225 120 225 135 180 135
Rectangle -13791810 true false 180 30 180 30
Polygon -13345367 true false 210 30 225 30 285 75 285 270 270 270 270 75 210 30

teleport-out
false
9
Polygon -13791810 true true 30 300 105 225 105 0 30 75 30 225
Rectangle -13791810 true true 180 30 180 30
Polygon -13345367 true false 75 0 105 0 30 75 30 300 0 300 0 75 75 0
Polygon -955883 true false 195 135 195 195 120 195 120 240 60 165 120 90 120 135 195 135

teleport-out-outdated
false
8
Polygon -955883 true false 90 120 90 180 135 180 135 225 195 150 135 75 135 120 90 120
Polygon -13345367 true false 0 225 75 300 75 75 0 0 0 225
Rectangle -13791810 true false 180 30 180 30
Polygon -13791810 true false 0 0 30 0 105 75 105 300 75 300 75 75 0 0

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="game-representation" repetitions="1" runMetricsEveryStep="false">
    <setup>value-iteration</setup>
    <timeLimit steps="1"/>
    <metric>get-patches-representation</metric>
    <metric>get-teleports-representation</metric>
    <metric>get-params-representation</metric>
    <metric>u</metric>
    <enumeratedValueSet variable="black-reward">
      <value value="-1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-transitions-per-experiment">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gamma">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-reward">
      <value value="-10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="teleport-reward">
      <value value="-2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-white-patches">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="blue-reward">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="epsilon">
      <value value="1.0E-10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-red-patches">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-teleport-pairs">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="q">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-experiments">
      <value value="1000"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="value-iteration-experiments" repetitions="1" runMetricsEveryStep="false">
    <setup>if epsilon = 50 [
set u table:make
]
reset-ticks
value-iteration
ask agens [
setxy 0 0
set heading 0
]
calc-expected-discounted-sum</setup>
    <timeLimit steps="1"/>
    <metric>table:get u (list 0 0 0)</metric>
    <metric>total-cumulative-reward / no-expers</metric>
    <enumeratedValueSet variable="black-reward">
      <value value="-1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-transitions-per-experiment">
      <value value="1000"/>
    </enumeratedValueSet>
    <steppedValueSet variable="gamma" first="0.05" step="0.05" last="0.95"/>
    <enumeratedValueSet variable="red-reward">
      <value value="-10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="teleport-reward">
      <value value="-2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-white-patches">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="blue-reward">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="epsilon">
      <value value="50"/>
      <value value="30"/>
      <value value="20"/>
      <value value="10"/>
      <value value="0.8"/>
      <value value="0.4"/>
      <value value="0.1"/>
      <value value="0.01"/>
      <value value="1.0E-5"/>
      <value value="1.0E-12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-red-patches">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-teleport-pairs">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="q">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-experiments">
      <value value="1000"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

tunnel
1.0
-0.2 1 2.0 2.0
0.0 1 1.0 0.0
0.2 1 2.0 2.0
link direction
true
0
@#$#@#$#@
0
@#$#@#$#@
