breed [ bees bee ]
breed [ floras flora ]
breed [deer a-deer]
breed [bears bear]
breed [hives hive]

bees-own [
  energy
  inventory
  infected? ; binary
  time-till-death ; how long left before death from parasite
  xcor-hive
  ycor-hive
  foraging? ; are they foraging
]
floras-own [ pollen ]
deer-own[ energy ]
bears-own[ energy ]
hives-own [hive-food
           xcoord
           ycoord]

patches-own [
  plant-amount ;; amount of plant
  hive?        ;; at hive?
  pollinated?  ;; pollinated in last tick
  temp  ;; ave temp
  max-temp
  min-temp
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup
 ca ;; clear

  ;; hives
  setup-hives

  ;; bees
  setup-bees

  ;; flora
  setup-flowers

  ;; deer
  setup-deer

  ;; bears
  setup-bears

  ;; patches
  setup-patches

  reset-ticks
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to go
  if not any? bees [ stop ]

  ;; PATCHES ROUTINE ;;
  ask patches [
    patches-routine
  ]

  ;; BEES ROUTINE ;;
  ask bees[
  ; check bee lifespan
  ask-if-dead-age
  ; die if no energy
  ask-if-dead

  ; hive procedure for those at hive
  hive-procedure

  ;; if warm enough at some point in day for bee to move
    ifelse ( max-temp > 7)[
      ;; indicate that bees are foraging
      set foraging? 1
      ; return to hive if inventory full, else search
      ifelse ( inventory >= max-inv ) [ return-to-hive ][ bee-search ]
    ][
      set foraging? 0
    ]

  ; age bee
  update-time-till-death

  ; infect new bees
  infect

  ; recover some of infected
  recover
  ]


  ;; DEER ROUTINE ;;
  ask deer[
    ask-if-dead
    move-deer
    deer-feed
    reproduce
  ]

  ;; BEAR ROUTINE ;;
    ask bears[
    ask-if-dead
    if (temp >= -1)[ ;; when spring starts bears are mobile
      move-bear
      bear-feed
    ]
    reproduce
  ]


  ;; HIVE ;;
  ask hives[
    ;; recolor if no more food
    recolor-hive
    ;; hatch more bees if enough  food
    hatch-larvae
  ]

  tick
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SETUP PROCEDURES ;;
;; SETUP TURTLES ;;
;; bees
to setup-bees
  ;; uninfected bees
  create-bees number-of-bees * (1 - proportion-infected) [
  set color yellow

  ;; hive co-ords
  set xcor-hive 0
  set ycor-hive  0

  ;; start at hive
  setxy random-xcor random-ycor

  set shape "bee 2"
  set energy random-float 100
  set inventory random max-inv
  set infected? FALSE
  set size 0.75
  set time-till-death 122 + random 31 ;; bees live between 122-152 days
  set foraging? 1
  ]

  ;; infected bees
  create-bees number-of-bees * proportion-infected [
  set color orange

   ;; hive co-ords
  set xcor-hive 0
  set ycor-hive  0

  setxy random-xcor random-ycor
  set shape "bee 2"
  set energy random-float 100
  set inventory max-inv
  set infected? TRUE
  set size 0.75
  set time-till-death random death-time-parasite
  set foraging? 1
  ]
end

;; deer
to setup-deer
  create-deer number-of-deer [
  set color brown - 2
  set shape "moose"
  set size 3
  setxy random-xcor random-ycor
  set energy random-float 100
  ]
end

;; bears
to setup-bears
  create-bears number-of-bears [
  set color black
  set shape "footprint other"
  set size 2.5
  setxy random-xcor random-ycor
  set energy random-float 100
  ]
end


;; hives
to setup-hives
  create-hives 1 [
    set color yellow
    set shape "egg"
    set hive-food random 100
    set size 3
    ;; co-ord to transfer to bees
    let hivex 0
    let hivey 0
    ;; set position
    setxy hivex hivey
    ;; save as turtle porperty
    set xcoord hivex
    set ycoord hivey
  ]
end


;; SETUP PATCHES ;;
to setup-patches
  ask patches [
    set plant-amount random-float 100 ;; between 0 an 100
    set pollinated? random 2 ;; 0 or 1
    recolor-plants
    ;; set temp
    set temp ( random-normal 0 4 ) + ( 11.4 * (cos ((360 / 365) * 0)) ) + 4.1 + temp-incr-factor
    set max-temp ( random-normal 0 4 ) + ( 14.9 * (cos ((360 / 365) * 0)) ) + 8.3 + temp-incr-factor
    set min-temp ( random-normal 0 4 ) + ( 10.45 * (cos ((360 / 365) * 0)) ) - 4.65 + temp-incr-factor
  ]
end

;; recolor the grass to indicate how much remains
to recolor-plants
  ifelse (plant-amount <= 0) [ set pcolor brown] [set pcolor scale-color green (10 - plant-amount) -150 50]
end

to setup-flowers ;; purely aesthetic
  create-floras 0[
  set color pink
  set size 2
  setxy random-xcor random-ycor
  set shape "flower"
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; GO PROCEDURES ;;
;;;;;;;; patches
to patches-routine
  ;; PLANTS
  ifelse ( pollinated? = 1 )[ regrow ][ age-plant ]
  ;; reset pollinated indicator
  set pollinated? 0
  recolor-plants
  update-temp
end

; regrowth and aging of plants
to regrow
  ifelse ( max-temp > 5.9 )[
    let x 2
    (ifelse ((plant-amount * (1 + x * plant-regrowth-rate)) < 100)[
      set plant-amount (plant-amount * (1 + x * plant-regrowth-rate))][set plant-amount 100])
  ][
    let x 1
    (ifelse ((plant-amount * (1 + x * plant-regrowth-rate)) < 100)[
      set plant-amount (plant-amount * (1 + x * plant-regrowth-rate))][set plant-amount 100])
  ]
end

to age-plant
  ifelse ( plant-amount * ( 1 - plant-death-rate ) > 0 )[ set plant-amount plant-amount * ( 1 - plant-death-rate ) ][set plant-amount 0]
end


;;; temperature
to update-temp
  set temp ( random-normal 0 1 ) + ( 11.4 * (cos ((360 / 365) * ticks)) ) + 4.1 + temp-incr-factor
  set max-temp ( random-normal 0 1 ) + ( 14.9 * (cos ((360 / 365) * ticks)) ) + 8.3 + temp-incr-factor
  set min-temp ( random-normal 0 1 ) + ( 10.45 * (cos ((360 / 365) * ticks)) ) - 4.65 + temp-incr-factor
end

;;;;;;;;;;;;;; turtles
;;; general
;; ask if  dead based on energy
to ask-if-dead
    if ( energy <= 0 ) [ die ]
end

;;;;;; bees
; what to do at hive
to hive-procedure
  ; if at hive
  if (any? hives-here )[
    let my-home one-of hives
    ;if there because of full inventory
    if (inventory >= max-inv)[
      ;; store inventory
      let new-food inventory
      ; drop inventory
      set inventory 0
      ; increase food in hive
      ask my-home [ set hive-food hive-food + new-food ]
      ; feed at hive
      beefeed
    ]
  ]
end

; what to do if inventory full
to return-to-hive
  ;; face hive
  facexy xcor-hive ycor-hive
  ;; move forward
  fd random 3
  ;; energy expense
  set energy energy - 0.1 * inventory
  ;; feed on way home
  if ( plant-amount > 0 ) [
    beefeed
    set pollinated? 1
  ]
end

; when bees earch for food
to bee-search
  ; move
  bee-move
  if ( plant-amount > 0 )[
  ; feed
  beefeed
  ; pollinate
  pollinate
  ; collect
  set inventory inventory + 1
  ]
end

to bee-move
  ;;random rotation
  rt random-float 90
  lt random-float 90
  ;; move forward
  fd random-float 2
  ;; energy expense
  set energy energy - 0.1 * inventory
end

to beefeed
  if energy < 100[
    ifelse ( energy + 1 < 100 )[ set energy energy + 1 ][ set energy 100 ]
  ]
end

to pollinate
  set pollinated? 1
end

;; spreading of parasites among bees
to spread-parasite
  if (infected? = TRUE)[
    if any? bees-here[
    let new-infections bees-here
      ask new-infections[
        set infected? TRUE
        set color orange
        set time-till-death 0.5 * time-till-death
      ]
    ]
  ]
end

;; new infections as result of high temp
to infect
  if max-temp > min-temp-for-infection + random 10 [
    if not infected?[
      let outcome random 2 ;; 0 or 1
      ifelse outcome = 1 [
        set infected? TRUE
        set time-till-death time-till-death * random-float 0.9
      ][
        set infected? FALSE]
    ]
  ]
end

;; bees that recover
to recover
  if infected? [
    if energy > recovery-energy[ set infected? FALSE ]
  ]
end

;; setting  time-till-death based on presence of parasite
to update-time-till-death
    set time-till-death time-till-death - 1
end

;; ask if dead based on time-till-death
to ask-if-dead-age
  if (time-till-death <= 0)[ die ]
end

to reproduce-bees
  if ( energy > 80 ) [
    set energy energy - 50
    hatch 1 [
      set energy 100
      setxy 0 0
      set infected? FALSE
      set foraging? 0
      set time-till-death 122 + random 31 ;; bees live between 122-152 days
    ]
  ]
end

;;;; deer
to move-deer ;;
  ;;random rotation
  rt random-float 90
  lt random-float 90
  ;; move forward
  fd random-float 10
  ;; energy expense
  set energy energy - 1
end

to deer-feed
  if energy < 100[
    ifelse energy + 1 < 100 [ set energy energy + 1 ][ set energy 100 ]
    set plant-amount plant-amount - 1
  ]
end

to reproduce
  if ( energy > 70 ) [
    set energy energy - 50
    hatch 1 [ set energy random-float 100 ]
  ]
end

;;;; bears
to bear-feed
  if (energy <= 100 )[  if (any? hives-here) [
    let this-hive one-of hives
    ;; raid hive if there is any hive food
    ask this-hive [ if ( hive-food > 0) [set hive-food 0]
      ask bears [set energy energy + 2]]
  ]
    ifelse (any? deer-here) [
      let target one-of deer
      ask target [ die ]
      set energy energy + 4
    ][
      if plant-amount > 0[
        set plant-amount plant-amount - 5
        set energy energy + 1
    ]
  ]]
  if energy > 100 [set energy 100]
end

to move-bear ;;
  ;;random rotation
  rt random-float 90
  lt random-float 90
  ;; move forward
  fd random-float 50
  ;; energy expense
  set energy energy - 1
end

;;;; hive
;; color hive
to recolor-hive
   ifelse (hive-food > 0 ) [ set color yellow ] [ set color brown ]
end

;; if sufficient hive food, hatch new bees
to hatch-larvae
  if (hive-food > 100)[
    ask bees [ reproduce-bees ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
751
552
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-20
20
-20
20
0
0
1
ticks
30.0

BUTTON
5
37
71
70
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
115
35
178
68
NIL
go\n
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
773
13
973
163
Population
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"bees" 1.0 0 -4079321 true "" "plot count bees  / 50"
"plants" 1.0 0 -14439633 true "" "plot sum [plant-amount] of patches / 1000"
"deer" 1.0 0 -10402772 true "" "plot count deer * 3"
"bears" 1.0 0 -13628663 true "" "plot count bears * 3"

SLIDER
7
219
179
252
number-of-bees
number-of-bees
0
400
150.0
50
1
NIL
HORIZONTAL

SLIDER
7
260
179
293
max-inv
max-inv
0
100
20.0
1
1
NIL
HORIZONTAL

SLIDER
8
128
179
161
number-of-deer
number-of-deer
0
100
60.0
1
1
NIL
HORIZONTAL

SLIDER
2
411
187
444
plant-regrowth-rate
plant-regrowth-rate
0
0.5
0.25
0.01
1
NIL
HORIZONTAL

SLIDER
0
449
188
482
plant-death-rate
plant-death-rate
0
0.1
0.03
0.01
1
NIL
HORIZONTAL

SLIDER
7
90
179
123
number-of-bears
number-of-bears
0
10
5.0
1
1
NIL
HORIZONTAL

SLIDER
989
323
1187
356
temp-incr-factor
temp-incr-factor
0
2
2.0
0.01
1
NIL
HORIZONTAL

PLOT
986
167
1186
317
Temperature 
NIL
NIL
0.0
10.0
1.0
-1.0
true
true
"" ""
PENS
"Max" 1.0 0 -955883 true "" "plot sum [max-temp] of patches / count patches"
"Ave" 1.0 0 -7500403 true "" "plot sum [temp] of patches / count patches"
"Min" 1.0 0 -13791810 true "" "plot sum [min-temp] of patches / count patches"

SLIDER
7
299
181
332
proportion-infected
proportion-infected
0
1
0.0
0.1
1
NIL
HORIZONTAL

PLOT
773
167
973
317
Bee Health
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Infected" 1.0 0 -2674135 true "" "if count bees > 0 [\nplot(count bees with [infected?])/(count bees)\n]"
"Healthy" 1.0 0 -13840069 true "" "if count bees > 0 [\nplot(count bees with [not infected?])/(count bees)\n]"

SLIDER
7
342
180
375
death-time-parasite
death-time-parasite
0
100
60.0
10
1
NIL
HORIZONTAL

SLIDER
774
324
974
357
min-temp-for-infection
min-temp-for-infection
0
15
5.0
5
1
NIL
HORIZONTAL

PLOT
983
10
1183
160
Foraging?
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
"default" 1.0 0 -16777216 true "" "plot sum [foraging?] of bees"

SLIDER
773
369
974
402
recovery-energy
recovery-energy
0
100
60.0
10
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This simulation aims to model the spread of parasites among a bee population within the context of a particular ecosystem, namely the Kootenay National Park in British Columbia, Canada. A microcosm of this ecosystem is created where the fauna relevant to the bee population are also simulated.

## HOW IT WORKS

Our simulation shows wild honey bees, various species of smaller mammals (deer) and bears interact in a landscape. 

If any of the live agents run out of energy they die. Deer and bears roam the landscape in search of food. This movement comes at an energy cost. Deer feed on plants where required to replenish their energy. Bears are omnivores who will feed on any of plants, deer, or beehives. However, there is a hierarchy involved in their food choice. Bears have a well-documented fondness for feeding on hives, and will choose hives ahead of deer and plants. When a bear raids a hive, the hives food supply is depleted, and the bees will swarm with their queen to a nearby site to create a new hive. We assume that this is in the same patch as the original hive. Next in line are deer, and if no other food source is available bears will feed on plants.

Bears are prompted by low temperatures to go into hibernation, where they will not move or hunt. They rely on energy stores from the warmer months during this time, and may reproduce if they have sufficient energy to do so. Although some smaller mammals go into hibernation, there are some that will move around and feed in winter, so the deer in our simulation will continue to move and feed during the colder months.

Bees are immobile at temperatures below 7 degrees Celsius. However, if there is a sufficiently warm point in the day, bees forage nectar and pollen among the plants in the landscape, which they then transport to the hive for honey production. This movement comes at an energy cost, which is replenished by feeding on nectar and pollen as they forage. While the bees go about their work they also pollinate the plants, facilitating their growth. Without this process the plants in each patch age and wither away. If a plant is pollinated, it will grow at a certain rate depending on the temperature. Once a bee’s inventory is full they return to the hive, feeding on plants (and pollinating) along the way where needed. They may also feed at the hive if there is sufficient food available. 

Given their short lifespan in the context of the simulation, bees are also assigned a lifetime (in days) after which they die. We use this attribute to examine the bee population as its members become infected by parasites. When a bee is infected by the parasite, its time till death is reduced. Infection occurs with greater probability in nature at warmer temperatures, and is passed from bee to bee when on the same patch independent of temperature. An infected bee may recover if they have sufficient energy. 

The hive itself is also an agent. When there is sufficient food in the hive, larvae are hatched.

## HOW TO USE IT

Use the NUMBER-OF-BEES, -BEARS, and -DEERS sliders to choose initial population size. You can also adjust the initial PROPORTION-INFECTED of bees, and the DEATH-TIME-PARASITE (the maximum time till death as a result of initial infection) for those initially infected. Then, press SETUP to create the initial population with these settings. 

The remaining sliders can be used to adjust other parameters in the model.
MAX-INV determines how much pollen and nectar bees  can carry before returning to the hive.
PLANT-DEATH-RATE and PLANT-REGROWTH-RATE determine how quickly plants grow and die.
MIN-TEMP-FOR-INFECTION determines the minimum temperature at which bees are susceptibe to parasites.
RECOVERY-ENERGY determinesthe energy required for and infected bee to overcome disease.
TEMP-INCR-FACTOR determines the increase in average temoerature as a result of climate change.

The Population plot shows the progression of turtle populations and plant-amount. The Foraging? plot shows how many bees are foraging at any time. The Bee Health plot shows the proportion of bees infected by parasites. The Temperature plot shows the maximum, average, and minimum temperature for each day.


## THINGS TO NOTICE

The amount of pollen and nectar a bee can carry (MAX-INV) will determine the radius of the foraging circle around the hive, and result in better plant growth in this space. A larger MAX-INV will increase this radius. Additionally, the MAX-INV effects the density of bees surrounding the hive. This may result in spiked parasite infection.

Although not explicitly encoded, bees spend the majority of the colder months in or around the hive. This is likely because once they have returned to the hive at some point in these months, they are not prompted by temperature to forage (since they cannot move).

Increasing the number of bears will result in the colony dying out sooner. However, this also results in the extinction of beaars in the simulation.

## THINGS TO TRY

Keeping all other parameters the same, adjust TEMP-INCR-FACTOR to see how the rising temeratures effect parasite incidence and bee population.

## NETLOGO FEATURES

The routines of the turtles are prompted by temperature as they occur in nature. For example, mobility of bees is determined by whether there is a sufficiently warm point in the day. Bears are prompted to hybernate in the region's Winter temperatures. 

## CREDITS AND REFERENCES

This model uses agent characteristics and rules which are adapted from the following models:
•	Wilensky, U. (2007). NetLogo Wolf Sheep Simple 5 model. http://ccl.northwestern.edu/netlogo/models/WolfSheepSimple5. Center for Connected Learning and Computer-Based Modeling, Northwestern Institute on Complex Systems, Northwestern University, Evanston, IL. 
•	Wilensky, U. (1997). NetLogo Ants model. http://ccl.northwestern.edu/netlogo/models/Ants. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL. 
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

bee 2
true
0
Polygon -1184463 true false 195 150 105 150 90 165 90 225 105 270 135 300 165 300 195 270 210 225 210 165 195 150
Rectangle -16777216 true false 90 165 212 185
Polygon -16777216 true false 90 207 90 226 210 226 210 207
Polygon -16777216 true false 103 266 198 266 203 246 96 246
Polygon -6459832 true false 120 150 105 135 105 75 120 60 180 60 195 75 195 135 180 150
Polygon -6459832 true false 150 15 120 30 120 60 180 60 180 30
Circle -16777216 true false 105 30 30
Circle -16777216 true false 165 30 30
Polygon -7500403 true true 120 90 75 105 15 90 30 75 120 75
Polygon -16777216 false false 120 75 30 75 15 90 75 105 120 90
Polygon -7500403 true true 180 75 180 90 225 105 285 90 270 75
Polygon -16777216 false false 180 75 270 75 285 90 225 105 180 90
Polygon -7500403 true true 180 75 180 90 195 105 240 195 270 210 285 210 285 150 255 105
Polygon -16777216 false false 180 75 255 105 285 150 285 210 270 210 240 195 195 105 180 90
Polygon -7500403 true true 120 75 45 105 15 150 15 210 30 210 60 195 105 105 120 90
Polygon -16777216 false false 120 75 45 105 15 150 15 210 30 210 60 195 105 105 120 90
Polygon -16777216 true false 135 300 165 300 180 285 120 285

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

egg
false
0
Circle -7500403 true true 96 76 108
Circle -7500403 true true 72 104 156
Polygon -7500403 true true 221 149 195 101 106 99 80 148

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

footprint other
true
0
Polygon -7500403 true true 75 195 90 240 135 270 165 270 195 255 225 195 225 180 195 165 177 154 167 139 150 135 132 138 124 151 105 165 76 172
Polygon -7500403 true true 250 136 225 165 210 135 210 120 227 100 241 99
Polygon -7500403 true true 75 135 90 135 105 120 105 75 90 75 60 105
Polygon -7500403 true true 120 122 155 121 161 62 148 40 136 40 118 70
Polygon -7500403 true true 176 126 200 121 206 89 198 61 186 57 166 106
Polygon -7500403 true true 93 69 103 68 102 50
Polygon -7500403 true true 146 34 136 33 137 15
Polygon -7500403 true true 198 55 188 52 189 34
Polygon -7500403 true true 238 92 228 94 229 76

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

moose
false
0
Polygon -7500403 true true 196 228 198 297 180 297 178 244 166 213 136 213 106 213 79 227 73 259 50 257 49 229 38 197 26 168 26 137 46 120 101 122 147 102 181 111 217 121 256 136 294 151 286 169 256 169 241 198 211 188
Polygon -7500403 true true 74 258 87 299 63 297 49 256
Polygon -7500403 true true 25 135 15 186 10 200 23 217 25 188 35 141
Polygon -7500403 true true 270 150 253 100 231 94 213 100 208 135
Polygon -7500403 true true 225 120 204 66 207 29 185 56 178 27 171 59 150 45 165 90
Polygon -7500403 true true 225 120 249 61 241 31 265 56 272 27 280 59 300 45 285 90

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
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="ChangeTemp" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>stop
ca</final>
    <timeLimit steps="730"/>
    <metric>count bees with [infected?]</metric>
    <metric>count bees with [not infected?]</metric>
    <metric>sum [temp] of patches / count patches</metric>
    <metric>sum [foraging?] of bees</metric>
    <metric>sum [temp] of patches / count patches</metric>
    <enumeratedValueSet variable="max-inv">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-deer">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plant-regrowth-rate">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="death-time-parasite">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-bears">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion-infected">
      <value value="0"/>
    </enumeratedValueSet>
    <steppedValueSet variable="temp-incr-factor" first="0" step="0.5" last="2"/>
    <enumeratedValueSet variable="number-of-bees">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plant-death-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-temp-for-infection">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recovery-energy">
      <value value="60"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="SensInfTemp" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>stop
ca</final>
    <timeLimit steps="730"/>
    <metric>count bees with [infected?]</metric>
    <metric>count bees with [not infected?]</metric>
    <metric>sum [temp] of patches / count patches</metric>
    <metric>sum [foraging?] of bees</metric>
    <metric>sum [temp] of patches / count patches</metric>
    <enumeratedValueSet variable="max-inv">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-deer">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plant-regrowth-rate">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="death-time-parasite">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-bears">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion-infected">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="temp-incr-factor">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-bees">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plant-death-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <steppedValueSet variable="min-temp-for-infection" first="5" step="5" last="20"/>
    <enumeratedValueSet variable="recovery-energy">
      <value value="60"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="SensRecovery" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>stop
ca</final>
    <timeLimit steps="730"/>
    <metric>count bees with [infected?]</metric>
    <metric>count bees with [not infected?]</metric>
    <metric>sum [temp] of patches / count patches</metric>
    <metric>sum [foraging?] of bees</metric>
    <metric>sum [temp] of patches / count patches</metric>
    <enumeratedValueSet variable="max-inv">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-deer">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plant-regrowth-rate">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="death-time-parasite">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-bears">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion-infected">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="temp-incr-factor">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-bees">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plant-death-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-temp-for-infection">
      <value value="5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="recovery-energy" first="50" step="10" last="100"/>
  </experiment>
  <experiment name="SensMaxInv" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>stop
ca</final>
    <timeLimit steps="730"/>
    <metric>count bees with [infected?]</metric>
    <metric>count bees with [not infected?]</metric>
    <metric>sum [temp] of patches / count patches</metric>
    <metric>sum [foraging?] of bees</metric>
    <metric>sum [temp] of patches / count patches</metric>
    <steppedValueSet variable="max-inv" first="5" step="5" last="20"/>
    <enumeratedValueSet variable="number-of-deer">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plant-regrowth-rate">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="death-time-parasite">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-bears">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion-infected">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="temp-incr-factor">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-bees">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plant-death-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-temp-for-infection">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recovery-energy">
      <value value="60"/>
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
@#$#@#$#@
0
@#$#@#$#@
