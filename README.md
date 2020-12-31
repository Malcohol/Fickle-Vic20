# Fickle-Vic20
A 4k real-time one-button puzzle game for the Commodore Vic-20

(C)2011,2012 Malcolm Tyrrell

## Instructions
Fickle is a very unreliable sort, always flitting around after new and
different things. This game has decided to teach Fickle to be steadfast by
playing hard-to-get.

Fickle has two moods, red and green, which can be toggled by pressing any key
except Restore. That's all the control you have, but fortunately it's enough to
help Fickle win the game's heart.

When in a red mood, Fickle ignores the markings on the level floor. However, in
a green mood, Fickle responds to the markings, for example by turning left at
clockwise markings, or by picking up a key.  

## Difficulty
The game has two speed, slow and fast. Toggle between them using the Restore
key at the welcome screen.

## Advice
The timer gives you a lot more time than it will take for Fickle to reach the
heart, so I recommend you try to plan a route through the level before you
start moving.

## Cheating
You can skip levels with the Restore key, but this will cause the game to
withhold its love.

## Compatibility
Fickle requires a Commodore Vic-20 with no memory expansions. It should work
on both PAL and NTSC Vics.

## Credits
Fickle was made with the cc65 compiler suite (http://www.cc65.org/),
the Exomizer 2 compressor (http://hem.bredband.net/magli143/exo/), and
knowledge distributed at various places on the Internet, but particularly in
the Denial forums (http://sleepingelephant.com/denial/). Thanks to all those
responsible for the above.

## Building 

Ensure you populate the exomizer submodule after cloning and call make in exomizer/exomizer2/src. 
Then change into Fickle's src folder and call make there.
All going well, you will have a usable Fickle.prg.

## Legals, Source code, Cloning, etc
Please distribute and enjoy Fickle.

The main Fickle source code can be used and distributed under the terms of the
GNU Affero General Public License v3.0. However, to build Fickle requires the use of
the Exomizer 2 compressor and the exodecrunch decompressor. These are copyright
Magnus Lind, and have a different Free Software license. Since Fickle requires a modified
version of that project, I forked it in GitHub, and this project uses it a submodule.
The modifications to that project (which are very minor) are marked with "MALX".

To my knowledge, Fickle's game mechanic is original. Please clone it if you'd
like, but I'd appreciate a credit for the design. The levels are copyright me,
so please ask permission if you want to reuse them in any non-free software
context.

Enjoy,

Malcolm
Malcolm.R.Tyrrell@gmail.com
