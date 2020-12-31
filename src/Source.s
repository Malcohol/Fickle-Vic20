;Source.s - the main source file of Fickle.
;(C)2011,2012 Malcolm Tyrrell (Malcolm.R.Tyrrell@gmail.com)

.include "Common.s"

	;Check the number of chars set in Common.s is correct.
	.assert NUM_CHARS = (CHR_LOCATION_END - CHR_LOCATION_START) / 8, error, "NUM_CHARS is wrong"

;Pointers in these locations redirect interrupt handling to a user routine.
IRQ_INTERRUPT_VECTOR 	= $0314 ; The main interrupt handler, which I'll replace
NMI_INTERRUPT_VECTOR 	= $0318 ; The interrupt triggered by the restore key

;Useful addresses in the ROM
ROM_START		= $E4A0
ROM_END_OF_INTERRUPT 	= $EB15
ROM_VICINIT_TABLE	= $EDE4

;Memory-mapped registers in the VIC
VIC_REGISTER_BASE			= $9000
VIC_IMODE_AND_HORIZONTAL_ORIGIN		= $9000
VIC_VERTICAL_ORIGIN			= $9001
VIC_SCREEN_LOC_AND_NUM_COLUMNS		= $9002
VIC_RASTER_NUM_ROWS_AND_CHAR_SIZE 	= $9003
VIC_RASTER_HIGH_BITS			= $9004
VIC_SCREEN_AND_CHAR_LOC 		= $9005
VIC_BASS_SWITCH_AND_FREQUENCY		= $900A
VIC_ALTO_SWITCH_AND_FREQUENCY		= $900B
VIC_SOPRANO_SWITCH_AND_FREQUENCY	= $900C
VIC_NOISE_SWITCH_AND_FREQUENCY		= $900D
VIC_AUX_COLOUR_AND_LOUDNESS 		= $900E
VIC_SCREEN_COLOUR_REVERSE_AND_BORDER	= $900F

PAL_DEFAULT_HORIZONTAL_ORIGIN = 12
PAL_DEFAULT_VERTICAL_ORIGIN = 38
PAL_DEFAULT_INTERRUPT_TIMER_DELAY = $4826

PAL_HORIZONTAL_ORIGIN = PAL_DEFAULT_HORIZONTAL_ORIGIN + (((22 - NUM_VIDEO_COLUMNS) * 2) / 2)
PAL_VERTICAL_ORIGIN = PAL_DEFAULT_VERTICAL_ORIGIN + (((23 - NUM_VIDEO_ROWS) * 4) / 2)
;In order to time game events at sufficiently fine granularity, I increase
;the timer frequency.
PAL_INTERRUPT_TIMER_DELAY = (PAL_DEFAULT_INTERRUPT_TIMER_DELAY / 5)

;The raster value for the first line of area where a sprite can be.
PAL_RASTER_BASE = 44
;An estimate of how many raster lines (divided by 2) are needed to update the sprite
;characters.
PAL_RASTER_LEAD_IN = 22
PAL_RASTER_DIFF = PAL_RASTER_BASE - PAL_RASTER_LEAD_IN
PAL_RASTER_SUM = PAL_RASTER_LEAD_IN + 8

NTSC_DEFAULT_HORIZONTAL_ORIGIN = 5
NTSC_DEFAULT_VERTICAL_ORIGIN = 25
NTSC_DEFAULT_INTERRUPT_TIMER_DELAY = $4289

NTSC_HORIZONTAL_ORIGIN = NTSC_DEFAULT_HORIZONTAL_ORIGIN + (((22 - NUM_VIDEO_COLUMNS) * 2) / 2)
NTSC_VERTICAL_ORIGIN = NTSC_DEFAULT_VERTICAL_ORIGIN + (((23 - NUM_VIDEO_ROWS) * 4) / 2)
NTSC_INTERRUPT_TIMER_DELAY = (NTSC_DEFAULT_INTERRUPT_TIMER_DELAY / 5)

NTSC_RASTER_BASE = 32
NTSC_RASTER_LEAD_IN = 28
NTSC_RASTER_DIFF = NTSC_RASTER_BASE - NTSC_RASTER_LEAD_IN
NTSC_RASTER_SUM = NTSC_RASTER_LEAD_IN + 8 + 5

;Help obtain some starting values. Tweaking will be necessary.
TEST_RASTER_VALUES = 0

.if TEST_RASTER_VALUES

;Use testing mode to judge if the raster values are correct
;It turns out that the values produced from the test needed tweaking.

.macro testRasterValuesPre
@waitForRaster0:
	LDA VIC_RASTER_HIGH_BITS
	BNE @waitForRaster0
	;Exploit the do and don't values for this vic reg
	LDA #DO_VALUE
	STA VIC_SCREEN_COLOUR_REVERSE_AND_BORDER
@waitForRasterBase:
	LDA VIC_RASTER_HIGH_BITS
	SEC
	CMP #RASTER_BASE
	BCC @waitForRasterBase
	LDA #DONT_VALUE
	STA VIC_SCREEN_COLOUR_REVERSE_AND_BORDER
.endmacro

.macro testRasterValuesPost
	LDA #DO_VALUE
	STA VIC_SCREEN_COLOUR_REVERSE_AND_BORDER
	JMP @waitForRaster0
.endmacro

.else
.macro testRasterValuesPre
.endmacro
.macro testRasterValuesPost
.endmacro
.endif

PETSCII_SPACE = 32
PETSCII_HEART = 83

;Memory-mapped registers for the two VIA chips
VIA_1_PORT_A_IO_REGISTER 	= $9111 ;Joystick scan
VIA_1_PORT_A_DDR 		= $9113 ;Joystick scan
VIA_1_INTERRUPT_FLAG_REGISTER	= $911D
VIA_2_PORT_B_IO_REGISTER 	= $9120 ;Keyboard row scan
VIA_2_PORT_A_IO_REGISTER 	= $9121 ;Keyboard column scan
VIA_2_TIMER_1_LOW_ORDER_LATCH	= $9126 ;For adjusting the interrupt frequency
VIA_2_TIMER_1_HIGH_ORDER_LATCH	= $9127 ;For adjusting the interrupt frequency

;SCREEN_AND_CHAR_LOC_TEXT = $F0
;SCREEN_AND_CHAR_LOC_GAME = $FC

;The screen at $1000 and the upper case / graphical character page.
SCREEN_AND_CHAR_LOC_TEXT = $C0
;The screen and the character page at $1000.
SCREEN_AND_CHAR_LOC_GAME = $CC

SOUND_NOTE_OFF = $00
SOUND_WALL_NOTE = $80
SOUND_GAME_REGISTER_0 = VIC_NOISE_SWITCH_AND_FREQUENCY 
SOUND_GAME_REGISTER_1 = VIC_SOPRANO_SWITCH_AND_FREQUENCY 
SOUND_WALL_REGISTER = SOUND_GAME_REGISTER_0
SOUND_CORNER_NOTE = $88
SOUND_CORNER_REGISTER = SOUND_GAME_REGISTER_0
SOUND_DOOR_NOTE = $80
SOUND_DOOR_REGISTER = SOUND_GAME_REGISTER_1
SOUND_KEY_NOTE = $D0
SOUND_KEY_REGISTER = SOUND_GAME_REGISTER_1
SOUND_SWITCH_NOTE = $A0
SOUND_SWITCH_REGISTER = VIC_SOPRANO_SWITCH_AND_FREQUENCY
SOUND_TWIRL_NOTE = $A0
SOUND_TWIRL_REGISTER = SOUND_GAME_REGISTER_0
SOUND_DEATH_NOTE = $FF
SOUND_DEATH_REGISTER = SOUND_GAME_REGISTER_0
SOUND_COMPLETE_NOTE = $E0
SOUND_COMPLETE_REGISTER = SOUND_GAME_REGISTER_1
SOUND_TELEPORT_NOTE = $C0
SOUND_TELEPORT_REGISTER = SOUND_GAME_REGISTER_1

COLOUR_LOCATION		= $9400

COLOUR_BLACK		= $00
COLOUR_WHITE		= $01
COLOUR_RED		= $02
COLOUR_CYAN		= $03
COLOUR_PURPLE		= $04
COLOUR_GREEN		= $05
COLOUR_BLUE		= $06
COLOUR_YELLOW		= $07
COLOUR_ORANGE		= $08
COLOUR_LIGHT_ORANGE	= $09
COLOUR_PINK		= $0A
COLOUR_LIGHT_CYAN	= $0B
COLOUR_LIGHT_PURPLE	= $0C
COLOUR_LIGHT_GREEN	= $0D
COLOUR_LIGHT_BLUE	= $0E
COLOUR_LIGHT_YELLOW	= $0F

NUM_GAME_COLUMNS= $06
NUM_GAME_ROWS	= $06

NUM_VIDEO_COLUMNS	= (NUM_GAME_COLUMNS * 3) + 1
NUM_VIDEO_ROWS		= (NUM_GAME_ROWS * 3) + 3

HEARTBAR_LOCATION = SCREEN_LOCATION + 2
HEARTBAR_COLOUR_LOCATION = COLOUR_LOCATION + 2
INFOBAR_LOCATION = SCREEN_LOCATION + (NUM_VIDEO_COLUMNS * (NUM_VIDEO_ROWS - 1)) + 2
INFOBAR_COLOUR_LOCATION = COLOUR_LOCATION + (NUM_VIDEO_COLUMNS * (NUM_VIDEO_ROWS - 1)) + 2
LIFE_LOCATION = INFOBAR_LOCATION - 2
LIFE_COLOUR_LOCATION = INFOBAR_COLOUR_LOCATION - 2
KEY_LOCATION = SCREEN_LOCATION
KEY_COLOUR_LOCATION = COLOUR_LOCATION

;This prohibits having text in the very top row, but saves a byte.
TEXT_TERMINATOR = 0

AXIS_HORIZONTAL	= 0
AXIS_VERTICAL 	= 1
DIR_BACK        = 255 ;left or up
DIR_FORWARD 	= 1  ;right or down

NUM_LIVES	= 4
NUM_LEVELS	= 15

;This is not a valid barrier since the (x,y) encoding maxes out at 29 << 3, so the
;highest valid barrier would be %11101111
BARRIER_TERMINATOR = %11110000

WALL_COLOUR	= COLOUR_BLUE
DO_COLOUR 	= COLOUR_GREEN
DONT_COLOUR 	= COLOUR_RED
SCREEN_COLOUR	= COLOUR_BLACK
TIMEBAR_COLOUR	= COLOUR_CYAN
BADDY_COLOUR	= COLOUR_LIGHT_CYAN
KEY_COLOUR 	= COLOUR_YELLOW
TELEPORT_COLOUR = COLOUR_CYAN
SWITCH_COLOUR	= COLOUR_WHITE
HEART_COLOUR	= COLOUR_RED
TWIRL_COLOUR	= COLOUR_PURPLE

DO_VALUE  	= (SCREEN_COLOUR * $0F) + $08 + DO_COLOUR
DONT_VALUE 	= (SCREEN_COLOUR * $0F) + $08 + DONT_COLOUR
TEXT_BG 	= (SCREEN_COLOUR * $0F) + $08 + DONT_COLOUR
TEXT_FG 	= COLOUR_WHITE

LEVEL_TIME_MAX = (NUM_VIDEO_COLUMNS - NUM_LIVES) * 8
ANIMATION_RATE = 5
LEVEL_TIME_RATE = 200
PLAYER_SLOW_RATE = 6
PLAYER_FAST_RATE = 5

DEATH_LOOP_LENGTH =20 
COMPLETE_LOOP_LENGTH=20

;Variables
;Because I've  overridden the interrupts, I no longer need to worry about
;clashes with any system variables in page 0.
.enum var
	timer_time

	timer_player
	timer_baddy	
	timer_animation

	LEVEL_INIT_START ;all set to zero.
	num_keys = LEVEL_INIT_START
	death			;non-zero means the player is dead
	skip			;non-zero means the player wants to skip
	num_baddies		;number of baddies in the level
	player_started		;non-zero means the player has started moving
	num_teleports		;Number of teleports seen so far during level
				;loading.
	LEVEL_INIT_END = num_teleports

	level_time		;= number of pixels in the timebar.

	floor_x	
	floor_y	
	floor_data	
	floor_tile		;floor_data & 15
	barrier_index
	barrier_type

	neighbour_offset_0 	;Offsets of neighbouring 2 characters from the
	neighbour_offset_1	;screen ptr.

	screen_ptr		;A pointer into the screen buffer.
	screen_ptr_hi

	;A pointer to some character in the screen or a back buffer (always combined
	;with an offset)
	target_char_ptr
	target_char_ptr_hi

	;The position of the holes within the 6-byte character buffers. Set getHoleOffsets
	hole_offset_0
	hole_offset_1

	sprite_struct_0ptr	;zero page address of start of a sprite struct

	;The "sprite struct" used by the sprite routines.
	sprite_x		;Sprite's x coordinate in pixels
	sprite_y		;Sprite's y coordinate in pixels
	sprite_dir		;DIR_FORWARD or DIR_BACK
	sprite_axis		;DIR_HORIZONTAL or DIR_VERTICAL
	sprite_has_updated	;Has the sprite moved yet?
	;The rest of the struct are never changed by a sprite routine.
	sprite_callback_ptr
	sprite_callback_ptr_hi
	sprite_back_chars_ptr	;Pointer to the storage with the back chars
	sprite_back_chars_ptr_hi
	sprite_source_ptr	;Pointer to the source image data
	sprite_source_ptr_hi
	sprite_image_ptr	;Pointer to the character data actually on the screen
	sprite_image_ptr_hi
	sprite_start_chr	;Char number of the first character in the sprite
	sprite_source_offset	;Offset from the start of the sprite source data

	animate_element		;Which screen element gets animated this frame

	key_state	
	key_event	

	;A pointer into the colour data buffer
	colour_ptr	
	colour_ptr_hi

	size_of_level		;How many bytes to the following level.

	baddy_lower_limit	;Lower limit for the baddy
	baddy_upper_limit	;Upper limit for the baddy

	baddy_rate		;Set to three times the player's rate

	teleport_0_x		;X coord of the first teleport
	teleport_0_y		;Y coord of the first teleport
	teleport_1_x		;X coord of the second teleport
	teleport_1_y		;Y coord of the second teleport

	layer_chr		;Character used to determine the layer from
				;which screen characters should be accessed
				;or updated

	player_rate		;non-zero means fast
	animate_turns 		;Whether the turns should be flipped or swapped

	;Tempories for use inside routines and sometimes for passing arguments
	param_0
	param_1
	param_2
	param_3
	param_4
	param_5

	drawBarrierCharsTmp
	mulABy3Tmp
	drawFloorTmp1
	drawFloorTmp2

	;The player's struct
	player_x
	player_y	
	player_dir	
	player_axis	
	player_has_updated
	
	;variables below are initialized at the start of every game.
	INITIALIZATION_START 

	player_callback_ptr = INITIALIZATION_START
	player_callback_ptr_hi
	player_back_chars_ptr
	player_back_chars_ptr_hi
	player_source_ptr
	player_source_ptr_hi
	player_image_ptr
	player_image_ptr_hi
	player_start_chr
	player_source_offset

	;The baddy's struct
	baddy_x	
	baddy_y	
	baddy_dir	
	baddy_axis	
	baddy_has_updated
	baddy_callback_ptr
	baddy_callback_ptr_hi
	baddy_back_chars_ptr
	baddy_back_chars_ptr_hi
	baddy_source_ptr
	baddy_source_ptr_hi
	baddy_image_ptr
	baddy_image_ptr_hi
	baddy_start_chr
	baddy_source_offset

	num_level 		;Current level
	cheat			;non-zero means the player has cheated
	num_lives
	leveldata_ptr		;Pointer to level data.
	leveldata_ptr_hi
	INITIALIZATION_END = leveldata_ptr_hi
.endenum

;I haven't actually confirmed this, but I've decided to "pass by value" when
;handling sprites, on the assumption that all the extra indexing of "pass by
;reference" would cost more code in total.
SPRITE_STRUCT_START = var::sprite_x
PLAYER_STRUCT_START = var::player_x
BADDY_STRUCT_START = var::baddy_x
SPRITE_FULL_STRUCT_SIZE = (var::sprite_source_offset - var::sprite_x) + 1
SPRITE_ACTIVE_STRUCT_SIZE = (var::sprite_has_updated - var::sprite_x) + 1
SPRITE_LOOP_START = var::player_x
SPRITE_LOOP_FINISH = SPRITE_LOOP_START + (SPRITE_FULL_STRUCT_SIZE * 2)

CHR_PAGE = CHR_LOCATION_START - $190 - (12 * 8)

CHR_WALL		= (CHR_LOCATION_WALL - CHR_PAGE) / 8
CHR_GAP			= (CHR_LOCATION_GAP - CHR_PAGE) / 8
CHR_SPIKE_UP		= (CHR_LOCATION_SPIKE_UP - CHR_PAGE) / 8
CHR_SPIKE_DOWN		= (CHR_LOCATION_SPIKE_DOWN - CHR_PAGE) / 8
CHR_SPIKE_LEFT		= (CHR_LOCATION_SPIKE_LEFT - CHR_PAGE) / 8
CHR_SPIKE_RIGHT		= (CHR_LOCATION_SPIKE_RIGHT - CHR_PAGE) / 8
CHR_CORNER_TL		= (CHR_LOCATION_CORNER_TL - CHR_PAGE) / 8
CHR_CORNER_BL		= (CHR_LOCATION_CORNER_BL - CHR_PAGE) / 8
CHR_CORNER_TR		= (CHR_LOCATION_CORNER_TR - CHR_PAGE) / 8
CHR_CORNER_BR		= (CHR_LOCATION_CORNER_BR - CHR_PAGE) / 8
CHR_CLOCKWISE_TL	= (CHR_LOCATION_CLOCKWISE_TL - CHR_PAGE) / 8
CHR_CLOCKWISE_TR	= (CHR_LOCATION_CLOCKWISE_TR - CHR_PAGE) / 8
CHR_CLOCKWISE_BL	= (CHR_LOCATION_CLOCKWISE_BL - CHR_PAGE) / 8
CHR_CLOCKWISE_BR	= (CHR_LOCATION_CLOCKWISE_BR - CHR_PAGE) / 8
CHR_ANTICLOCKWISE_TL	= (CHR_LOCATION_ANTICLOCKWISE_TL - CHR_PAGE) / 8
CHR_ANTICLOCKWISE_TR	= (CHR_LOCATION_ANTICLOCKWISE_TR - CHR_PAGE) / 8
CHR_ANTICLOCKWISE_BL	= (CHR_LOCATION_ANTICLOCKWISE_BL - CHR_PAGE) / 8
CHR_ANTICLOCKWISE_BR	= (CHR_LOCATION_ANTICLOCKWISE_BR - CHR_PAGE) / 8
CHR_KEY_TL		= (CHR_LOCATION_KEY_TL - CHR_PAGE) / 8
CHR_KEY_TR		= (CHR_LOCATION_KEY_TR - CHR_PAGE) / 8
CHR_KEY_BL		= (CHR_LOCATION_KEY_BL - CHR_PAGE) / 8
CHR_KEY_BR		= (CHR_LOCATION_KEY_BR - CHR_PAGE) / 8
CHR_SWITCH_LEFT_TL	= (CHR_LOCATION_SWITCH_LEFT_TL - CHR_PAGE) / 8
CHR_SWITCH_LEFT_BL	= (CHR_LOCATION_SWITCH_LEFT_BL - CHR_PAGE) / 8
CHR_SWITCH_LEFT_BR	= (CHR_LOCATION_SWITCH_LEFT_BR - CHR_PAGE) / 8
CHR_SWITCH_RIGHT_TR	= (CHR_LOCATION_SWITCH_RIGHT_TR - CHR_PAGE) / 8
CHR_SWITCH_RIGHT_BL	= (CHR_LOCATION_SWITCH_RIGHT_BL - CHR_PAGE) / 8
CHR_SWITCH_RIGHT_BR	= (CHR_LOCATION_SWITCH_RIGHT_BR - CHR_PAGE) / 8
CHR_BARRIER_OPEN	= (CHR_LOCATION_BARRIER_OPEN - CHR_PAGE) / 8
CHR_BARRIER_ELECTRIFIED	= (CHR_LOCATION_BARRIER_ELECTRIFIED - CHR_PAGE) / 8
CHR_BARRIER_CLOSED	= (CHR_LOCATION_BARRIER_CLOSED - CHR_PAGE) / 8
CHR_DOOR		= (CHR_LOCATION_DOOR - CHR_PAGE) / 8
CHR_KEY_SYMBOL		= (CHR_LOCATION_KEY_SYMBOL - CHR_PAGE) / 8
CHR_LIFE_SYMBOL_LEFT	= (CHR_LOCATION_LIFE_SYMBOL_LEFT - CHR_PAGE) / 8
CHR_LIFE_SYMBOL_RIGHT	= (CHR_LOCATION_LIFE_SYMBOL_RIGHT - CHR_PAGE) / 8
CHR_TIMEBAR_BODY	= (CHR_LOCATION_TIMEBAR_BODY - CHR_PAGE) / 8
CHR_TIMEBAR_TOP		= (CHR_LOCATION_TIMEBAR_TOP - CHR_PAGE) / 8
CHR_TIMEBAR_EMPTY	= (CHR_LOCATION_TIMEBAR_EMPTY - CHR_PAGE) / 8
CHR_TIMEBAR_TIP		= (CHR_LOCATION_TIMEBAR_TIP - CHR_PAGE) / 8
CHR_HEART_TOP		= (CHR_LOCATION_HEART_TOP - CHR_PAGE) / 8
CHR_HEART_BL		= (CHR_LOCATION_HEART_BL - CHR_PAGE) / 8
CHR_HEART_BR		= (CHR_LOCATION_HEART_BR - CHR_PAGE) / 8
CHR_HEART_HOLLOW	= (CHR_LOCATION_HEART_HOLLOW - CHR_PAGE) / 8
CHR_HEART_FULL		= (CHR_LOCATION_HEART_FULL - CHR_PAGE) / 8
CHR_HEART_BROKEN	= (CHR_LOCATION_HEART_BROKEN - CHR_PAGE) / 8

CHR_BUFF_START = $190 / 8
CHR_BADDY_BUFF  = CHR_BUFF_START + 0
CHR_PLAYER_BUFF  = CHR_BUFF_START + 6
CHR_BUFF_END = CHR_BUFF_START + 12

CHR_PLAYER_TL		= ((CHR_LOCATION_PLAYER_TL - CHR_LOCATION_SPRITE_SOURCE)/ 8) + CHR_BUFF_START
CHR_PLAYER_TR		= ((CHR_LOCATION_PLAYER_TR - CHR_LOCATION_SPRITE_SOURCE)/ 8) + CHR_BUFF_START
CHR_PLAYER_BL		= ((CHR_LOCATION_PLAYER_BL - CHR_LOCATION_SPRITE_SOURCE)/ 8) + CHR_BUFF_START
CHR_PLAYER_BR		= ((CHR_LOCATION_PLAYER_BR - CHR_LOCATION_SPRITE_SOURCE)/ 8) + CHR_BUFF_START
CHR_BADDY_TL		= ((CHR_LOCATION_BADDY_TL - CHR_LOCATION_SPRITE_SOURCE) / 8) + CHR_BUFF_START
CHR_BADDY_TR		= ((CHR_LOCATION_BADDY_TR - CHR_LOCATION_SPRITE_SOURCE) / 8) + CHR_BUFF_START
CHR_BADDY_BL		= ((CHR_LOCATION_BADDY_BL - CHR_LOCATION_SPRITE_SOURCE) / 8) + CHR_BUFF_START
CHR_BADDY_BR		= ((CHR_LOCATION_BADDY_BR - CHR_LOCATION_SPRITE_SOURCE) / 8) + CHR_BUFF_START

FLOOR_GAP	= (FLOOR_LOCATION_GAP - FLOOR_LOCATION_START) / 4
FLOOR_BLOCK	= (FLOOR_LOCATION_BLOCK - FLOOR_LOCATION_START) / 4
FLOOR_CORNER_TL	= (FLOOR_LOCATION_CORNER_TL - FLOOR_LOCATION_START) / 4
FLOOR_CORNER_TR	= (FLOOR_LOCATION_CORNER_TR - FLOOR_LOCATION_START) / 4
FLOOR_CORNER_BL	= (FLOOR_LOCATION_CORNER_BL - FLOOR_LOCATION_START) / 4
FLOOR_CORNER_BR	= (FLOOR_LOCATION_CORNER_BR - FLOOR_LOCATION_START) / 4
FLOOR_CLOCKWISE	= (FLOOR_LOCATION_CLOCKWISE - FLOOR_LOCATION_START) / 4
FLOOR_ANTICLOCKWISE= (FLOOR_LOCATION_ANTICLOCKWISE - FLOOR_LOCATION_START) / 4
FLOOR_KEY	= (FLOOR_LOCATION_KEY - FLOOR_LOCATION_START) / 4
FLOOR_BADDY	= (FLOOR_LOCATION_BADDY - FLOOR_LOCATION_START) / 4
FLOOR_FINISH	= (FLOOR_LOCATION_FINISH - FLOOR_LOCATION_START) / 4
FLOOR_PLAYER	= (FLOOR_LOCATION_PLAYER - FLOOR_LOCATION_START) / 4
FLOOR_SWITCH_LEFT	= (FLOOR_LOCATION_SWITCH_LEFT - FLOOR_LOCATION_START) / 4
FLOOR_SWITCH_RIGHT 	= (FLOOR_LOCATION_SWITCH_RIGHT - FLOOR_LOCATION_START) / 4
FLOOR_TELEPORT 	= (FLOOR_LOCATION_TELEPORT - FLOOR_LOCATION_START) / 4

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.segment "CODE"

initialize:
	;No event pending
	LDX #0
	STX var::key_event
	STX var::animate_turns
	;Assume key down
	INX
	STX var::key_state
	;Restart the interrupts.
	CLI

	;Copy the VIC settings to their destination
	LDX #$F
@loopVic:
	LDA VIC_SETTINGS,X
	STA VIC_REGISTER_BASE,X
	DEX
	BPL @loopVic

	;var::player_rate
	LDA #PLAYER_SLOW_RATE
	STA var::player_rate

	;Check which type of Vic-20 this is by using the horizontal origin
	;setting built into the rom.
	LDA ROM_VICINIT_TABLE
	CMP #PAL_DEFAULT_HORIZONTAL_ORIGIN
	BEQ @palVic20

@ntscVic20:
	LDA #NTSC_HORIZONTAL_ORIGIN
	STA VIC_IMODE_AND_HORIZONTAL_ORIGIN
	LDA #NTSC_VERTICAL_ORIGIN
	STA VIC_VERTICAL_ORIGIN
	LDA #NTSC_RASTER_SUM
	STA RASTER_SUM_LOCATION
	LDA #NTSC_RASTER_DIFF
	STA RASTER_DIFF_LOCATION
	LDX #.LOBYTE(NTSC_INTERRUPT_TIMER_DELAY)
	LDY #.HIBYTE(NTSC_INTERRUPT_TIMER_DELAY)
	BNE @setInterruptTimer
@palVic20:
	LDX #.LOBYTE(PAL_INTERRUPT_TIMER_DELAY)
	LDY #.HIBYTE(PAL_INTERRUPT_TIMER_DELAY)
@setInterruptTimer:
	STX VIA_2_TIMER_1_LOW_ORDER_LATCH
	STY VIA_2_TIMER_1_HIGH_ORDER_LATCH

	;Fall through

;********************************************************************
; INTRO SCREEN 
;********************************************************************

introScreen:
	LDX #INITIALIZATION_SETTINGS_END - INITIALIZATION_SETTINGS
@loopInit:
	LDA INITIALIZATION_SETTINGS,X
	STA var::INITIALIZATION_START,X
	DEX
	BPL @loopInit

	LDX #TEXT_OFFSET_INTRO
	JSR textScreen

;********************************************************************
; GAME START
;********************************************************************

gameInit:
	LDA #SCREEN_AND_CHAR_LOC_GAME
	STA VIC_SCREEN_AND_CHAR_LOC

	LDA var::player_rate
	JSR mulABy3
	STA var::baddy_rate

	LDX #NUM_LEVELS
@loop:
	LDA #CHR_HEART_HOLLOW
	STA HEARTBAR_LOCATION,X
	LDA #COLOUR_RED
	STA HEARTBAR_COLOUR_LOCATION,X
	DEX
	BPL @loop

	;Draw lives
	LDA #DO_COLOUR
	STA LIFE_COLOUR_LOCATION
	STA LIFE_COLOUR_LOCATION + NUM_VIDEO_COLUMNS - 2
	LDA #DONT_COLOUR
	STA LIFE_COLOUR_LOCATION + 1
	STA LIFE_COLOUR_LOCATION + NUM_VIDEO_COLUMNS - 1

	LDX #NUM_LIVES
@loop0:
	LDY LIFE_POS_LUT,X
	LDA #CHR_LIFE_SYMBOL_LEFT
	CPY #3
	BMI @left
	LDA #CHR_LIFE_SYMBOL_RIGHT
@left:
	STA LIFE_LOCATION,Y
	DEX
	BPL @loop0

;********************************************************************
; LEVEL START
;********************************************************************

loadLevel:
	LDA var::num_level
	CMP #NUM_LEVELS
	BNE @notLevelEnd

	;Check for game finished
	LDX #TEXT_OFFSET_COMPLETE
	LDA var::cheat
	BEQ @noCheat
	LDX #TEXT_OFFSET_CHEAT
@noCheat:
	JSR textScreen
	JMP introScreen

@notLevelEnd:
	LDA #0
	LDX #var::LEVEL_INIT_END - var::LEVEL_INIT_START
@levelInitLoop:
	STA var::LEVEL_INIT_START,X
	DEX
	BPL @levelInitLoop

	; Set the screen and border colours
	LDA #DONT_VALUE
	STA VIC_SCREEN_COLOUR_REVERSE_AND_BORDER

	;This stops resetSprites from wrongly aligning the baddy sprite twice.
	LDA #8
	STA var::baddy_x
	STA var::baddy_y

	LDX #NUM_GAME_COLUMNS
	STX var::floor_x
@xLoop:
	
	LDY #NUM_GAME_ROWS
	STY var::floor_y
@yLoop:
	JSR getFloorData

	CLC
	LDA var::floor_x
	JSR mulABy3
	TAX
	LDA var::floor_y
	JSR mulABy3
	TAY
	JSR moveScreenAndColourPtrXY

	;Draw the corner, always
	LDA #CHR_WALL
	LDY #0
	JSR placeWallPiece

	;Draw the top/bottow characters, if not at final column
	LDX var::floor_x
	CPX #NUM_GAME_COLUMNS
	BEQ @finalColumn

	LDA var::floor_data
	ROL
	ROL
	ROL
	AND #%00000011
	TAY
	LDA UD_MAP, Y
	JSR drawHorizWall

@finalColumn:
	;Draw the left/right characters, if appropriate
	LDY var::floor_y
	CPY #NUM_GAME_ROWS
	BEQ @notFinalRow

	LDA var::floor_data
	LSR
	LSR
	LSR
	LSR
	AND #%00000011
	TAY
	LDA LR_MAP, Y

	JSR drawVertWall

	LDX var::floor_x
	CPX #NUM_GAME_COLUMNS
	BEQ @notInterior

	;Draw floor block
	LDA var::floor_tile

	;If it's a player, we need to set its coords
	CMP #FLOOR_PLAYER
	BNE @notPlayer
	;Set y to be the target sprite's y-coord
	LDY #var::player_y
	JSR setPixelCoordsFromFloor
	BMI @notSpecial
@notPlayer:
	
	;If it's a baddy, we need to set its coords
	CMP #FLOOR_BADDY
	BNE @notBaddy
	INC var::num_baddies
	;TODO this only handles one baddy
	;Set y to be the target sprite's y-coord
	LDY #var::baddy_y
	JSR setPixelCoordsFromFloor
	BMI @notSpecial
@notBaddy:

	;If it's a teleport, store its coords
	CMP #FLOOR_TELEPORT
	BNE @notTeleport
	LDA var::num_teleports
	ASL
	ADC #var::teleport_0_y
	TAY
	JSR setPixelCoordsFromFloor
	INC var::num_teleports

@notTeleport:
@notSpecial:
	;Update the screen itself
	LDA #0
	STA var::layer_chr
	LDA var::floor_tile
	JSR drawFloor
@notFinalRow:
@notInterior:

	DEC var::floor_y
	BMI @doneRows
	JMP @yLoop
@doneRows:

	DEC var::floor_x
	BMI @doneColumns
	JMP @xLoop
@doneColumns:

	;Handle doors, which follow the level
	LDY #NUM_GAME_COLUMNS * NUM_GAME_ROWS
	STY var::barrier_index
	
@handleDoor:
	LDY var::barrier_index
	LDA (var::leveldata_ptr), Y
	CMP #BARRIER_TERMINATOR
	BCS @noMoreBarrier

	JSR getBarrierTargets
	LDA var::barrier_type
	JSR drawBarrierChars

	INC var::barrier_index
	BNE @handleDoor
	
@noMoreBarrier:
	;Parse playermetadata
	TAX
	AND #%00000001
	STA var::player_axis
	STA var::sprite_axis
	TXA
	AND #%00000010
	SEC
	SBC #1
	STA var::player_dir
	STA var::sprite_dir

	LDA var::num_baddies
	BEQ @noBaddies
	INY
	LDA (var::leveldata_ptr),Y

	TAX
	AND #%00000001
	STA var::baddy_axis
	TXA
	AND #%00000010
	SEC
	SBC #1
	STA var::baddy_dir
	TXA 
	AND #%00011100
	;Obtain a multiple of 24 pixels from the provided value
	ASL
	JSR mulABy3
	CLC
	ADC #8
	STA var::baddy_lower_limit
	TXA
	AND #%11100000
	;Obtain a multiple of 24 pixels from the provided value
	LSR
	LSR
	JSR mulABy3
	CLC
	ADC #8
	STA var::baddy_upper_limit
@noBaddies:
	INY
	STY var::size_of_level

	LDA #0
	STA var::baddy_has_updated
	STA var::player_has_updated
	STA var::key_event

	LDY #(LEVEL_TIME_MAX / 8) - 1
@loop1:
	LDA #CHR_TIMEBAR_BODY
	STA INFOBAR_LOCATION, Y
	LDA #TIMEBAR_COLOUR
	STA INFOBAR_COLOUR_LOCATION, Y
	DEY
	BPL @loop1
	JSR fixTip
	LDA #0
	STA CHR_LOCATION_TIMEBAR_TIP
	STA CHR_LOCATION_TIMEBAR_TIP + 7
	LDA #CHR_TIMEBAR_TIP
	STA INFOBAR_LOCATION + (LEVEL_TIME_MAX / 8) - 1
	;key area
	LDX #3
@loop2:
	LDY LIFE_POS_LUT,X
	LDA #CHR_GAP
	STA KEY_LOCATION, Y
	LDA #KEY_COLOUR
	STA KEY_COLOUR_LOCATION,Y
	DEX
	BPL @loop2

	LDA #LEVEL_TIME_MAX - 1
	STA var::level_time
	LDA #0
	STA var::timer_time
	STA var::timer_baddy
	STA var::timer_player
	STA var::timer_animation

	JSR setEyes
	JSR resetSprites

;*****************************************************************************
; LEVEL LOOP
;*****************************************************************************

levelLoop:
	LDA var::num_baddies
	BEQ @postBaddy
@handleBaddy:
	SEC
	LDA var::timer_baddy
	SBC var::baddy_rate
	BCC @postBaddy
	STA var::timer_baddy

	LDX #BADDY_STRUCT_START
	JSR updateSprite

@postBaddy:
@handlePlayer:
	SEC
	LDA var::timer_player
	SBC var::player_rate
	BCC @postPlayer
	STA var::timer_player

	LDA var::player_started
	BEQ @postPlayer

	LDX #PLAYER_STRUCT_START
	JSR updateSprite

@postPlayer:
	;Animation
	SEC
	LDA var::timer_animation
	SBC #ANIMATION_RATE
	BCC @postAnimations
	STA var::timer_animation
	INC var::animate_element
	LDA var::animate_element
	AND #%00001111

	BNE @notOpenBarrier
	;if (var::animate_element mod 16) == 0, animate the open barrier
	LDX #(CHR_LOCATION_BARRIER_OPEN - CHR_LOCATION_ANIMATION_START)
	LDY #(CHR_LOCATION_BARRIER_OPEN - CHR_LOCATION_ANIMATION_START) + 7
	JSR animateExchange
	BNE @postAnimations

@notOpenBarrier:
	AND #%00000111
	CMP #%00000010
	BNE @notClosedBarrier
	;Closed barrier animation just rotates the bytes in the character.
	;if (var::animate_element mod 8) == 2, animate the closed barrier
	LDX #(CHR_LOCATION_BARRIER_CLOSED - CHR_LOCATION_ANIMATION_START)
	LDY #(CHR_LOCATION_BARRIER_CLOSED - CHR_LOCATION_ANIMATION_START) + 1
@loopClosed:
	;This is inefficient, but allows reuse of code.
	JSR animateExchange
	INX
	INY
	CPY #(CHR_LOCATION_BARRIER_CLOSED - CHR_LOCATION_ANIMATION_START) + 8
	BNE @loopClosed
	BEQ @postAnimations

@notClosedBarrier:
;	;if (var::animate_element mod 8) == 4...
;	CMP #%00000100
;	BNE @notAnotherAnimation
;	
;	B?? @postAnimations
;@notAnotherAnimation:

	;AND #%00000011
	CMP #%00000001
	BNE @notTurns
	;if (var::animate_element mod 4) == 1, animate the turns

	;The animations of the turns is done either by flipping the character data of each
	;tiles, or swapping the character data of the tiles.
	;As a performance optimization, we don't flip or swap the top and bottom two rows,
	;which may make the constants difficult to understand.
	LDX #59
	TXA	;A is some non-zero value.
	EOR var::animate_turns
	STA var::animate_turns
	BEQ @flip

@swap:
	LDY #27
@swaploop:
	JSR animateExchange
	DEX
	DEY
	BNE @swaploop
	BEQ @postAnimations
@flip:
	LDY #32
@fliploop:
	JSR animateExchange
	INY
	CPY #46
	BNE @notEndOfFirstTile
	LDX #13 + 1
	LDY #14
@notEndOfFirstTile:
	DEX
	BNE @fliploop
	BEQ @postAnimations

@notTurns:
	CMP #%00000011
	;else (var::animate_element mod 4) == 3, animate the electrified barrier
	;The electrified barrier is animated by wandering around a page of ROM
	;and anding what we find with the closed barrier's bytes.
	LDA var::animate_element
	LDY #7
@loopElectrified:
	ADC ROM_START, X
	TAX
	AND CHR_LOCATION_BARRIER_CLOSED,Y
	STA CHR_LOCATION_BARRIER_ELECTRIFIED,Y
	INX
	DEY
	BPL @loopElectrified

@postAnimations:

	;Handle the timebar
	SEC
	LDA var::timer_time
	SBC #LEVEL_TIME_RATE
	BCC @postTimebar
	STA var::timer_time
	DEC var::level_time
	;Don't use death variable, since at same stack level as death routine.
	BEQ @death
@stillAlive:
	LDA var::level_time
	;Store the time in Y
	TAY
	;Divide A by 8 and check A mod 8 != 7 and
	LSR
	BCC @shiftTip
	LSR
	BCC @shiftTip
	LSR
	BCC @shiftTip

	;The timebar has reached a character boundary, so rewrite some characters
	;on screen and fix up the tip graphics.

	;X is (A / 8)
	TAX
	LDA #CHR_TIMEBAR_EMPTY
	CPX #(LEVEL_TIME_MAX / 8) - 2
	BNE @normalChar
	LDA #CHR_TIMEBAR_TOP
@normalChar:
	STA INFOBAR_LOCATION + 1, X
	LDA #CHR_TIMEBAR_TIP
	STA INFOBAR_LOCATION, X

	JSR fixTip

	;Shrink the tip (even if we just fixed it)
@shiftTip:
	LDX #3
@loopShrinkTip:
	LDA CHR_LOCATION_TIMEBAR_TIP + 2, X
	ASL
	;Y still holds the time.
	CPY #LEVEL_TIME_MAX - 8
	BCC @normalTip
	AND #%11111100
	ORA #%00000001
@normalTip:
	STA CHR_LOCATION_TIMEBAR_TIP + 2, X
	DEX
	BPL @loopShrinkTip

@postTimebar:

	LDA var::death
	BEQ @notDead
@death:
	JSR deathRattle
	JSR resetSprites
	
@deathdeath:
	DEC var::num_lives
	BMI @gameOver
	LDX var::num_lives
	LDY LIFE_POS_LUT,X
	LDA #CHR_GAP
	STA LIFE_LOCATION,Y
	JMP loadLevel

@notDead:
	LDA var::skip
	BEQ @notSkip
	JSR deathRattle
	LDX var::num_level
	LDA #CHR_HEART_BROKEN
	STA HEARTBAR_LOCATION,X
	JSR advanceLevel
	JMP loadLevel

@notSkip:

@handleKeys:
	LDA var::key_event
	BEQ @noEvent
	STA var::player_started	;A is necessarily non-zero
	LDA #0
	STA var::key_event
	LDX #DO_VALUE
	CPX VIC_SCREEN_COLOUR_REVERSE_AND_BORDER
	BNE @borderWasDo
	LDX #DONT_VALUE
@borderWasDo:
	STX VIC_SCREEN_COLOUR_REVERSE_AND_BORDER

@noEvent:
	JMP levelLoop

@gameOver:
	LDX #TEXT_OFFSET_GAME_OVER
	JSR textScreen
	JMP introScreen

;*****************************************************************************
; SUBROUTINES 
;*****************************************************************************

TEXT_OFFSET_INTRO = (TEXT_LOCATION_INTRO - TEXT_LUT - 1) & 255
TEXT_OFFSET_INTRO_END = TEXT_OFFSET_GAME_OVER
TEXT_OFFSET_GAME_OVER = TEXT_LOCATION_GAME_OVER - TEXT_LUT - 1
TEXT_OFFSET_COMPLETE = TEXT_LOCATION_COMPLETE - TEXT_LUT - 1
TEXT_OFFSET_CHEAT = TEXT_LOCATION_CHEAT - TEXT_LUT - 1

.macro textString SS
.repeat .strlen(SS), I
	.if(.strat(SS,I) = 104)
		.byte (PETSCII_HEART << 1) + (I = .strlen(SS) - 1)
	.elseif((.strat(SS,I) >= 65) .AND (.strat(SS,I) <= 90))
		;Map capital ASCII characters to PETSCII
		.byte ((.strat(SS, I) - 64) << 1) + (I = .strlen(SS) - 1)
	.else
		.byte (.strat(SS,I) << 1) + (I = .strlen(SS) - 1)
	.endif
.endrep
.endmacro

TEXT_LUT:
	;y, x, num_spaces
TEXT_LOCATION_INTRO:
	.byte 2, 6
	textString "FICKLEh"
	.byte 15, 6
	textString "(C)2011"
	.byte 17, 2
	textString "MALCOLM TYRRELL"
	.byte 9, 3
	textString "SLOW"
	.byte 9, 12
	textString "FAST"
	.byte TEXT_TERMINATOR
TEXT_LOCATION_GAME_OVER:
	.byte 7, 6
	textString "TAKE h"
	.byte 11, 3
	textString "AND TRY AGAIN"
	.byte TEXT_TERMINATOR
TEXT_LOCATION_COMPLETE:
	.byte 7, 1
	textString "WELL DONE, FICKLE"
	.byte 11, 3
	textString "YOU WON MY h!"
	.byte TEXT_TERMINATOR
TEXT_LOCATION_CHEAT:
	.byte 7, 1
	textString "YOU CANNOT WIN MY"
	.byte 11, 3
	textString "h BY CHEATING"
	.byte TEXT_TERMINATOR

deathRattle:
	JSR silenceGame
	LDY #SOUND_DEATH_NOTE
	STY SOUND_DEATH_REGISTER
	LDY #DEATH_LOOP_LENGTH
	STY var::param_0
	LDX #0
@deathLoop:
	DEC VIC_VERTICAL_ORIGIN
	INC VIC_IMODE_AND_HORIZONTAL_ORIGIN
	JSR rasterSkip

	INC VIC_VERTICAL_ORIGIN
	DEC VIC_IMODE_AND_HORIZONTAL_ORIGIN
	JSR rasterSkip

	DEC var::param_0
	BNE @deathLoop
	LDA #SOUND_NOTE_OFF
	STA SOUND_DEATH_REGISTER
	RTS

fixTip:
	;Fix up the tip
	LDA #%11111111
	LDX #5
@loopFixTip:
	STA CHR_LOCATION_TIMEBAR_TIP + 1, X
	DEX
	BPL @loopFixTip
	RTS
	
silenceGame:
	LDY #SOUND_NOTE_OFF
	STY SOUND_GAME_REGISTER_0
	STY SOUND_GAME_REGISTER_1
	RTS

drawHorizWall:
	; Draw it twice
	LDY #1
	JSR placeWallPiece
	INY
	;branch rather than call routine
	BNE placeWallPiece

drawVertWall:
	; Draw it twice
	LDY #NUM_VIDEO_COLUMNS
	JSR placeWallPiece
	LDY #NUM_VIDEO_COLUMNS * 2
	;fall through

;Put a wall piece in place
placeWallPiece:
	PHA
	STA (var::screen_ptr), Y
	TAX
	LDA WALL_COLOUR_LUT,X
	STA (var::colour_ptr),Y
	PLA
	RTS

updateSprite:
	;Copy the updating sprite's struct over the sprite's struct
	STX var::sprite_struct_0ptr
	LDA #SPRITE_FULL_STRUCT_SIZE
	LDY #SPRITE_STRUCT_START
	JSR zeroPageCopy

	;Check for char cell offset
	LDX var::sprite_axis
	LDA var::sprite_x,X
	AND #%000000111
	BNE @justMoving

	;If the sprite has reached a char cell offset, we'll need to adjust the
	;characters on the screen.

	LDA var::sprite_y
	;set Y to be (var::sprite_y / 8)
	LSR
	LSR
	LSR
	TAY

	LDA var::sprite_x
	;set X to be (var::sprite_x / 8)
	LSR
	LSR
	LSR
	TAX

	;Get hole offsets in var::param_(0,1)
	JSR getHoleOffsets

	;Move the screen pointer to one char above and left of the sprite.
	DEY
	DEX
	JSR moveScreenAndColourPtrXY

	;Don't hide the trail in the first frame.
	LDA var::sprite_has_updated
	BEQ @dontHideTrail

	;Copy chars from the back buffer over the chars left behind.

	;Get neighbour offsets (using inverse dir in A)
	LDA var::sprite_dir
	EOR #$FE
	LDX var::sprite_axis
	JSR getNeighbourOffsets

	LDX #1
@charPosition:
	LDY var::hole_offset_0,X
	LDA (var::sprite_back_chars_ptr),Y
	PHA
	LDY var::neighbour_offset_0,X
	;Get the target character in var::param_(4,5)
	JSR spriteCharGetTarget
	PLA
	STA (var::target_char_ptr),Y
	DEX
	BPL @charPosition

@dontHideTrail:
@logic:
	;Push the return address from the callback onto the stack.
	LDA #.HIBYTE(@postLogic)
	PHA
	LDA #.LOBYTE(@postLogic) - 1
	PHA
	JMP (var::sprite_callback_ptr)

	;Once the new direction is determined, we have to do more sprite stuff.
@postLogic:
	;Copy chars from the new target to the back buffer

	;Get neighbour offsets (takes dir in A)
	LDA var::sprite_dir
	LDX var::sprite_axis
	JSR getNeighbourOffsets

	LDX #1
@charPosition1:
	LDY var::neighbour_offset_0,X
	;Get a pointer to the target character in var::target_char_ptr
	JSR spriteCharGetTarget
	;Load the target character
	LDA (var::target_char_ptr),Y
	LDY var::hole_offset_0,X
	STA (var::sprite_back_chars_ptr),Y
	DEX
	BPL @charPosition1

	;We can now cleanly update the sprite's chars
	JSR updateChars

	;Copy the sprite's chars to the target
	LDX #1
@charPosition2:
	CLC
	LDA var::hole_offset_0,X
	ADC var::sprite_start_chr
	PHA
	LDY var::neighbour_offset_0,X
	;Get the target character
	JSR spriteCharGetTarget
	PLA
	STA (var::target_char_ptr),Y
	DEX
	BPL @charPosition2
	BMI @afterMoving

@justMoving:
	JSR updateChars

@afterMoving:
	LDA #1
	STA var::sprite_has_updated

	;Copy the sprite's struct back over the sprite's struct
	LDA #SPRITE_ACTIVE_STRUCT_SIZE
	LDX #SPRITE_STRUCT_START
	LDY var::sprite_struct_0ptr
	JSR zeroPageCopy
	RTS

	;Assuming at (X,Y) in chars.
	;Sets the hole position in var::hole_offset_0 and _1.
getHoleOffsets:
	;Protect X
	TXA
	PHA

	CLC
	;The index into the hole offset table is:
	;(2 + (X mod 3) - (Y mod 3)) * 2
	LDA #3
	ADC MOD_3_LUT,X
	SBC MOD_3_LUT,Y
	ASL A
	TAX
	LDA HOLE_OFFSET_LUT,X
	STA var::hole_offset_0
	INX
	LDA HOLE_OFFSET_LUT,X
	STA var::hole_offset_1

	;Restore X
	PLA
	TAX
	RTS

	;A should be the direction, X axis
	;Get neighbour position pointer in var::neighbour_offset_0 and _1
getNeighbourOffsets:
	;Use var::neighbour_offset_0 as a temporary
	STX var::neighbour_offset_0
	CLC
	ADC var::neighbour_offset_0
	AND #%00000011
	CLC
	ASL
	TAX
	LDA NEIGHBOUR_OFFSET_LUT,X
	STA var::neighbour_offset_0
	INX
	LDA NEIGHBOUR_OFFSET_LUT,X
	STA var::neighbour_offset_1
	RTS

;Move the sprite's position variables according to its axis and direction.
;Also, rotate its graphics.
updateChars:
	JSR moveSprite

	;Modify the sprite's chars to reflect the sprite's current state over its back buffer chars.
	;Make sure the raster beam does pass over the characters while we are
	;updating them.
	;Check if the raster beam is sufficiently far above the sprite.
	LDA var::sprite_y
	LSR
	CLC
RASTER_DIFF_LOCATION = * + 1
	ADC #PAL_RASTER_DIFF
	CMP VIC_RASTER_HIGH_BITS
	BCS dontWaitForRaster
	;Otherwise, ensure the raster beam has passed the end of the sprite.
RASTER_SUM_LOCATION = * + 1
	ADC #PAL_RASTER_SUM
waitForRaster:
	CMP VIC_RASTER_HIGH_BITS
	BCS waitForRaster
dontWaitForRaster:

updateCharsNoMove:
	testRasterValuesPre

	;For each character in the back buffer
	LDY #0

@charLoop:
	;Params 4 and 5 will hold the address of the characters data

	TYA
	TAX

	;Divide by 8
	LSR
	LSR
	LSR
	TAY
	LDA (var::sprite_back_chars_ptr),Y
	STA var::param_4	;lobyte
	LDA #0
	STA var::param_5	;hibyte
	;Multiply ((var::param_5 << 8) + var::param_4) by eight
	ASL var::param_4
	ROL var::param_5
	ASL var::param_4
	ROL var::param_5
	ASL var::param_4
	ROL var::param_5
	;Add the char locations
	LDA var::param_4
	.assert .LOBYTE(CHR_PAGE) = 0, error, "Need to add LOBYTE(CHR_PAGE)"
	;Don't need this: ADC #.LOBYTE(CHR_PAGE)
	STA var::param_4
	LDA var::param_5
	ADC #.HIBYTE(CHR_PAGE)
	STA var::param_5

	;Restore Y from X
	TXA
	TAY

	;Subtract Y
	EOR #$FF
	SEC
	ADC var::param_4
	STA var::param_4
	LDA var::param_5
	SBC #$00
	STA var::param_5

@rowLoop:
	;Assume background colours are never in the source.
	LDA (var::sprite_source_ptr),Y
	AND #%01010101
	PHA
	;Collisions detection (assumes there is only one player)
	AND (var::param_4),Y
	BEQ @notDeath
	STA var::death
@notDeath:
	PLA
	ASL A
	EOR #%11111111
	AND (var::param_4),Y
	ORA (var::sprite_source_ptr),Y
	STA (var::sprite_image_ptr),Y

	INY
	TYA
	AND #%00000111
	BNE @rowLoop
	TYA
	CMP #(6 * 8)
	BNE @charLoop

	testRasterValuesPost

	RTS

rotateSpriteVert:
	LDA #0
	JSR @rotateSpriteColumn
	LDA #1

;A in 0..2 is the column to rotate.
@rotateSpriteColumn:
	;A and dir become a look-up in the SPRITE_ROTATE_VERT_LUT
	CLC
	ADC var::sprite_dir
	AND #%00000011
	CLC
	ASL
	ASL
	TAX
	
	;var::param_0 is a loop limit
	STX var::param_0
	INX
	INX
	LDY SPRITE_ROTATE_VERT_LUT,X
	STY var::param_1

@shiftOneColumnLoop:
	;Loop while var::param_2 >= var::param_0
	STX var::param_2

@shiftOneChar:
	LDX #8
@shiftOneCharLoop:
	;Swap var::param_3 with the sprite data
	LDA var::param_3
	PHA
	LDA (var::sprite_source_ptr), Y
	STA var::param_3
	PLA
	STA (var::sprite_source_ptr), Y

	TYA
	CLC
	ADC var::sprite_dir
	TAY

	DEX
	BNE @shiftOneCharLoop

	;Adjust counter (var::param_2) and test against limit
	LDX var::param_2
	DEX
	LDY SPRITE_ROTATE_VERT_LUT,X
	CPX var::param_0

	BPL @shiftOneColumnLoop
	
	;Account for the starting byte
	LDA var::param_3
	LDY var::param_1
	STA (var::sprite_source_ptr),Y
	RTS

moveSprite:
	LDX var::sprite_axis
	LDA var::sprite_x,X
	CLC
	ADC var::sprite_dir
	STA var::sprite_x,X
	LDX var::sprite_axis
	BEQ @moveSpriteHoriz

@moveSpriteVert:
	JSR rotateSpriteVert
@dontRotateHoriz:
	RTS

@moveSpriteHoriz:
	AND #%00000001
	BNE @dontRotateHoriz
	;Rotate twice because it's multicolour mode.
	JSR rotateSpriteHoriz
	;Fall through
	;JSR rotateSpriteHoriz
	;RTS

rotateSpriteHoriz:
	;var::param_0 is the row of characters 0..1
	LDA #2
	STA var::param_0
	LDA var::sprite_source_offset
	TAX
	;Remember the value
	PHA
	
@rotateACharRowOneBit:
	;var::param_2 is the char we are manipulating
	LDA #3
	STA var::param_2

	LDA var::sprite_dir
	CMP #DIR_BACK
	BEQ @rotateLeft

@rotateRight:
	;A will be a shift register for the bits which move between bytes
	LDA #0
	CLC
	
@rotateACharCellRight:
	;for each byte in the row.
	LDY #8
	ROR A

@rotateAByteRight:
	ROR CHR_LOCATION_SPRITE_SOURCE, X
	ROR A
	INX
	DEY
	BNE @rotateAByteRight
	DEC var::param_2
	BNE @rotateACharCellRight

	;Move X back to the start (temporarily store A in Y)
	TAY
	PLA
	TAX
	PHA
	TYA

	;We apply the 8 overflow bits in A to the each of the bytes in the char
	LDY #8

@applyOverflowBitsAtLeft:
	ASL CHR_LOCATION_SPRITE_SOURCE, X
	ROR A
	ROR CHR_LOCATION_SPRITE_SOURCE, X
	INX
	DEY
	BNE @applyOverflowBitsAtLeft
	JMP @unify
@rotateLeft:
	TXA
	CLC
	ADC #(8 * 3) - 1
	TAX
	
	;A will be a shift register for the bits which move between bytes
	LDA #0
	CLC

@rotateACharCellLeft:
	;for each byte in the row.
	LDY #8
	ROL A

@rotateAByteLeft:
	ROL CHR_LOCATION_SPRITE_SOURCE, X
	ROL A
	DEX
	DEY
	BNE @rotateAByteLeft
	DEC var::param_2
	BNE @rotateACharCellLeft

	;Move X back to the start (temporarily store A in Y)
	TAY
	PLA
	PHA
	CLC
	ADC #(8 * 3) - 1
	TAX
	TYA

	;We apply the 8 overflow bits in A to the each of the bytes in the char
	LDY #8

@applyOverflowBitsAtRight:
	LSR CHR_LOCATION_SPRITE_SOURCE, X
	ROL A
	ROL CHR_LOCATION_SPRITE_SOURCE, X
	DEX
	DEY
	BNE @applyOverflowBitsAtRight

@unify:
	;Move X back to the start.
	PLA
	TAX
	PHA

	;Move X to the next row.
	PLA
	CLC
	ADC #(8 * 3)
	PHA
	TAX
	
	DEC var::param_0
	BNE @rotateACharRowOneBit

	PLA
	RTS


;Move the screen pointer to X and Y	
	.assert .LOBYTE(COLOUR_LOCATION) = 0, error, "Account for unaligned colour location"
	.assert .LOBYTE(COLOUR_LOCATION) = .LOBYTE(SCREEN_LOCATION), error, "Account for unaligned screen location"
moveScreenAndColourPtrXY:
	TXA
	CLC
	ADC #NUM_VIDEO_COLUMNS
	ADC SCREEN_ROW_LUT_LOW,Y
	STA var::colour_ptr
	STA var::screen_ptr
	LDA #.HIBYTE(SCREEN_LOCATION)
	ADC #0		;Capture the carry from adding X and .LOBYTE(Y * 19) 
	CPY #14		;Carry = (Y * 19 > 255)
	ADC #0		;Capture the carry from adding .HIBYTE(Y * 19)
	STA var::screen_ptr_hi
	CLC
	ADC #.HIBYTE(COLOUR_LOCATION) - .HIBYTE(SCREEN_LOCATION)
	STA var::colour_ptr_hi
	RTS

;Access the target chars in the screen layer.
screenCharGetTarget:
	LDA #CHR_BUFF_END
	BNE setLayer

;Access the target char in the current sprite's layer (or above)
spriteCharGetTarget:
	LDA var::sprite_start_chr
setLayer:
	STA var::layer_chr

;var::layer_chr should be the lowest char of the layer we're interested in.
;Y is an offset from the screen ptr to the char we're targetting.
;The result is that var::target_char_ptr points to the target char.
;Afterwards Y will still be a valid offset, but may be different if
;the target was in a back buffer.
charGetTargetContinue:
	LDA var::layer_chr
	;Assume character is on screen
	LDA var::screen_ptr
	STA var::target_char_ptr
	LDA var::screen_ptr_hi
	STA var::target_char_ptr_hi

	;See if we've found a character of the appropriate layer.
@checkInLayer:
	LDA (var::target_char_ptr),Y
	CMP var::layer_chr
	;Branch if the character in A is actually from a lower sprite.
	BCC @spriteCharGetBackBufferTarget
	RTS

@spriteCharGetBackBufferTarget:
	;Otherwise, get a pointer to the corresponding back-buffer
	;of the higher-numbered sprite and try again.
	;we know that (char <= CHR_BUFF_END)
	.assert CHR_BUFF_START < .LOBYTE(BACK_BUFFERS), error, "Buffers have moved"
	;Note: arrived here with a clear carry
	ADC #.LOBYTE(BACK_BUFFERS) - CHR_BUFF_START
	STA var::target_char_ptr
	;Assume no page is advanced here.
	.assert .LOBYTE(BACK_BUFFERS) + 12 < 256, error, "Back buffers cross a page boundary"
	LDA #.HIBYTE(BACK_BUFFERS)
	STA var::target_char_ptr_hi
	;The pointer is to the actual target, so there is no offset.
	LDY #0
	;This always branches.
	BEQ @checkInLayer

baddyCallback:
	LDA var::sprite_has_updated
	BEQ @dontCheckLimits
	;Check baddy limits
	LDX var::sprite_axis
	LDA var::sprite_x,X
	CMP var::baddy_upper_limit
	BEQ @atUpperLimit
	CMP var::baddy_lower_limit
	BNE @notAtLowerLimit
@atUpperLimit:
	JSR changeSpriteDirection
@notAtLowerLimit:
@dontCheckLimits:
	RTS

playerCallback:
	;Silence player sounds when a char-cell boundary is reached.
	JSR silenceGame

	;Get player coords in chars
	LDA var::sprite_x
	JSR divABy24
	;Ensure the sprite is 3-char aligned.
	BCC @alignedX
	RTS

@alignedX:
	STA var::floor_x
	LDA var::sprite_y
	JSR divABy24
	;Ensure the sprite is 3-char aligned.
	BCC @alignedY
	RTS

@alignedY:
	STA var::floor_y
	JSR getFloorData

@handleCorners:
	AND #%00001100
	BNE @notCorner
	LDA #SOUND_CORNER_NOTE
	STA SOUND_CORNER_REGISTER
	JSR changePlayerAxis
	LDA var::floor_data
	AND #%00000010
	BEQ @walls
	JSR changePlayerDirection
@walls:
	JMP @handleWalls

@notCorner:
	;Check Do/Don't status before considering other floor tiles
	LDA VIC_SCREEN_COLOUR_REVERSE_AND_BORDER
	CMP #DO_VALUE
	BEQ @doValue
	JMP @handleWalls
@doValue:

	;Handle twirls
	LDA var::floor_data
	AND #%00001010
	BNE @notTwirl
	JSR changePlayerAxis
	LDA #SOUND_TWIRL_NOTE
	STA SOUND_TWIRL_REGISTER
	LDA var::floor_data
	AND #%00000001
	EOR var::sprite_axis
	BEQ @gotoWalls
	JSR changePlayerDirection
@gotoWalls:
	JMP @handleWalls

@notTwirl:
	;Handle Key
	LDA var::floor_tile
	CMP #FLOOR_KEY
	BNE @notKey
	
	JSR preSwapFloorTest
	BEQ @notKey
	LDA #FLOOR_GAP
	JSR swapFloor
	INC var::num_keys
	LDA #CHR_KEY_SYMBOL
	JSR adjustKeySymbols
	LDA #SOUND_KEY_NOTE
	STA SOUND_KEY_REGISTER
@notLastKey:
	JMP @handleWalls

@notKey:
	LDA var::floor_tile
	CMP #FLOOR_SWITCH_LEFT
	BNE @notSwitch

	JSR preSwapFloorTest
	BEQ @switchIsRight
	LDA #FLOOR_SWITCH_RIGHT
@switchIsRight:
	BNE @switchIsLeft
	LDA #FLOOR_SWITCH_LEFT
@switchIsLeft:
	JSR swapFloor
	JSR switchBarriers
	JSR resetSpritePos

	LDA #SOUND_SWITCH_NOTE
	STA SOUND_SWITCH_REGISTER
	JMP @handleWalls

@notSwitch:
	CMP #FLOOR_FINISH
	BNE @notFinish
	JMP complete
@notFinish:
	CMP #FLOOR_TELEPORT
	BNE @notTeleport

	;Draw the teleport over the sprite.
	LDA #FLOOR_TELEPORT
	JSR spriteDrawFloor

	;Set x to be the teleport offset (0 or 2) the player is not at.
	LDX #2
	;Loop over the x and y coordinates of teleport 1.
	LDY #1
@coordLoop:
	LDA var::sprite_x,Y
	CMP var::teleport_1_x,Y
	BNE @teleport0
	DEY
	BPL @coordLoop
	LDX #0
@teleport0:
	;Replace sprite chars by back chars

	LDA var::teleport_0_x,X
	STA var::sprite_x
	LDA var::teleport_0_y,X
	STA var::sprite_y

	JSR resetSpritePos

	;Draw the teleport over the sprite.
	LDA #FLOOR_PLAYER
	JSR spriteDrawFloor

	LDA #SOUND_TELEPORT_NOTE
	STA SOUND_TELEPORT_REGISTER

@notTeleport:
	;Other floor tiles here.

@handleWalls:
	LDA var::sprite_dir
	LDX var::sprite_axis
	JSR getNeighbourOffsets
	LDY var::neighbour_offset_0
	JSR screenCharGetTarget

	CMP #CHR_GAP
	BEQ @gap
	CMP #CHR_BARRIER_OPEN
	BEQ @gap

	CMP #CHR_DOOR
	BNE @notDoor
	;See if we can unlock the door
	LDA var::num_keys
	BEQ @wallBounce
	LDA #SOUND_DOOR_NOTE
	STA SOUND_DOOR_REGISTER
	LDA #CHR_GAP
	STA (var::target_char_ptr), Y
	LDA #8 | COLOUR_RED
	STA (var::colour_ptr),Y
	LDY var::neighbour_offset_1
	JSR screenCharGetTarget
	LDA #CHR_GAP
	STA (var::target_char_ptr), Y
	LDA #8 | COLOUR_RED
	STA (var::colour_ptr),Y
	LDA #CHR_GAP
	JSR adjustKeySymbols
	DEC var::num_keys
@gap:
	RTS

@notDoor:
	CMP #CHR_BARRIER_ELECTRIFIED
	BNE @notBarrier
	BEQ @death

@notBarrier:
	;Handle spikes
	STA var::param_0
	LDA var::sprite_dir
	AND #%00000010
	CLC
	ADC var::sprite_axis
	ADC #CHR_SPIKE_LEFT
	;This algorithm depends on the sequence of spike characters
.assert CHR_SPIKE_UP = CHR_SPIKE_LEFT + 1, error, "Spikes out of sequence"
.assert CHR_SPIKE_RIGHT = CHR_SPIKE_LEFT + 2, error, "Spikes out of sequence"
.assert CHR_SPIKE_DOWN = CHR_SPIKE_LEFT + 3, error, "Spikes out of sequence"
	CMP var::param_0
	BNE @wallBounce
@death:
	STA var::death
	RTS

@wallBounce:
	LDY #SOUND_WALL_NOTE
	STY SOUND_WALL_REGISTER
	JSR changePlayerDirection

	RTS

resetSpritePos:
	LDA var::sprite_y
	;set Y to be (var::sprite_y / 8) - 1
	LSR
	LSR
	LSR
	TAY

	LDA var::sprite_x
	;set X to be (var::sprite_x / 8) - 1
	LSR
	LSR
	LSR
	TAX

	;Get hole offsets in var::param_(0,1)
	JSR getHoleOffsets

	;Move the screen pointer to one char above and left of the sprite.
	DEY
	DEX
	JSR moveScreenAndColourPtrXY
	RTS

;Given that var::floor_x and var::floor_y are floor coordinates, set the
;pixel coordinates, where y points to the y-coord.
;Modifies X, Y and A.
setPixelCoordsFromFloor:
	LDX #1
@xAndYLoop:
	LDA var::floor_x,X
	JSR mulABy3
	ADC #1
	ASL
	ASL
	ASL
	;By using an offset from 0, we get a sort of indirect addressing mode
	STA 0,Y
	;Shift to the x-coordinate.
	DEY
	DEX
	BPL @xAndYLoop
	RTS

;If A corresponds to a pixel coord aligned to a floor square
;this puts the floor coord in A
;Sets the carry flag if the result was 1 mod 3.
divABy24:
	LSR A
	LSR A
divABy6:
	LSR A
	TAY
	LDA DIV_3_LUT,Y
	;Shift right and set carry appropriately
	LSR
	RTS

;Draw a text screen using the strings in the text table from offset X.
textScreen:
	;Store the argument in param_0
	STX var::param_0

	;Use a ROM character set.
	LDA #SCREEN_AND_CHAR_LOC_TEXT
	STA VIC_SCREEN_AND_CHAR_LOC
	;Set the background
	LDA #TEXT_BG
	STA VIC_SCREEN_COLOUR_REVERSE_AND_BORDER

	LDY #((NUM_VIDEO_COLUMNS * NUM_VIDEO_ROWS) / 2) + 1
@spaceLoop:
	LDA #PETSCII_SPACE
	STA SCREEN_LOCATION - 1 ,Y
	STA SCREEN_LOCATION + ((NUM_VIDEO_COLUMNS * NUM_VIDEO_ROWS) / 2),Y
	LDA #TEXT_FG
	STA COLOUR_LOCATION - 1, Y
	STA COLOUR_LOCATION + ((NUM_VIDEO_COLUMNS * NUM_VIDEO_ROWS) / 2),Y
	DEY
	BNE @spaceLoop

	;Restore the argument
	LDX var::param_0

@lineLoop:
	INX
	LDY TEXT_LUT,X
	BEQ @endOfText
	INX
	;Terporarily store X in param_0
	STX var::param_0
	LDA TEXT_LUT,X
	TAX
	JSR moveScreenAndColourPtrXY
	LDX var::param_0

	LDY #0
@stringLoop:
	INX
	LDA TEXT_LUT,X
	LSR
	PHP	;Remember the carry flag
	STA (var::screen_ptr),Y
	CMP #PETSCII_HEART
	BNE @ordinaryChar
	LDA #COLOUR_RED
	STA (var::colour_ptr),Y
@ordinaryChar:
	INY
	PLP	;Restore the carry
	BCC @stringLoop

	BCS @lineLoop
@endOfText:

	STX var::param_0

	;Wait for a new key press.
	LDA #0
	STA var::key_event
@eventLoop:
	;A is 0 at this loop entrance.
	STA var::cheat ; Reuse the cheat variable for this.

	LDX var::param_0
	CPX #TEXT_OFFSET_INTRO_END
	BNE @notIntro

	LDA #PETSCII_HEART 
	JSR drawAtSpeedSelectorPos

	LDA var::cheat
	BEQ @notRestore

	;Clear the current selector
	LDA #PETSCII_SPACE		
	JSR drawAtSpeedSelectorPos
	;X is still the old rate.
	LDY SPEED_SWAP_LUT,X
	STY var::player_rate

@notIntro:
@notRestore:
	LDA var::key_event
	BEQ @eventLoop

	RTS

drawAtSpeedSelectorPos:
	LDX var::player_rate
	LDY HEART_SELECTOR_OFFSET_LUT,X
	STA SCREEN_LOCATION + (NUM_VIDEO_COLUMNS * 10) + 2,Y
	LDA #COLOUR_RED
	STA COLOUR_LOCATION + (NUM_VIDEO_COLUMNS * 10) + 2,Y
	RTS

mulABy3:
	STA var::mulABy3Tmp
	ASL
	CLC
	ADC var::mulABy3Tmp
	RTS

;Put the floor data at (var::floor_x, var::floor_y) in var::floor_data
;Modifies A, X and Y registers.
getFloorData:
	LDX var::floor_x
	LDY var::floor_y
	;A is a mask which is used to handle the outer walls
	LDA #%00000000

	;Handle top and bottom outer walls
	CPY #0
	BNE @yNot0
	ORA #%10000000
@yNot0:
	CPY #NUM_GAME_ROWS
	BNE @yNot7
	ORA #%01000000
	LDY #0	; Y is mod 6
@yNot7:

	;Handle left and right outer walls
	CPX #0
	BNE @xNot0
	ORA #%00100000
@xNot0:
	CPX #NUM_GAME_COLUMNS
	BNE @xNot7
	ORA #%00010000
	LDX #0	; X is mod 6
@xNot7:
	PHA

	;Use the coords to construct an offset in the level data
	TXA
	CLC
	ADC MUL_6_LUT, Y
	TAY

	;Look-up the floor tile and combine it with the mask constructed above
	PLA
	ORA (var::leveldata_ptr),Y
	STA var::floor_data
	AND #%00001111
	STA var::floor_tile
	RTS

animateExchange:
	LDA CHR_LOCATION_ANIMATION_START,X
	PHA
	LDA CHR_LOCATION_ANIMATION_START,Y
	STA CHR_LOCATION_ANIMATION_START,X
	PLA
	STA CHR_LOCATION_ANIMATION_START,Y
	RTS

;****************************************************************
;* ROUTINES IN LOW MEMORY
;****************************************************************
	.segment "LOW1"

	;Buffer for exomizer
	.byte 0,0,0

switchBarriers:
	;Handle doors, which follow the level
	LDY #NUM_GAME_COLUMNS * NUM_GAME_ROWS
	STY var::param_0
	
@handleDoor:
	LDY var::param_0
	LDA (var::leveldata_ptr), Y
	;Ignore doors
	CMP #BARRIER_TERMINATOR
	BCS @noMoreBarrier
	TAY
	AND #%00000011
	BEQ @barrierIsDoor
	TYA

	JSR getBarrierTargets
	;Look at the character currently on the screen and compare it to the
	;one stored in the level.
	LDY var::neighbour_offset_0
	LDA (var::screen_ptr),Y
	LDY var::barrier_type
	CMP var::barrier_type
	BNE @altState
	INY
@altState:
	LDA BARRIER_SWITCH_LUT,Y
	JSR drawBarrierChars

@barrierIsDoor:
	INC var::param_0
	BNE @handleDoor
@noMoreBarrier:
	RTS

drawBarrierChars:
	;Write two characters in A to the screen at Y-offsets var::param_2 and var::param_3.
	;Note: Sprites can't overlap a barrier, so we don't check back
	;buffers.
	LDX #1
@twoDoorChars:
	STX var::drawBarrierCharsTmp
	LDY var::neighbour_offset_0,X
	JSR placeWallPiece
	LDX var::drawBarrierCharsTmp
	DEX
	BPL @twoDoorChars
	RTS

	;Decode a barrierdata
	;The screen pointer is moved to the encoded locations
	;with var::neighbour_offset_0 and _1 encoding the offsets from the
	;screen ptr to the actual character locations.
	;Sets var::barrier_type is the barrier type.
	;TODO this is pants. Rewrite
getBarrierTargets:
	PHA
	AND #%00000011
	CLC
	ADC #CHR_DOOR
	STA var::barrier_type
	PLA
	LSR
	LSR
	LDY #0
	LSR
	BCC @axisIsHorizontal
	LDY #1
@axisIsHorizontal:
	STY var::param_3
	;var::param_1 = (y * 6) + x
	STA var::param_1
	;A = y
	JSR divABy6
	;var::param_2 = y * 3
	JSR mulABy3
	PHA
	ADC #3
	STA var::param_2
	PLA
	;A = -(y * 6) + (var::param_1)
	ASL
	EOR #$FF
	SEC
	ADC var::param_1
	;X = x * 3
	JSR mulABy3
	STA var::param_1

	;Move the screen and colour pointers
	LDY var::param_2
	LDX var::param_1

	;Handle the flipped case.
	LDA var::param_3
	BNE @invert
	LDY var::param_1
	LDX var::param_2
@invert:

	JSR moveScreenAndColourPtrXY
	;Get the neighbour offsets (Encoding only uses up/left direction)
	LDA #DIR_BACK
	LDX var::param_3
	JSR getNeighbourOffsets
	RTS

rasterSkip:
@rasterSkip1:
	CPX VIC_RASTER_HIGH_BITS
	BCC @rasterSkip1

@rasterSkip2:
	CPX VIC_RASTER_HIGH_BITS
	BCS @rasterSkip2
	RTS

advanceLevel:
	LDA var::leveldata_ptr
	CLC
	ADC var::size_of_level
	STA var::leveldata_ptr
	BCC @noCarry
	INC var::leveldata_ptr_hi
@noCarry:
	INC var::num_level

	;fall through

resetSprites:
	;Clear the back-buffers
	LDX #(2 * 6) - 1
	LDA #CHR_GAP
@byteLoop:
	STA BACK_BUFFERS,X
	DEX
	BPL @byteLoop

	;Restore all the sprite source position within its original characters.
	LDX #SPRITE_LOOP_START
	STX var::sprite_struct_0ptr

@spriteResetLoop:
	;We don't copy the sprite values back.
	LDA #SPRITE_FULL_STRUCT_SIZE
	LDY #SPRITE_STRUCT_START
	JSR zeroPageCopy
	;Handle sprite dying in first column by adding 24.
	LDX var::sprite_axis
	LDA var::sprite_x,X
	CLC
	ADC #24
	STA var::sprite_x,X

@keepRotating:
	LDX var::sprite_axis
	LDA var::sprite_x,X
	AND #%00000111
	BNE @dontTestForAlignment
	LDA var::sprite_x,X
	JSR divABy24
	BCC @aligned
@dontTestForAlignment:
	JSR moveSprite
	JMP @keepRotating

@aligned:
	JSR updateCharsNoMove
	
	LDA var::sprite_struct_0ptr
	CLC
	ADC #SPRITE_FULL_STRUCT_SIZE
	TAX
	STA var::sprite_struct_0ptr
	CMP #SPRITE_LOOP_FINISH
	BNE @spriteResetLoop
	
	RTS

	;Copy a chunk of A bytes from X to Y.
zeroPageCopy:
	STA var::param_0
@loop:
	LDA 0, X
	STA 0, Y
	INX
	INY
	DEC var::param_0
	BNE @loop
	RTS

changePlayerAxis:
	LDA #1
	EOR var::sprite_axis
	STA var::sprite_axis
	JSR setEyes
	RTS

changePlayerDirection:
	JSR changeSpriteDirection

;Given the player source is in the aligned position, adjust the eyes to the
;direction and axis.
setEyes:
	LDA var::sprite_dir
	AND #%00000010
	ORA var::sprite_axis
	ASL
	ASL
	ASL
	STA var::param_0
	LDX #7
@loop:
	LDY var::param_0
	LDA EYE_CHR_LUT, Y
	LDY EYE_OFFSET_LUT, X
	STA CHR_LOCATION_PLAYER,Y
	INC var::param_0
	DEX
	BPL @loop
	RTS

;**********************************************
;* VECTORS
;**********************************************

	;We have to put these vectors where the ROM expects them
	.segment "LOW2"

	;pointer to main interrupt handler
	.word irqInterruptHandler

	;Use the unused break vector to hold a two byte look-up table.
WALL_MASK_LUT:
	.byte %00110000, %11000000

	;Pointer to the NMI interrupt handler
	.word nmiInterruptHandler

;**********************************************
;* MORE STUFF FOR LOW MEMORY
;**********************************************

	.segment "LOW3"

changeSpriteDirection:
	LDA #$FE
	EOR var::sprite_dir
	STA var::sprite_dir
	RTS

;Mult 0..7 by 6 result (mod 6)
MUL_6_LUT:
	.byte 0,6,12,18,24,30,36

complete:
	LDX var::num_level
	LDA #CHR_HEART_FULL
	STA HEARTBAR_LOCATION,X
	JSR silenceGame
	LDA #SOUND_COMPLETE_NOTE
	STA SOUND_COMPLETE_REGISTER
	LDX #COMPLETE_LOOP_LENGTH
	;Play an ascending sequence of notes.
@completeLoop:
	JSR rasterSkip
	INC SOUND_COMPLETE_REGISTER
	DEX
	BNE @completeLoop
	JSR advanceLevel
	JSR silenceGame
	;Remove return addresses from the stack so we can jump directly.
	PLA
	PLA
	PLA
	PLA
	JMP loadLevel

;Given an alternative floor tile in A, replace the one in the back buffer
preSwapFloorTest:
	LDY #NUM_VIDEO_COLUMNS + 1
	JSR screenCharGetTarget
	LDA (var::target_char_ptr),Y
	;TODO consider using a logical operator here.
	CMP #CHR_GAP
	RTS

spriteDrawFloor:
	LDY var::sprite_start_chr
	STY var::layer_chr

drawFloor:
swapFloor:
	STA var::drawFloorTmp1
	;Loop 4 times for the 4 characters in a floor tile.
	LDX #3
@offsetsLoop:
	STX var::drawFloorTmp2

	LDY FLOOR_OFFSET_LUT,X
	;Colour data is unaffected by layers, so perform update before
	;target check.
	LDX var::drawFloorTmp1
	LDA FLOOR_COLOUR_DATA, X
	STA (var::colour_ptr),Y
	JSR charGetTargetContinue
	
	LDA var::drawFloorTmp1
	;Multiply A by 4
	CLC
	ASL
	ASL
	ADC var::drawFloorTmp2
	;X indexs into the four floor chars
	TAX
	LDA FLOOR_DATA,X
	STA (var::target_char_ptr),Y

	LDX var::drawFloorTmp2
	DEX
	BPL @offsetsLoop
	RTS

	;Call this after changing a key value
adjustKeySymbols:
	LDX var::num_keys
	LDY LIFE_POS_LUT - 1,X
	STA KEY_LOCATION,Y
	RTS

;*****************************************************************************
;* INTERRUPT
;*****************************************************************************

irqInterruptHandler:
	;Increment the timers.
	INC var::timer_time
	INC var::timer_player
	INC var::timer_baddy
	INC var::timer_animation

	;If there is a keyboard event which has not yet been processed, nothing to do.
	LDY var::key_event
	BNE @endOfInterrupt 

	STY VIA_1_PORT_A_DDR
	;Check if the column indicates a keydown.
	STY VIA_2_PORT_B_IO_REGISTER
	LDX VIA_2_PORT_A_IO_REGISTER
	INX
	BNE @someKeyIsDown
	;Joystick
	LDA VIA_1_PORT_A_IO_REGISTER
	AND #%00010000
	BNE @noKeysAreDown
@someKeyIsDown:
	;Some key is down, so Y goes from 0 to 1.
	INY
	LDA var::key_state
	BNE @notANewEvent
	STY var::key_event
@noKeysAreDown:
@notANewEvent:
	STY var::key_state
@endOfInterrupt:
	;Ensure the interrupt refires appropriately and restore registers
	JMP ROM_END_OF_INTERRUPT

nmiInterruptHandler:
	PHA
	;Interrupt operations here.
	;clear the interrupt flag so it can retrigger
	LDA #%01111111
	STA var::skip
	STA var::cheat
	STA VIA_1_INTERRUPT_FLAG_REGISTER
	;TODO May need to back up all registers, in which case I can 
	;JMP END_OF_NMI_INTERRUPT
	PLA
	RTI

;*****************************************************************************
;* DATA
;*****************************************************************************
	.segment "LEVELDATA"

.macro	floordata top, left, floor
	.byte (top << 6) + (left << 4) + floor
.endmacro

BARRIER_DOOR = 0
BARRIER_OPEN = 1
BARRIER_CLOSED = 2
BARRIER_ELECTRIFIED = 3

;Combine a direction and an axis.
DIRAX_RIGHT 	= %10
DIRAX_LEFT 	= %00
DIRAX_DOWN 	= %11
DIRAX_UP	= %01

WALL_OPEN	= %00
WALL_WALL	= %11
SPIKE_UP	= %01
SPIKE_DOWN	= %10
SPIKE_LEFT	= %01
SPIKE_RIGHT	= %10
;Only available at far left and top
SPIKE_BOTH	= %00

	;We only need 5 bits to store the 0..25 (x,y) positions for doors and
	;barriers. Since there is no divide by 5 routine, but there is
	;a divide by 6 routine, I use div 6. However, I exploit the axis
	;to guarantee that x * y is less than 32.
	;Note: A horizontal axis here implies the door blocks horizontal
	;motion.
	;TODO check that a div 5 LUT would be worthwhile
.macro  barrierdata type, yy, xx, axis
.if (axis = AXIS_VERTICAL)
	.byte ((((yy - 1) * 6) + xx) << 3) + (axis << 2) + type
.else
	.byte ((((xx - 1) * 6) + yy) << 3) + (axis << 2) + type
.endif
.endmacro

;This is also the barrier terminator 
;TODO still have bits 2 and 3 spare!
.macro playermetadata dirax
	.byte BARRIER_TERMINATOR + dirax
.endmacro

;TODO there must be a more efficient encoding of the limits.
.macro baddymetadata dirax, lowerlimit, upperlimit
	.byte (lowerlimit << 2) + (upperlimit << 5) + dirax
.endmacro

LEVEL_DATA:

;;template
;	floordata WALL_WALL,	WALL_WALL,	FLOOR_GAP
;	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_WALL, 	WALL_OPEN,	FLOOR_GAP
;	;
;	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
;	;
;	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
;	;
;	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_PLAYER
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
;	;
;	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
;	;
;	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
;	;
;	playermetadata DIRAX_RIGHT

;intro
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_WALL,	WALL_WALL,	FLOOR_GAP
	floordata WALL_WALL,	WALL_WALL,	FLOOR_CORNER_TL
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL, 	WALL_OPEN,	FLOOR_CORNER_TR
	;
	floordata WALL_WALL,	WALL_WALL,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_PLAYER
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_ANTICLOCKWISE
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CORNER_TR
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	;
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_FINISH
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_CORNER_BL
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
	;
	floordata WALL_WALL,	WALL_WALL,	FLOOR_CORNER_TL
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_ANTICLOCKWISE
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CLOCKWISE
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CORNER_TR
	;
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	;
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_CORNER_BL
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
	;
	playermetadata DIRAX_RIGHT

;spikes 0
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata SPIKE_BOTH,	WALL_WALL,	FLOOR_GAP
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata SPIKE_UP,	WALL_WALL,	FLOOR_PLAYER
	floordata WALL_WALL, 	WALL_WALL,	FLOOR_BLOCK
	;
	floordata WALL_WALL,	WALL_WALL,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CLOCKWISE
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata SPIKE_DOWN,	WALL_OPEN,	FLOOR_CLOCKWISE
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CORNER_TR
	;
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	;
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_FINISH
	floordata WALL_OPEN,	SPIKE_RIGHT,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	;
	floordata WALL_WALL,	SPIKE_LEFT,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CLOCKWISE
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_ANTICLOCKWISE
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	;
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	;
	playermetadata DIRAX_DOWN

;spikes 1
	floordata SPIKE_DOWN,	SPIKE_BOTH,	FLOOR_CLOCKWISE
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_FINISH
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata SPIKE_DOWN, 	WALL_OPEN,	FLOOR_ANTICLOCKWISE
	;
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_CORNER_BL
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CORNER_TR
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	;
	floordata WALL_WALL,	SPIKE_RIGHT,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CLOCKWISE
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_PLAYER
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	;
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CLOCKWISE
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CORNER_TR
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	;
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata SPIKE_UP,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	;
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_CORNER_BL
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CLOCKWISE
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CLOCKWISE
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
	;
	playermetadata DIRAX_LEFT

;baddy 0
	floordata WALL_WALL,	WALL_WALL,	FLOOR_CORNER_TL
	floordata SPIKE_DOWN,	WALL_OPEN,	FLOOR_ANTICLOCKWISE
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CORNER_TR
	floordata SPIKE_UP,	WALL_WALL,	FLOOR_CORNER_TL
	floordata SPIKE_DOWN,	WALL_OPEN,	FLOOR_CLOCKWISE
	floordata WALL_WALL, 	WALL_OPEN,	FLOOR_CORNER_TR
	;
	floordata WALL_OPEN,	SPIKE_LEFT,	FLOOR_CORNER_BL
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CLOCKWISE
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_ANTICLOCKWISE
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	;
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata SPIKE_UP,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata SPIKE_UP,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	;
	floordata WALL_WALL,	SPIKE_LEFT,	FLOOR_BADDY
	floordata WALL_WALL,	WALL_WALL,	FLOOR_CORNER_TL
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_ANTICLOCKWISE
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_WALL,	WALL_WALL,	FLOOR_CORNER_TL
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_ANTICLOCKWISE
	;
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_FINISH
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_ANTICLOCKWISE
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_PLAYER
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_CORNER_BL
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
	;
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata SPIKE_UP,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	;
	playermetadata DIRAX_UP
	baddymetadata DIRAX_DOWN, 3, 5

;door 1
	floordata SPIKE_BOTH,	SPIKE_RIGHT,	FLOOR_FINISH
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata SPIKE_BOTH,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL, 	WALL_OPEN,	FLOOR_CORNER_TR
	;
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_WALL,	WALL_WALL,	FLOOR_CORNER_TL
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CLOCKWISE
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	;
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_WALL,	WALL_WALL,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_ANTICLOCKWISE
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CORNER_TR
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	;
	floordata WALL_OPEN,	SPIKE_RIGHT,	FLOOR_ANTICLOCKWISE
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CLOCKWISE
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CLOCKWISE
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
	;
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata SPIKE_UP,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_PLAYER
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	;
	floordata WALL_OPEN,	SPIKE_RIGHT,	FLOOR_CLOCKWISE
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_KEY
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	;
	barrierdata BARRIER_DOOR,1,0,AXIS_VERTICAL
	barrierdata BARRIER_DOOR,0,1,AXIS_HORIZONTAL
	barrierdata BARRIER_DOOR,3,4,AXIS_HORIZONTAL
	playermetadata DIRAX_UP

;teleport 0
	floordata WALL_WALL,	WALL_WALL,	FLOOR_CORNER_TL
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CORNER_TR
	floordata SPIKE_UP,	WALL_WALL,	FLOOR_CORNER_TL
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata SPIKE_UP,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL, 	WALL_OPEN,	FLOOR_CORNER_TR
	;
	floordata WALL_OPEN,	SPIKE_BOTH,	FLOOR_TELEPORT
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_CORNER_BL
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_ANTICLOCKWISE
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	;
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_WALL,	WALL_WALL,	FLOOR_CORNER_TL
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CORNER_TR
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_FINISH
	;
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_OPEN,	SPIKE_RIGHT,	FLOOR_CLOCKWISE
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CORNER_TR
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	;
	floordata WALL_WALL,	SPIKE_LEFT,	FLOOR_BLOCK
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_CORNER_BL
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_TELEPORT
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	;
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_WALL,	WALL_WALL,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_ANTICLOCKWISE
	floordata SPIKE_UP,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_PLAYER
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	;
	playermetadata DIRAX_UP

;switches 0
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata SPIKE_UP,	WALL_WALL,	FLOOR_CORNER_TL
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CORNER_TR
	floordata WALL_WALL, 	WALL_WALL,	FLOOR_BLOCK
	;
	floordata WALL_WALL,	SPIKE_LEFT,	FLOOR_CORNER_TL
	floordata SPIKE_DOWN,	WALL_OPEN,	FLOOR_CLOCKWISE
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CLOCKWISE
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	;
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_SWITCH_LEFT
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_WALL,	WALL_WALL,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_ANTICLOCKWISE
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CORNER_TR
	;
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_CORNER_BL
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	;
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata SPIKE_UP,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_WALL,	WALL_WALL,	FLOOR_FINISH
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
	;
	floordata WALL_WALL,	WALL_WALL,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_SWITCH_LEFT
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_ANTICLOCKWISE
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_PLAYER
	;
	barrierdata BARRIER_ELECTRIFIED, 4, 3, AXIS_VERTICAL
	barrierdata BARRIER_OPEN, 2, 5, AXIS_HORIZONTAL
	barrierdata BARRIER_CLOSED, 3, 2, AXIS_HORIZONTAL
	playermetadata DIRAX_LEFT

;baddy and door
	floordata WALL_WALL,	WALL_WALL,	FLOOR_CORNER_TL
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_ANTICLOCKWISE
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CORNER_TR
	floordata WALL_WALL,	WALL_WALL,	FLOOR_FINISH
	floordata SPIKE_DOWN,	WALL_OPEN,	FLOOR_GAP
	floordata SPIKE_DOWN, 	WALL_OPEN,	FLOOR_CLOCKWISE
	;
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_CORNER_BL
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CORNER_TR
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	;
	floordata WALL_WALL,	WALL_WALL,	FLOOR_CORNER_TL
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CORNER_TR
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_CLOCKWISE
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CLOCKWISE
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
	;
	floordata WALL_OPEN,	SPIKE_RIGHT,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CLOCKWISE
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_BADDY
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CLOCKWISE
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CLOCKWISE
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CORNER_TR
	;
	floordata WALL_OPEN,	SPIKE_RIGHT,	FLOOR_PLAYER
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata SPIKE_UP,	WALL_OPEN,	FLOOR_CORNER_TR
	floordata WALL_OPEN,	SPIKE_RIGHT,	FLOOR_KEY
	floordata WALL_OPEN,	SPIKE_LEFT,	FLOOR_GAP
	;
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_CORNER_BL
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_CORNER_BL
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
	;
	barrierdata BARRIER_DOOR, 2, 4, AXIS_HORIZONTAL
	playermetadata DIRAX_RIGHT
	baddymetadata DIRAX_UP, 1, 4

;teleport and switches
	floordata WALL_WALL,	WALL_WALL,	FLOOR_CORNER_TL
	floordata SPIKE_DOWN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CORNER_TR
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_WALL,	WALL_WALL,	FLOOR_CORNER_TL
	floordata WALL_WALL, 	WALL_OPEN,	FLOOR_CORNER_TR
	;
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_SWITCH_LEFT
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_PLAYER
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_TELEPORT
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
	;
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_CORNER_BL
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CORNER_TR
	;
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_CORNER_BL
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_TELEPORT
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_SWITCH_LEFT
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	;
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_SWITCH_LEFT
	;
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_FINISH
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
	;
	barrierdata BARRIER_CLOSED, 5, 1, AXIS_HORIZONTAL
	barrierdata BARRIER_CLOSED, 5, 2, AXIS_VERTICAL
	barrierdata BARRIER_ELECTRIFIED, 1, 2, AXIS_VERTICAL
	barrierdata BARRIER_OPEN, 1, 2, AXIS_HORIZONTAL
	barrierdata BARRIER_ELECTRIFIED, 2, 5, AXIS_HORIZONTAL
	playermetadata DIRAX_DOWN

;Switch and baddy
	floordata SPIKE_UP,	WALL_WALL,	FLOOR_CORNER_TL
	floordata SPIKE_UP,	WALL_OPEN,	FLOOR_CLOCKWISE
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL, 	WALL_OPEN,	FLOOR_CORNER_TR
	;
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_SWITCH_LEFT
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata SPIKE_DOWN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CLOCKWISE
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
	;
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_CORNER_BL
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_ANTICLOCKWISE
	floordata WALL_WALL,	SPIKE_LEFT,	FLOOR_BLOCK
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	;
	floordata WALL_WALL,	WALL_WALL,	FLOOR_CORNER_TL
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_ANTICLOCKWISE
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_SWITCH_LEFT
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CLOCKWISE
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CORNER_TR
	;
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_FINISH
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_BADDY
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_PLAYER
	;
	floordata WALL_OPEN,	SPIKE_RIGHT,	FLOOR_ANTICLOCKWISE
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata SPIKE_UP,	WALL_WALL,	FLOOR_BLOCK
	;
	barrierdata BARRIER_OPEN, 3, 3, AXIS_HORIZONTAL
	barrierdata BARRIER_CLOSED, 1, 3, AXIS_HORIZONTAL
	barrierdata BARRIER_ELECTRIFIED, 1, 4, AXIS_VERTICAL
	barrierdata BARRIER_OPEN, 3, 1, AXIS_VERTICAL
	playermetadata DIRAX_UP
	baddymetadata DIRAX_DOWN, 2, 5

;doors 2
	floordata WALL_WALL,	WALL_WALL,	FLOOR_KEY
	floordata SPIKE_DOWN,	WALL_OPEN,	FLOOR_CLOCKWISE
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_KEY
	floordata SPIKE_UP,	WALL_WALL,	FLOOR_CORNER_TL
	floordata WALL_WALL, 	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CORNER_TR
	;
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_KEY
	floordata WALL_OPEN,	SPIKE_RIGHT,	FLOOR_ANTICLOCKWISE
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CLOCKWISE
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_KEY
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_PLAYER
	;
	floordata WALL_OPEN,	SPIKE_RIGHT,	FLOOR_ANTICLOCKWISE
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CORNER_TR
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata SPIKE_DOWN,	WALL_WALL,	FLOOR_GAP
	floordata SPIKE_UP,	WALL_WALL,	FLOOR_BLOCK
	;
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_WALL,	WALL_WALL,	FLOOR_CORNER_TL
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_ANTICLOCKWISE
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	;
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_CORNER_BL
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CLOCKWISE
	floordata SPIKE_UP,	SPIKE_LEFT,	FLOOR_FINISH
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CORNER_TR
	;
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_CORNER_BL
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	SPIKE_LEFT,	FLOOR_CORNER_BL
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_ANTICLOCKWISE
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
	;
	barrierdata BARRIER_DOOR, 1, 2, AXIS_HORIZONTAL
	barrierdata BARRIER_DOOR, 3, 3, AXIS_VERTICAL
	barrierdata BARRIER_DOOR, 3, 2, AXIS_HORIZONTAL
	barrierdata BARRIER_DOOR, 5, 0, AXIS_VERTICAL
	barrierdata BARRIER_DOOR, 5, 5, AXIS_HORIZONTAL
	playermetadata DIRAX_UP

;switches 1
	floordata WALL_WALL,	WALL_WALL,	FLOOR_CORNER_TL
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_SWITCH_LEFT
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CORNER_TR
	floordata WALL_WALL,	WALL_WALL,	FLOOR_CORNER_TL
	floordata SPIKE_UP,	WALL_OPEN,	FLOOR_CORNER_TR
	floordata WALL_WALL, 	WALL_WALL,	FLOOR_BLOCK
	;
	floordata WALL_OPEN,	SPIKE_RIGHT,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_ANTICLOCKWISE
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CORNER_TR
	;
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_SWITCH_LEFT
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CLOCKWISE
	floordata SPIKE_UP,	WALL_OPEN,	FLOOR_CORNER_TR
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_FINISH
	;
	floordata WALL_OPEN,	SPIKE_RIGHT,	FLOOR_CLOCKWISE
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_PLAYER
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_ANTICLOCKWISE
	floordata SPIKE_UP,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CORNER_TR
	;
	floordata SPIKE_UP,	SPIKE_LEFT,	FLOOR_BLOCK
	floordata WALL_OPEN,	SPIKE_RIGHT,	FLOOR_CLOCKWISE
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata SPIKE_DOWN,	WALL_OPEN,	FLOOR_ANTICLOCKWISE
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	;
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_CORNER_BL
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_CORNER_BL
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_ANTICLOCKWISE
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
	;
	barrierdata BARRIER_CLOSED, 3, 4, AXIS_HORIZONTAL
	barrierdata BARRIER_OPEN, 2, 2, AXIS_VERTICAL
	barrierdata BARRIER_ELECTRIFIED, 5, 2, AXIS_VERTICAL
	barrierdata BARRIER_ELECTRIFIED, 2, 1, AXIS_HORIZONTAL
	barrierdata BARRIER_OPEN, 1, 1, AXIS_HORIZONTAL
	playermetadata DIRAX_RIGHT

;Doors and switches 0
	floordata WALL_WALL,	SPIKE_RIGHT,	FLOOR_CLOCKWISE
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_SWITCH_LEFT
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CORNER_TR
	floordata SPIKE_UP,	WALL_WALL,	FLOOR_CORNER_TL
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL, 	WALL_OPEN,	FLOOR_CORNER_TR
	;
	floordata WALL_OPEN,	SPIKE_BOTH,	FLOOR_PLAYER
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_ANTICLOCKWISE
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CLOCKWISE
	;
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_KEY
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_KEY
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	;
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata SPIKE_DOWN,	WALL_OPEN,	FLOOR_ANTICLOCKWISE
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_ANTICLOCKWISE
	floordata WALL_WALL,	SPIKE_LEFT,	FLOOR_BLOCK
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	;
	floordata WALL_OPEN,	SPIKE_LEFT,	FLOOR_CORNER_BL
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CLOCKWISE
	;
	floordata WALL_WALL,	SPIKE_RIGHT,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_FINISH
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
	floordata WALL_OPEN,	SPIKE_RIGHT,	FLOOR_CLOCKWISE
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
	;
	barrierdata BARRIER_ELECTRIFIED, 1, 3, AXIS_HORIZONTAL
	barrierdata BARRIER_OPEN, 4, 3, AXIS_HORIZONTAL
	barrierdata BARRIER_DOOR, 0, 1, AXIS_HORIZONTAL
	barrierdata BARRIER_CLOSED, 3, 1, AXIS_HORIZONTAL
	barrierdata BARRIER_DOOR, 2, 3, AXIS_VERTICAL
	playermetadata DIRAX_RIGHT
	;baddymetadata DIRAX_RIGHT, 1, 4

.if !TEST_RASTER_VALUES

;doors and switches 1
	floordata WALL_WALL,	WALL_WALL,	FLOOR_CORNER_TL
	floordata SPIKE_DOWN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata SPIKE_UP,	WALL_OPEN,	FLOOR_PLAYER
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL, 	WALL_OPEN,	FLOOR_CORNER_TR
	;
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_SWITCH_LEFT
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_SWITCH_LEFT
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	;
	floordata WALL_OPEN,	SPIKE_BOTH,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CLOCKWISE
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_ANTICLOCKWISE
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	;
	floordata WALL_OPEN,	SPIKE_RIGHT,	FLOOR_CLOCKWISE
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_KEY
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_KEY
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_KEY
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_KEY
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
	;
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
	;
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_CORNER_BL
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_CORNER_BL
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_ANTICLOCKWISE
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_FINISH
	;
	barrierdata BARRIER_DOOR, 4, 1, AXIS_VERTICAL
	barrierdata BARRIER_DOOR, 2, 3, AXIS_HORIZONTAL
	barrierdata BARRIER_DOOR, 2, 5, AXIS_HORIZONTAL
	barrierdata BARRIER_DOOR, 5, 3, AXIS_VERTICAL
	barrierdata BARRIER_DOOR, 5, 5, AXIS_HORIZONTAL
	barrierdata BARRIER_OPEN, 1, 1, AXIS_VERTICAL
	barrierdata BARRIER_CLOSED, 1, 2, AXIS_VERTICAL
	barrierdata BARRIER_ELECTRIFIED, 1, 3, AXIS_VERTICAL
	playermetadata DIRAX_RIGHT

;everything
	floordata SPIKE_UP,	SPIKE_LEFT,	FLOOR_CORNER_TL
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata SPIKE_DOWN,	WALL_OPEN,	FLOOR_CLOCKWISE
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata SPIKE_DOWN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL, 	WALL_OPEN,	FLOOR_FINISH
	;
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_KEY
	floordata WALL_WALL,	WALL_WALL,	FLOOR_CORNER_TL
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_ANTICLOCKWISE
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_WALL,	SPIKE_LEFT,	FLOOR_BLOCK
	;
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_KEY
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_BADDY
	floordata WALL_OPEN,	SPIKE_RIGHT,	FLOOR_CLOCKWISE
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CORNER_TR
	;
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_TELEPORT
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CLOCKWISE
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_TELEPORT
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
	;
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_CORNER_BL
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CLOCKWISE
	floordata WALL_OPEN,	SPIKE_LEFT,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_SWITCH_LEFT
	;
	floordata WALL_OPEN,	SPIKE_RIGHT,	FLOOR_ANTICLOCKWISE
	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_PLAYER
	floordata WALL_OPEN,	WALL_WALL,	FLOOR_CORNER_BL
	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
	;
	barrierdata BARRIER_DOOR,4,0,AXIS_VERTICAL
	barrierdata BARRIER_OPEN,0,4,AXIS_HORIZONTAL
	barrierdata BARRIER_ELECTRIFIED,1,2,AXIS_VERTICAL
	barrierdata BARRIER_DOOR,1,4,AXIS_VERTICAL
	playermetadata DIRAX_UP
	baddymetadata DIRAX_DOWN, 2, 4

;;intro
;	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
;	floordata WALL_WALL,	WALL_WALL,	FLOOR_GAP
;	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
;	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
;	floordata WALL_WALL,	WALL_WALL,	FLOOR_GAP
;	floordata WALL_WALL, 	WALL_WALL,	FLOOR_BLOCK
;	;
;	floordata WALL_WALL,	WALL_WALL,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_ANTICLOCKWISE
;	floordata WALL_WALL,	WALL_OPEN,	FLOOR_PLAYER
;	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CLOCKWISE
;	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
;	;
;	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
;	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
;	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
;	floordata WALL_WALL,	WALL_WALL,	FLOOR_FINISH
;	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
;	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
;	;
;	floordata WALL_WALL,	WALL_WALL,	FLOOR_CORNER_TL
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CLOCKWISE
;	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_ANTICLOCKWISE
;	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CORNER_TR
;	;
;	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
;	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
;	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
;	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
;	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
;	;
;	floordata WALL_OPEN,	WALL_WALL,	FLOOR_CORNER_BL
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
;	;
;	playermetadata DIRAX_RIGHT

;;spikes 2
;	floordata WALL_WALL,	WALL_WALL,	FLOOR_CORNER_TL
;	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CORNER_TR
;	floordata WALL_WALL,	WALL_WALL,	FLOOR_FINISH
;	floordata WALL_WALL,	WALL_WALL,	FLOOR_CORNER_TL
;	floordata SPIKE_DOWN,	WALL_OPEN,	FLOOR_ANTICLOCKWISE
;	floordata WALL_WALL, 	WALL_OPEN,	FLOOR_GAP
;	;
;	floordata WALL_OPEN,	SPIKE_LEFT,	FLOOR_PLAYER
;	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
;	floordata WALL_OPEN,	SPIKE_RIGHT,	FLOOR_CLOCKWISE
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
;	floordata WALL_OPEN,	WALL_WALL,	FLOOR_CORNER_BL
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_ANTICLOCKWISE
;	;
;	floordata SPIKE_UP,	WALL_WALL,	FLOOR_BLOCK
;	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
;	floordata WALL_WALL,	WALL_WALL,	FLOOR_GAP
;	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CORNER_TR
;	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
;	;
;	floordata WALL_WALL,	SPIKE_LEFT,	FLOOR_CORNER_TL
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_ANTICLOCKWISE
;	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CORNER_TR
;	floordata WALL_WALL,	SPIKE_RIGHT,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CLOCKWISE
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CLOCKWISE
;	;
;	floordata WALL_OPEN,	SPIKE_LEFT,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_WALL,	FLOOR_CORNER_BL
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_ANTICLOCKWISE
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
;	;
;	floordata WALL_OPEN,	WALL_WALL,	FLOOR_CORNER_BL
;	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
;	floordata WALL_OPEN,	WALL_WALL,	FLOOR_CORNER_BL
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
;	floordata SPIKE_UP,	WALL_WALL,	FLOOR_BLOCK
;	;
;	playermetadata DIRAX_UP

;;door 0
;	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
;	floordata SPIKE_UP,	WALL_WALL,	FLOOR_CORNER_TL
;	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CORNER_TR
;	floordata WALL_WALL,	WALL_WALL,	FLOOR_CORNER_TL
;	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_WALL, 	WALL_OPEN,	FLOOR_CORNER_TR
;	;
;	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
;	floordata WALL_OPEN,	WALL_WALL,	FLOOR_CORNER_BL
;	floordata SPIKE_UP,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CLOCKWISE
;	floordata WALL_WALL,	WALL_OPEN,	FLOOR_FINISH
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
;	;
;	floordata WALL_WALL,	WALL_WALL,	FLOOR_CORNER_TL
;	floordata SPIKE_DOWN,	WALL_OPEN,	FLOOR_CLOCKWISE
;	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CORNER_TR
;	;
;	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
;	floordata WALL_OPEN,	SPIKE_RIGHT,	FLOOR_KEY
;	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CLOCKWISE
;	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
;	;
;	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
;	floordata WALL_OPEN,	SPIKE_RIGHT,	FLOOR_PLAYER
;	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CLOCKWISE
;	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CORNER_TR
;	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
;	;
;	floordata WALL_OPEN,	WALL_WALL,	FLOOR_CORNER_BL
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CLOCKWISE
;	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
;	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
;	;
;	barrierdata BARRIER_DOOR, 2, 3, AXIS_VERTICAL
;	playermetadata DIRAX_RIGHT

;;baddy, key, switch
;	floordata WALL_WALL,	WALL_WALL,	FLOOR_PLAYER
;	floordata WALL_WALL,	WALL_WALL,	FLOOR_CORNER_TL
;	floordata SPIKE_UP,	WALL_OPEN,	FLOOR_CORNER_TR
;	floordata WALL_WALL,	WALL_WALL,	FLOOR_CORNER_TL
;	floordata WALL_WALL,	WALL_OPEN,	FLOOR_GAP
;	floordata WALL_WALL, 	WALL_OPEN,	FLOOR_FINISH
;	;
;	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
;	floordata WALL_WALL,	WALL_WALL,	FLOOR_CORNER_TL
;	floordata WALL_WALL,	WALL_OPEN,	FLOOR_CORNER_TR
;	;
;	floordata WALL_OPEN,	SPIKE_RIGHT,	FLOOR_ANTICLOCKWISE
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CLOCKWISE
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_BADDY
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CLOCKWISE
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_ANTICLOCKWISE
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_SWITCH_LEFT
;	;
;	floordata WALL_OPEN,	WALL_WALL,	FLOOR_SWITCH_LEFT
;	floordata SPIKE_UP,	WALL_WALL,	FLOOR_CORNER_TL
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_ANTICLOCKWISE
;	floordata WALL_OPEN,	SPIKE_LEFT,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_WALL,	FLOOR_CORNER_BL
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
;	;
;	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_WALL,	FLOOR_KEY
;	floordata WALL_OPEN,	WALL_WALL,	FLOOR_GAP
;	floordata WALL_OPEN,	WALL_WALL,	FLOOR_KEY
;	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
;	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
;	;
;	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
;	floordata WALL_OPEN,	WALL_WALL,	FLOOR_CORNER_BL
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CLOCKWISE
;	floordata WALL_OPEN,	WALL_OPEN,	FLOOR_CORNER_BR
;	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
;	floordata WALL_WALL,	WALL_WALL,	FLOOR_BLOCK
;	;
;	barrierdata BARRIER_OPEN, 3, 0, AXIS_VERTICAL
;	barrierdata BARRIER_DOOR, 3, 3, AXIS_VERTICAL
;	barrierdata BARRIER_DOOR, 1, 3, AXIS_VERTICAL
;	barrierdata BARRIER_ELECTRIFIED, 0, 5, AXIS_HORIZONTAL
;	playermetadata DIRAX_DOWN
;	baddymetadata DIRAX_RIGHT, 0, 3

.endif

; The look up table for floor blocks.
FLOOR_DATA:
FLOOR_LOCATION_START:
FLOOR_LOCATION_CORNER_TR:
	.byte CHR_GAP, CHR_CORNER_TR, CHR_GAP, CHR_GAP
FLOOR_LOCATION_CORNER_BL:
	.byte CHR_GAP, CHR_GAP, CHR_CORNER_BL, CHR_GAP
FLOOR_LOCATION_CORNER_TL:
	.byte CHR_CORNER_TL, CHR_GAP, CHR_GAP, CHR_GAP
FLOOR_LOCATION_CORNER_BR:
	.byte CHR_GAP, CHR_GAP, CHR_GAP, CHR_CORNER_BR
FLOOR_LOCATION_CLOCKWISE:
	.byte CHR_CLOCKWISE_TL, CHR_CLOCKWISE_TR, CHR_CLOCKWISE_BL, CHR_CLOCKWISE_BR
FLOOR_LOCATION_ANTICLOCKWISE:
	.byte CHR_ANTICLOCKWISE_TL, CHR_ANTICLOCKWISE_TR, CHR_ANTICLOCKWISE_BL, CHR_ANTICLOCKWISE_BR
FLOOR_LOCATION_KEY:
	.byte CHR_KEY_TL, CHR_KEY_TR, CHR_KEY_BL, CHR_KEY_BR
FLOOR_LOCATION_SWITCH_LEFT:
	.byte CHR_SWITCH_LEFT_TL, CHR_GAP, CHR_SWITCH_LEFT_BL, CHR_SWITCH_LEFT_BR
FLOOR_LOCATION_FINISH:
	.byte CHR_HEART_TOP, CHR_HEART_TOP, CHR_HEART_BL, CHR_HEART_BR
FLOOR_LOCATION_TELEPORT:
	.byte CHR_CORNER_TL, CHR_CORNER_TR, CHR_CORNER_BL, CHR_CORNER_BR

FLOOR_LOCATION_BLOCK:
	.byte CHR_WALL, CHR_WALL, CHR_WALL, CHR_WALL
FLOOR_LOCATION_GAP:
	.byte CHR_GAP, CHR_GAP, CHR_GAP, CHR_GAP
FLOOR_LOCATION_BADDY:
	.byte CHR_BADDY_TL, CHR_BADDY_TR, CHR_BADDY_BL, CHR_BADDY_BR
FLOOR_LOCATION_PLAYER:
	.byte CHR_PLAYER_TL, CHR_PLAYER_TR, CHR_PLAYER_BL, CHR_PLAYER_BR

;Not obliged to be in range 0..16
FLOOR_LOCATION_SWITCH_RIGHT:
	.byte CHR_GAP, CHR_SWITCH_RIGHT_TR, CHR_SWITCH_RIGHT_BL, CHR_SWITCH_RIGHT_BR

.macro	multicolourData colour
	.byte $8 | colour
.endmacro

.macro	hiRezData colour
	.byte colour
.endmacro

FLOOR_COLOUR_DATA:
	multicolourData WALL_COLOUR		;Corner
	multicolourData WALL_COLOUR		;Corner
	multicolourData WALL_COLOUR		;Corner
	multicolourData WALL_COLOUR		;Corner
	multicolourData TWIRL_COLOUR		;Clockwise twirl
	multicolourData TWIRL_COLOUR		;Anticlockwise twirl
	multicolourData KEY_COLOUR		;Key
	multicolourData SWITCH_COLOUR		;Switch left
	multicolourData HEART_COLOUR		;Heart
	multicolourData TELEPORT_COLOUR		;Teleport

	hiRezData WALL_COLOUR			;Block
	;These need entries only to ensure that the colour is multicolour
	multicolourData	COLOUR_WHITE		;Gap
	multicolourData COLOUR_WHITE		;Baddy
	;Ensure the player colour is the same as the teleport
	multicolourData TELEPORT_COLOUR		;Player
	multicolourData SWITCH_COLOUR		;Switch right

WALL_COLOUR_LUT = WALL_COLOUR_DATA - CHR_GAP
WALL_COLOUR_DATA:
	multicolourData COLOUR_WHITE	;Gap
	hiRezData COLOUR_RED	;Door 
	multicolourData COLOUR_WHITE	;Barrier_open
	hiRezData COLOUR_WHITE		;Barrier_closed
	hiRezData COLOUR_WHITE		;Barrier_electrified
	hiRezData WALL_COLOUR 		;Wall
	hiRezData WALL_COLOUR		;Spike
	hiRezData WALL_COLOUR		;Spike
	hiRezData WALL_COLOUR		;Spike
	hiRezData WALL_COLOUR		;Spike

UD_MAP:
	.byte CHR_GAP, CHR_SPIKE_UP, CHR_SPIKE_DOWN, CHR_WALL
LR_MAP:
	.byte CHR_GAP, CHR_SPIKE_LEFT, CHR_SPIKE_RIGHT, CHR_WALL


HEART_SELECTOR_OFFSET_LUT = HEART_SELECTOR_OFFSET_LOCATION - PLAYER_FAST_RATE
HEART_SELECTOR_OFFSET_LOCATION:
	.byte 9
	;Note: This table expects a 0 in the following location

; Lookup tables for the low byte of the start of each row.
SCREEN_ROW_LUT_LOW:
	.byte .LOBYTE(NUM_VIDEO_COLUMNS *  0)
	.byte .LOBYTE(NUM_VIDEO_COLUMNS *  1)
	.byte .LOBYTE(NUM_VIDEO_COLUMNS *  2)
	.byte .LOBYTE(NUM_VIDEO_COLUMNS *  3)
	.byte .LOBYTE(NUM_VIDEO_COLUMNS *  4)
	.byte .LOBYTE(NUM_VIDEO_COLUMNS *  5)
	.byte .LOBYTE(NUM_VIDEO_COLUMNS *  6)
	.byte .LOBYTE(NUM_VIDEO_COLUMNS *  7)
	.byte .LOBYTE(NUM_VIDEO_COLUMNS *  8)
	.byte .LOBYTE(NUM_VIDEO_COLUMNS *  9)
	.byte .LOBYTE(NUM_VIDEO_COLUMNS * 10)
	.byte .LOBYTE(NUM_VIDEO_COLUMNS * 11)
	.byte .LOBYTE(NUM_VIDEO_COLUMNS * 12)
	.byte .LOBYTE(NUM_VIDEO_COLUMNS * 13)
	.byte .LOBYTE(NUM_VIDEO_COLUMNS * 14)
	.byte .LOBYTE(NUM_VIDEO_COLUMNS * 15)
	.byte .LOBYTE(NUM_VIDEO_COLUMNS * 16)
	.byte .LOBYTE(NUM_VIDEO_COLUMNS * 17)
	.byte .LOBYTE(NUM_VIDEO_COLUMNS * 18)
	.byte .LOBYTE(NUM_VIDEO_COLUMNS * 19)
	.byte .LOBYTE(NUM_VIDEO_COLUMNS * 20)

HOLE_OFFSET_LUT:
	.byte 4,5
	.byte 1,2
	.byte 0,3
	.byte 1,4
	.byte 2,5

SPEED_SWAP_LUT = SPEED_SWAP_LOCATION - PLAYER_FAST_RATE
SPEED_SWAP_LOCATION:
	.assert PLAYER_SLOW_RATE = PLAYER_FAST_RATE + 1, error, "Adjust SPEED_SWAP_LUT to new rates"
	.byte PLAYER_SLOW_RATE
	.byte PLAYER_FAST_RATE

BARRIER_SWITCH_LUT = BARRIER_SWITCH_BASE_LUT - CHR_BARRIER_OPEN
BARRIER_SWITCH_BASE_LUT:
	.byte CHR_BARRIER_OPEN
	.byte CHR_BARRIER_CLOSED
	.byte CHR_BARRIER_ELECTRIFIED
	.byte CHR_BARRIER_OPEN

	;Table of settings for the VIC chip
VIC_SETTINGS:
	;VIC_IMODE_AND_HORIZONTAL_ORIGIN
	.byte PAL_HORIZONTAL_ORIGIN
	;VIC_VERTICAL_ORIGIN
	.byte PAL_VERTICAL_ORIGIN
	;VIC_SCREEN_LOC_AND_NUM_COLUMNS (Screen at $1000)
	.byte $00 + NUM_VIDEO_COLUMNS
	;VIC_RASTER_NUM_ROWS_AND_CHAR_SIZE
	.byte $80 + (NUM_VIDEO_ROWS * 2)
	;VIC_RASTER_HIGH_BITS - Readonly, but seems okay with writing
	.byte 0
	;VIC_SCREEN_AND_CHAR_LOC
	.byte SCREEN_AND_CHAR_LOC_TEXT
	;Light pen and paddle
	.byte 0,0,0,0
	;Sound registers
	.byte SOUND_NOTE_OFF
	.byte SOUND_NOTE_OFF
	.byte SOUND_NOTE_OFF
	.byte SOUND_NOTE_OFF
	;VIC_AUX_COLOUR_AND_LOUDNESS
	.byte (BADDY_COLOUR << 4) + $F
	;VIC_AUX_COLOUR_AND_LOUDNESS
	.byte DONT_VALUE

	;Initialize zero page variables
	;To save space, we don't distinguish between once ever and once per game
	;settings.
INITIALIZATION_SETTINGS:
	;var::player_callback_ptr
	.word playerCallback
	;var::player_back_chars_ptr
	.word PLAYER_CHAR_BUFFER
	;var::player_source_ptr
	.word CHR_LOCATION_PLAYER
	;var::player_image_ptr
	.word SPRITE_PLAYER_BUFFER
	;var::player_start_chr
	.byte CHR_PLAYER_BUFF
	;var::player_source_offset
	.byte (CHR_LOCATION_PLAYER - CHR_LOCATION_SPRITE_SOURCE)
	;Corresponding to the active section of baddy
	;We put 8 in the coordinates to placate resetSprites.
	.byte 8,8,0,0,0
	;var::baddy_callback_ptr
	.word baddyCallback
	;var::baddy_back_chars_ptr
	.word BADDY_CHAR_BUFFER
	;var::baddy_source_ptr
	.word CHR_LOCATION_BADDY
	;var::baddy_image_ptr
	.word SPRITE_BADDY_BUFFER
	;var::baddy_start_chr
	.byte CHR_BADDY_BUFF
	;var::baddy_source_offset
	.byte (CHR_LOCATION_BADDY - CHR_LOCATION_SPRITE_SOURCE) 
	;var::num_level
	.byte 0
	;var::cheat
	.byte 0
	;var::num_lives
	.byte NUM_LIVES
	;var::leveldata_ptr
	.word LEVEL_DATA
INITIALIZATION_SETTINGS_END:

;Mapping from (character positions - 1) to (floor positions * 2)
;We will never query at 0, so we can drop the initial byte
;Note: The last four entries are needed to handle the case when the player
;dies in the first or last column/row.
DIV_3_LUT:
	.byte (0 << 1) + 1, (0 << 1) + 0, (0 << 1) + 1
	.byte (1 << 1) + 1, (1 << 1) + 0, (1 << 1) + 1
	.byte (2 << 1) + 1, (2 << 1) + 0, (2 << 1) + 1
	.byte (3 << 1) + 1, (3 << 1) + 0, (3 << 1) + 1
	.byte (4 << 1) + 1, (4 << 1) + 0, (4 << 1) + 1
	.byte (5 << 1) + 1, (5 << 1) + 0, (5 << 1) + 1
	.byte (6 << 1) + 1, (6 << 1) + 0, (6 << 1) + 1

SPRITE_ROTATE_VERT_LUT:
	.byte (3 * 8) + 7, (2 * 8) + 7, (5 * 8) + 7, $FF	;2nd column up
	.byte 1 * 8, 0 * 8, 4 * 8, $FF				;1st column down
	.byte 2 * 8, 3 * 8, 5 * 8, $FF				;2nd column down
	.byte (4 * 8) + 7, (0 * 8) + 7, (1 * 8) + 7		;1st column up

;We will never query at 0, so we can drop the initial byte
MOD_3_LUT = MOD_3_LUT_LOCATION - 1
MOD_3_LUT_LOCATION:
	.byte 0,1,2
	.byte 0,1,2
	.byte 0,1,2
	.byte 0,1,2
	.byte 0,1,2
	;overlaps with the following table.
	;.byte 0

LIFE_POS_LUT:
	.byte 0, NUM_VIDEO_COLUMNS - 1, 1, NUM_VIDEO_COLUMNS - 2

;The offsets of centred tile.
FLOOR_OFFSET_LUT:
	.byte NUM_VIDEO_COLUMNS + 1
	.byte NUM_VIDEO_COLUMNS + 2
	.byte (2 * NUM_VIDEO_COLUMNS) + 1
	.byte (2 * NUM_VIDEO_COLUMNS) + 2

;The offset of neighbour pairs.
NEIGHBOUR_OFFSET_LUT:
	.byte 1,2							;Up
	.byte NUM_VIDEO_COLUMNS + 3, (2 * NUM_VIDEO_COLUMNS) + 3	;Right
	.byte (3 * NUM_VIDEO_COLUMNS) + 1, (3 * NUM_VIDEO_COLUMNS) + 2	;Down
	.byte NUM_VIDEO_COLUMNS, 2 * NUM_VIDEO_COLUMNS			;Left

EYE_OFFSET_LUT:
	.byte 23, 22, 21, 20, 15, 14, 13, 12

EYE_CHR_LUT:

EYE_TL_RIGHT:
	.byte %00010101
	.byte %01010100
	.byte %01010100
	.byte %01010101

EYE_TR_RIGHT:
	.byte %01010100
	.byte %01010001
	.byte %01010001
	.byte %01010101

EYE_TL_DOWN:
	.byte %00010101
	.byte %01010101
	.byte %01010001
	.byte %01010001

EYE_TR_DOWN:
	.byte %01010100
	.byte %01010101
	.byte %01000101
	.byte %01000101

EYE_TL_LEFT:
	.byte %00010101
	.byte %01000101
	.byte %01000101
	.byte %01010101

EYE_TR_LEFT:
	.byte %01010100
	.byte %00010101
	.byte %00010101
	.byte %01010101
EYE_TL_UP:
	.byte %00010001
	.byte %01010001
	.byte %01010101
	.byte %01010101

EYE_TR_UP:
	.byte %01000100
	.byte %01000101
	.byte %01010101
	.byte %01010101

;*****************************************************************************
; CHARACTER DATA
;*****************************************************************************

	.segment "MYCHAR"

	;Exomizer buffer
	.byte 0,0

CHR_LOCATION_START:
CHR_LOCATION_SPRITE_SOURCE:

CHR_LOCATION_BADDY:
CHR_LOCATION_BADDY_SPARE_L:
	.byte $00, $00, $00, $00, $00, $00, $00, $00

CHR_LOCATION_BADDY_TL:
	.byte %00001111
	.byte %00111111
	.byte %11000011
	.byte %11000011
	.byte %11000011
	.byte %11111100
	.byte %00111100
	.byte %00111100

CHR_LOCATION_BADDY_TR:
	.byte %11110000
	.byte %11111100
	.byte %11000011
	.byte %11000011
	.byte %11000011
	.byte %00111111
	.byte %00111100
	.byte %00111100

CHR_LOCATION_BADDY_SPARE_R:
	.byte $00, $00, $00, $00, $00, $00, $00, $00

CHR_LOCATION_BADDY_BL:
	.byte %00111111
	.byte %00111111
	.byte %00110011
	.byte %00001100
	.byte %00111111
	.byte %00111111
	.byte %00111111
	.byte %00001111

CHR_LOCATION_BADDY_BR:
	.byte %11111100
	.byte %11111100
	.byte %00110000
	.byte %11001100
	.byte %11111100
	.byte %11111100
	.byte %11111100
	.byte %11110000

CHR_LOCATION_PLAYER:
CHR_LOCATION_PLAYER_SPARE_T:
	.byte $00, $00, $00, $00, $00, $00, $00, $00

CHR_LOCATION_PLAYER_TL:
	.byte %00000001
	.byte %00000101
	.byte %00010101
	.byte %00010101
	.byte %00010101
	.byte %01010101
	.byte %01010101
	.byte %01010101

CHR_LOCATION_PLAYER_TR:
	.byte %01000000
	.byte %01010000
	.byte %01010100
	.byte %01010100
	.byte %01010100
	.byte %01010101
	.byte %01010101
	.byte %01010101

CHR_LOCATION_PLAYER_SPARE_B:
	.byte $00, $00, $00, $00, $00, $00, $00, $00

CHR_LOCATION_PLAYER_BL:
	.byte %01010101
	.byte %01010101
	.byte %01010101
	.byte %00010001
	.byte %00010100
	.byte %00010101
	.byte %00000101
	.byte %00000001

CHR_LOCATION_PLAYER_BR:
	.byte %01010101
	.byte %01010101
	.byte %01010101
	.byte %01000100
	.byte %00010100
	.byte %01010100
	.byte %01010000
	.byte %01000000

CHR_LOCATION_CORNER_TL:
	.byte %10101000
	.byte %10100000
	.byte %10000000
	.byte %10000000
	.byte %10000000
	.byte %00000000
	.byte %00000000
	.byte %00000000

CHR_LOCATION_CORNER_TR:
	.byte %00101010
	.byte %00001010
	.byte %00000010
	.byte %00000010
	.byte %00000010
	.byte %00000000
	.byte %00000000
	.byte %00000000

CHR_LOCATION_CORNER_BL:
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %10000000
	.byte %10000000
	.byte %10000000
	.byte %10100000
	.byte %10101000

CHR_LOCATION_CORNER_BR:
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000010
	.byte %00000010
	.byte %00000010
	.byte %00001010
	.byte %00101010

CHR_LOCATION_CLOCKWISE_TL:
	.byte %00000010
	.byte %00001010
CHR_LOCATION_ANIMATION_START:
	.byte %00101000
	.byte %00100000
	.byte %00100000
	.byte %10100000
	.byte %10000000
	.byte %10000000

CHR_LOCATION_CLOCKWISE_TR:
	.byte %10000000
	.byte %10100000
	.byte %00101000
	.byte %00101000
	.byte %10001000
	.byte %10001010
	.byte %10000010
	.byte %10000010

CHR_LOCATION_CLOCKWISE_BR:
	.byte %00000010
	.byte %00000010
	.byte %00001010
	.byte %00001000
	.byte %00001000
	.byte %00101000
	.byte %10100000
	.byte %10000000

CHR_LOCATION_CLOCKWISE_BL:
	.byte %10000010
	.byte %10000010
	.byte %10100010
	.byte %00100010
	.byte %00101000
	.byte %00101000
	.byte %00001010
	.byte %00000010

CHR_LOCATION_ANTICLOCKWISE_TL:
	.byte %00000010
	.byte %00001010
	.byte %00101000
	.byte %00100000
	.byte %00100000
	.byte %10100000
	.byte %10000000
	.byte %10000010

CHR_LOCATION_ANTICLOCKWISE_TR:
	.byte %10000000
	.byte %10100000
	.byte %00101000
	.byte %00001000
	.byte %00001000
	.byte %00101010
	.byte %10101010
	.byte %10100010

CHR_LOCATION_ANTICLOCKWISE_BR:
	.byte %10000010
	.byte %00000010
	.byte %00001010
	.byte %00001000
	.byte %00001000
	.byte %00101000
	.byte %10100000
	.byte %10000000

CHR_LOCATION_ANTICLOCKWISE_BL:
	.byte %10001010
	.byte %10101010
	.byte %10101000
	.byte %00100000
	.byte %00100000
	.byte %00101000
	.byte %00001010
	.byte %00000010

CHR_LOCATION_GAP:
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000

CHR_LOCATION_DOOR:
	.byte %11100011
	.byte %11011101
	.byte %11100011
	.byte %11110111
	.byte %11110111
	.byte %11000111
	.byte %11100111
	.byte %11000111

CHR_LOCATION_BARRIER_OPEN:
	.byte %10000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000010

CHR_LOCATION_BARRIER_CLOSED:
	.byte %10011001
	.byte %11001100
	.byte %01100110
	.byte %00110011
	.byte %10011001
	.byte %00110011
	.byte %01100110
	.byte %11001100

CHR_LOCATION_BARRIER_ELECTRIFIED:
	.byte %10101001
	.byte %10010100
	.byte %00111010
	.byte %01101001
	.byte %11001001
	.byte %00101010
	.byte %10101110
	.byte %01010010

CHR_LOCATION_WALL:
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111

CHR_LOCATION_SPIKE_LEFT:
	.byte %00011111
	.byte %00001111
	.byte %00011111
	.byte %11111111
	.byte %01111111
	.byte %00011111
	.byte %00001111
	.byte %00011111

CHR_LOCATION_SPIKE_UP:
	.byte %00001000
	.byte %00011000
	.byte %00011000
	.byte %10111101
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111

CHR_LOCATION_SPIKE_RIGHT:
	.byte %11111000
	.byte %11110000
	.byte %11111000
	.byte %11111110
	.byte %11111111
	.byte %11111000
	.byte %11110000
	.byte %11111000

CHR_LOCATION_SPIKE_DOWN:
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %10111101
	.byte %00011000
	.byte %00011000
	.byte %00001000

CHR_LOCATION_KEY_TL:
	.byte %00000000
	.byte %00000010
	.byte %00001010
	.byte %00001000
	.byte %00001010
	.byte %00000010
	.byte %00000000
	.byte %00000000

CHR_LOCATION_KEY_TR:
	.byte %00000000
	.byte %10100000
	.byte %00101000
	.byte %00001000
	.byte %00101000
	.byte %10100000
	.byte %10000000
	.byte %10000000

CHR_LOCATION_KEY_BL:
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00001010
	.byte %00000010
	.byte %00001010
	.byte %00000010
	.byte %00001010

CHR_LOCATION_KEY_BR:
	.byte %10000000
	.byte %10000000
	.byte %10000000
	.byte %10000000
	.byte %10000000
	.byte %10000000
	.byte %10000000
	.byte %10000000

CHR_LOCATION_SWITCH_LEFT_TL:
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00100000
	.byte %00100000
	.byte %00100000

CHR_LOCATION_SWITCH_LEFT_BL:
	.byte %00001000
	.byte %00001000
	.byte %00001000
	.byte %00000010
	.byte %00000010
	.byte %00000010
	.byte %00001010
	.byte %00101010

CHR_LOCATION_SWITCH_LEFT_BR:
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %10000000
	.byte %10100000
	.byte %10101000

CHR_LOCATION_SWITCH_RIGHT_TR:
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00001000
	.byte %00001000
	.byte %00001000

CHR_LOCATION_SWITCH_RIGHT_BL:
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000010
	.byte %00001010
	.byte %00101010

CHR_LOCATION_SWITCH_RIGHT_BR:
	.byte %00100000
	.byte %00100000
	.byte %00100000
	.byte %10000000
	.byte %10000000
	.byte %10000000
	.byte %10100000
	.byte %10101000

CHR_LOCATION_HEART_TOP:
	.byte %00101000
	.byte %00101000
	.byte %10101010
	.byte %10101010
	.byte %10101010
	.byte %10101010
	.byte %10101010
	.byte %10101010

CHR_LOCATION_HEART_BL:
	.byte %00101010
	.byte %00101010
	.byte %00101010
	.byte %00001010
	.byte %00001010
	.byte %00001010
	.byte %00000010
	.byte %00000010

CHR_LOCATION_HEART_BR:
	.byte %10101000
	.byte %10101000
	.byte %10101000
	.byte %10100000
	.byte %10100000
	.byte %10100000
	.byte %10000000
	.byte %10000000

CHR_LOCATION_KEY_SYMBOL:
	.byte %00011100
	.byte %00100010
	.byte %00011100
	.byte %00001000
	.byte %00001000
	.byte %00111000
	.byte %00011000
	.byte %00111000

CHR_LOCATION_LIFE_SYMBOL_LEFT:
	.byte %00111100
	.byte %01111110
	.byte %11101101
	.byte %11111111
	.byte %11111111
	.byte %11011011
	.byte %01100110
	.byte %00111100

CHR_LOCATION_LIFE_SYMBOL_RIGHT:
	.byte %00111100
	.byte %01111110
	.byte %10110111
	.byte %11111111
	.byte %11111111
	.byte %11011011
	.byte %01100110
	.byte %00111100

CHR_LOCATION_TIMEBAR_BODY:
	.byte %00000000
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %00000000

CHR_LOCATION_TIMEBAR_EMPTY:
	.byte %00000000
	.byte %11111111
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %11111111
	.byte %00000000

CHR_LOCATION_TIMEBAR_TOP:
	.byte %00000000
	.byte %11111111
	.byte %00000001
	.byte %00000001
	.byte %00000001
	.byte %00000001
	.byte %11111111
	.byte %00000000

CHR_LOCATION_HEART_HOLLOW:
	.byte %00000000
	.byte %00110110
	.byte %01001001
	.byte %01000001
	.byte %01000001
	.byte %00100010
	.byte %00010100
	.byte %00001000

CHR_LOCATION_HEART_FULL:
	.byte %00000000
	.byte %00110110
	.byte %01111111
	.byte %01111111
	.byte %01111111
	.byte %00111110
	.byte %00011100
	.byte %00001000

CHR_LOCATION_HEART_BROKEN:
	.byte %00000000
	.byte %00100010
	.byte %01110111
	.byte %01110111
	.byte %01110111
	.byte %00101110
	.byte %00001100
	.byte %00001000

CHR_LOCATION_TIMEBAR_TIP:
	;This is refreshed by code, so we let it overwrite some
	;initialization code.

CHR_LOCATION_END:

;*****************************************************************************
; BUFFERS
;*****************************************************************************

	.segment "BACKBUFFER"
BACK_BUFFERS:
BADDY_CHAR_BUFFER = BACK_BUFFERS + 0
PLAYER_CHAR_BUFFER = BACK_BUFFERS + 6

	.segment "SPRITEBUFFER"
SPRITE_BUFFER_START:
SPRITE_BADDY_BUFFER = SPRITE_BUFFER_START + (0 * 8)
SPRITE_PLAYER_BUFFER = SPRITE_BUFFER_START + (6 * 8)

;*****************************************************************************
; SCREEN
;*****************************************************************************

	.segment "SCREEN"
SCREEN_LOCATION:

