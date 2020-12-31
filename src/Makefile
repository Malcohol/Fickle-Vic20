#(C)2011,2012 Malcolm Tyrrell (Malcolm.R.Tyrrell@gmail.com)

# Fickle is built in two phases.

all: Fickle.prg

# Phase 1: Build bin files corresponding to 2 chunks of code we want at
# specific locations in memory.

Source.o: Source.s Common.s ../exomizer/exomizer2/exodecrs/exodecrunch.s
	ca65 --cpu 6502X -g $<

low1.bin low2.bin low3.bin main.bin decruncher.bin Fickle.vice: Source.o Phase1.cfg
	ld65 -C Phase1.cfg -Ln Fickle.vice $<

exodecrunch.os: ../exomizer/exomizer2/exodecrs/exodecrunch.s
	ca65 -o $@ --cpu 6502X -g $<

# Preparation for Phase 2: Compress the two chunks.

main.exo: main.bin
	../exomizer/exomizer2/src/exomizer mem -o $@ $<,4592 | grep "The load address\|Literal sequences"

# low is made up of three parts to ensure the middle one is placed
# at exactly the correct memory address
low.bin: low1.bin low2.bin low3.bin
	cat $^ > $@

low.exo: low.bin
	../exomizer/exomizer2/src/exomizer mem -o $@ $<,512 | grep "The load address\|Literal sequences"

# Phase 2: Build a program which contains compressed versions of the bin files,
# and knows how to decompress them to the appropriate locations.

Fickle.o: Fickle.s Common.s low.exo main.exo
	ca65 -o $@ --cpu 6502X -g $<

Fickle.prg: Fickle.o Phase2.cfg exodecrunch.os
	ld65 -o $@ -C Phase2.cfg -Ln Fickle2.vice $< exodecrunch.os

# Clean 
clean:
	rm -f a.out *.o *.bin *.exo *.os *.prg *.vice viclog


