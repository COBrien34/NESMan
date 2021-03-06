    .inesprg 1
    .ineschr 1
    .inesmap 0
    .inesmir 1



PPUCTRL     = $2000
PPUMASK     = $2001
PPUSTATUS   = $2002
OAMADDR     = $2003
OAMDATA     = $2004
PPUSCROLL   = $2005
PPUADDR     = $2006
PPUDATA     = $2007
OAMDMA      = $4014
JOYPAD1     = $4016
JOYPAD2     = $4017

BUTTON_A        = %10000000     ; Defining Controls |
BUTTON_B        = %01000000                         
BUTTON_SELECT   = %00100000                         
BUTTON_START    = %00010000
BUTTON_UP       = %00001000
BUTTON_DOWN     = %00000100
BUTTON_LEFT     = %00000010
BUTTON_RIGHT    = %00000001

ENEMY_SQUAD_WIDTH     = 4
ENEMY_SQUAD_HEIGHT    = 4
NUM_ENEMIES           = 1


ENEMY_HITBOX_WIDTH      = 8 ; Hit box width
ENEMY_HITBOX_HEIGHT     = 8 ; Hitbox height
BULLET_HIT_BOX_X        = 2 ; Relative to sprite top left corner
BULLET_HIT_BOX_Y        = 2
BULLET_HITBOX_WIDTH     = 2 ; Hit box width
BULLET_HITBOX_HEIGHT    = 6 ; Hit box height

    .rsset $0000
joypad1_state       .rs 1
nametable_address   .rs 2
bullet_active       .rs 1
enemy_info          .rs 4 * NUM_ENEMIES
player_speed        .rs 2   ; in subpixels per frame -- 16 bits
player_position_sub .rs 1   ; in subpixels
enemyY_speed        .rs 2
enemyY_position_sub .rs 1   ; in subpixels
enemyX_speed        .rs 2   
enemyX_position_sub .rs 1   ; in subpixels
touching_ground     .rs 1   ; Ground Check
    
    .rsset $0200
sprite_player   .rs 4       ; Defining Player sprites
sprite_player_1 .rs 4       ; Defining Player sprites
sprite_player_2 .rs 4       ; Defining Player sprites
sprite_player_3 .rs 4       ; Defining Player sprites

sprite_bullet   .rs 4       ; Defining Bullet Sprite
sprite_enemy    .rs 4 * NUM_ENEMIES

    .rsset $0000
SPRITE_Y        .rs 1
SPRITE_TILE     .rs 1
SPRITE_ATTRIB   .rs 1
SPRITE_X        .rs 1

ENEMY_X_SPEED    = 128

GRAVITY          =  10  ; in subpixels/frame*2
JUMP_SPEED       = -(1 * 256 + 128) ; in subpixels/frame

    .rsset $0000
ENEMY_SPEED     .rs 1
ENEMY_ALIVE     .rs 1

    .bank 0
    .org $C000


RESET:
    SEI         ; ignore IRQs
    CLD         ; disable decimal mode
    LDX #$40
    STX $4017   ;disable APU frame
    LDX #$ff
    TXS         ; Set up stack
    INX         ; now X = 0
    STX PPUCTRL   ; disable NMI
    STX PPUMASK   ; siable rendering
    STX $4010   ; disable DMC IRQs

    ; Optional (omitted):
    ; Set up mapper and jmp to further init code here.

    ; If the user presses Reset during vblank, the PPU may reset
    ; with the vblank flag still true.  This has about a 1 in 13
    ; chance of happening on NTSC or 2 in 9 on PAL.  Clear the
    ; flag now so the vblankwait1 loop sees an actual vblank.
    BIT PPUSTATUS

    ; First of two waits for vertical blank to make sure that the
    ; PPU has stabilized
vblankwait1:  
    BIT PPUSTATUS
    BPL vblankwait1

    ; We now have about 30,000 cycles to burn before the PPU stabilizes.
    ; One thing we can do with this time is put RAM in a known state.
    ; Here we fill it with $00, which matches what (say) a C compiler
    ; expects for BSS.  Conveniently, X is still 0.
    TXA
clrmem:
    LDA #0
    STA $000,x
    STA $100,x
    STA $300,x
    STA $400,x
    STA $500,x
    STA $600,x
    STA $700,x  ; Remove this if you're storing reset-persistent data

    ; We skipped $200,x on purpose.  Usually, RAM page 2 is used for the
    ; display list to be copied to OAM.  OAM needs to be initialized to
    ; $EF-$FF, not 0, or you'll get a bunch of garbage sprites at (0, 0).

    LDA #$FF
    STA $200,x

    INX
    BNE clrmem

    ; Other things you can do between vblank waits are set up audio
    ; or set up other mapper registers.
   
vblankwait2:
    BIT PPUSTATUS
    BPL vblankwait2

    ; End of initialisation code

    JSR InitilaiseGame

    LDA #%10000000      ; Enable NMI
    STA PPUCTRL

    LDA #%00011000      ; Enable sprites and background
    STA PPUMASK

    LDA #0
    STA PPUSCROLL       ; set x scroll
    STA PPUSCROLL       ; set y scroll

      ; Enter an infinite loop
forever:
    JMP forever
; ----------------------------------------------------------------------------------------------------------

InitilaiseGame: ; Begin Subroutine

    ; Reset the PPU high/low latch
    LDA $2002

    ; Write address $3F00 (Background palette) to the PPU
    LDA #$3F
    STA PPUADDR
    LDA #$00
    STA PPUADDR

    ; Write the background palette
    LDA #$0F
    STA PPUDATA
    LDA #$3E
    STA PPUDATA
    LDA #$2D
    STA PPUDATA
    LDA #$10
    STA PPUDATA

    ; Write address $3F10 (Sprite Palette) to the PPU
    LDA #$3F
    STA PPUADDR
    LDA #$10
    STA PPUADDR

    ; Write the background colour
    LDA #$0F
    STA PPUDATA

    
    ; Write the palette colours
    LDA #$15
    STA PPUDATA
    LDA #$11
    STA PPUDATA
    LDA #$30
    STA PPUDATA

    ; Write sprite data for sprite 0
    LDA #199           ;Y position
    STA sprite_player + SPRITE_Y
    LDA #0              ; Tile number
    STA sprite_player + SPRITE_TILE
    LDA #0              ; Attributes
    STA sprite_player + SPRITE_ATTRIB
    LDA #128            ; X position
    STA sprite_player + SPRITE_X

    ; Write sprite data for sprite 1
    LDA #199            ;Y position
    STA sprite_player_1 + SPRITE_Y
    LDA #1             ; Tile number
    STA sprite_player_1 + SPRITE_TILE
    LDA #0              ; Attributes
    STA sprite_player_1 + SPRITE_ATTRIB
    LDA #136            ; X position
    STA sprite_player_1 + SPRITE_X

    ; Write sprite data for sprite 2
    LDA #207            ;Y position
    STA sprite_player_2 + SPRITE_Y
    LDA #2             ; Tile number
    STA sprite_player_2 + SPRITE_TILE
    LDA #0              ; Attributes
    STA sprite_player_2 + SPRITE_ATTRIB
    LDA #126            ; X position
    STA sprite_player_2 + SPRITE_X

    ; Write sprite data for sprite 3
    LDA #207            ;Y position
    STA sprite_player_3 + SPRITE_Y
    LDA #3            ; Tile number
    STA sprite_player_3 + SPRITE_TILE
    LDA #0              ; Attributes
    STA sprite_player_3 + SPRITE_ATTRIB
    LDA #134            ; X position
    STA sprite_player_3 + SPRITE_X

    ; Write sprite data for sprite 1 (enemy)
    LDA #194    ; Y pos
    STA sprite_enemy + SPRITE_Y
    LDA #8      ; Tile No.
    STA sprite_enemy + SPRITE_TILE
    LDA #1   ; Attributes 
    STA sprite_enemy + SPRITE_ATTRIB
    LDA #210   ; X pos
    STA sprite_enemy + SPRITE_X
    STA enemy_info + ENEMY_ALIVE, x

    ; Load nametable data
    LDA #$20            ; Write address $2000 to PPUADDR register
    STA PPUADDR
    LDA #$00
    STA PPUADDR

    ; Creates and Loads nametable
    LDA #LOW(NametableData)
    STA nametable_address
    LDA #HIGH(NametableData)
    STA nametable_address + 1
LoadNametable_OuterLoop:
    LDY #0
LoadNametable_InnerLoop:
    LDA [nametable_address], Y
    BEQ LoadNametable_End
    STA PPUDATA
    INY
    BNE LoadNametable_InnerLoop
    INC nametable_address + 1
    JMP LoadNametable_OuterLoop
LoadNametable_End:

    ; Load attribute data
    LDA #$23            ; Write address $2000 to PPUADDR register
    STA PPUADDR
    LDA #$C0
    STA PPUADDR

    LDA #0
    LDX #64
LoadAttributes_Loop:
    STA PPUDATA
    DEX 
    BNE LoadAttributes_Loop

    RTS ; End subroutine

; ----------------------------------------------------------------------------------------------------------

; NMI is called on every frame
NMI:
    ;Initilaise controller 1
    LDA #1
    STA JOYPAD1
    LDA #0
    STA JOYPAD1

    ; Read joypad state
    LDX #0
    STX joypad1_state
ReadController:
    LDA JOYPAD1
    LSR A
    ROL joypad1_state
    INX
    CPX #8
    BNE ReadController

    ; React to Right button
    LDA joypad1_state
    AND #BUTTON_RIGHT
    BEQ ReadRight_Done 
    LDA sprite_player + SPRITE_X
    CLC 
    ADC #1
    STA sprite_player + SPRITE_X
    LDA sprite_player_1 + SPRITE_X
    CLC
    ADC #1
    STA sprite_player_1 + SPRITE_X
    LDA sprite_player_2 + SPRITE_X
    CLC
    ADC #1
    STA sprite_player_2 + SPRITE_X
    LDA sprite_player_3 + SPRITE_X
    CLC
    ADC #1
    STA sprite_player_3 + SPRITE_X
ReadRight_Done: 

 ; React to Left button
    LDA joypad1_state
    AND #BUTTON_LEFT
    BEQ ReadLeft_Done 
    LDA sprite_player + SPRITE_X
    SEC 
    SBC #1
    STA sprite_player + SPRITE_X
    LDA sprite_player_1 + SPRITE_X
    SEC
    SBC #1
    STA sprite_player_1 + SPRITE_X
    LDA sprite_player_2 + SPRITE_X
    SEC
    SBC #1
    STA sprite_player_2 + SPRITE_X
    LDA sprite_player_3 + SPRITE_X
    SEC
    SBC #1
    STA sprite_player_3 + SPRITE_X
ReadLeft_Done: 

    ; React to A button
    LDA joypad1_state
    AND #BUTTON_A
    BEQ ReadA_Done
    ; Set player speed
    LDA #LOW(JUMP_SPEED)
    STA player_speed
    LDA #HIGH(JUMP_SPEED)
    STA player_speed + 1

ReadA_Done:

    ; Update player sprite
    ; First, update speed
    LDA player_speed     ; Low 8 bits
    CLC
    ADC #LOW(GRAVITY)
    STA player_speed
    LDA player_speed + 1 ; High 8 bits
    ADC #HIGH(GRAVITY)   ; NB: *don't* clear the carry flag
    STA player_speed + 1

    ; ; Second, update position
    LDA player_position_sub ; Low 8 bits
    CLC
    ADC player_speed
    STA player_position_sub
    LDA sprite_player + SPRITE_Y ; High 8 bits
    ADC player_speed + 1         ; NB: *don't* clear the carry flag
    STA sprite_player + SPRITE_Y


GroundCheck: ; Checks for the ground so the player doesnt fall through the map
    LDA sprite_player + SPRITE_Y
    ADC #15
    CMP #214
    BCC NotTouchingGround
    LDA #214
    SBC #15
    STA sprite_player + SPRITE_Y
    LDA #0
    STA player_speed
    STA player_speed + 1

NotTouchingGround:

AlignPlayerSprites: ; Align sprites so they stay together whilst jumping
    LDA sprite_player + SPRITE_Y
    STA sprite_player_1 + SPRITE_Y
    ADC #07
    STA sprite_player_2 + SPRITE_Y
    STA sprite_player_3 + SPRITE_Y

    ; React to B button
    LDA joypad1_state
    AND #BUTTON_B
    BEQ ReadB_Done
    
    ; Spawn a Bullet if one is not active
    LDA bullet_active
    BNE ReadB_Done
    ; No bullet active, so spawn one
    LDA #1
    STA bullet_active
    LDA sprite_player + SPRITE_Y            ;Y position
    STA sprite_bullet + SPRITE_Y
    LDA #5              ; Tile number
    STA sprite_bullet + SPRITE_TILE
    LDA #0              ; Attributes
    STA sprite_bullet + SPRITE_ATTRIB
    LDA sprite_player + SPRITE_X            ; X position
    STA sprite_bullet + SPRITE_X
ReadB_Done:

    ; Update the bullet
    LDA bullet_active
    BEQ UpdateBullet_Done
    LDA sprite_bullet + SPRITE_X
    CLC
    ADC #2
    STA sprite_bullet + SPRITE_X
    BCC UpdateBullet_Done
    ; If carry flag is clear, bullet has left the top of the screen -- destroy it
    LDA #0
    STA bullet_active
UpdateBullet_Done:

    ; Update enemies

MoveEnemyLeft:
    ; Update speed
    LDA enemyX_position_sub
    SEC
    SBC #LOW(ENEMY_X_SPEED)
    STA enemyX_position_sub
    LDA sprite_enemy+SPRITE_X
    SBC #HIGH(ENEMY_X_SPEED)
    STA sprite_enemy+SPRITE_X

    LDX #(NUM_ENEMIES-1)*4
UpdateEnemies_Loop:
    ; Check if enemy is alive
    LDA enemy_info + ENEMY_ALIVE, x
    BNE UpdateEnemies_Start
    JMP UpdateEnemies_Next
UpdateEnemies_Start:
    LDA sprite_enemy + SPRITE_X, x
    SEC
    SBC enemy_info + ENEMY_SPEED, x
    STA sprite_enemy + SPRITE_X, x
  

                               ;              \1        \2        \3            \4            \5            \6           \7
CheckCollisionWithEnemy .macro ; parameters: object_x, object_y, object_hit_x, object_hit_y, object_hit_w, object_hit_h, no_collision_label
    ; If there is a collision, execution continues to immediately after this macro
    ; Else, jump to no_collision_label
    LDA sprite_enemy + SPRITE_X, x ; Calculate x_enemy - w_bullet
    .if \3 > 0
    SEC
    SBC \3
    .endif 
    SEC
    SBC \5 + 1                     ; Assume w2 + 8
    CMP \1                         ; Compare with x_bullet (x2)
    BCS \7                         ; Branch if x1-w2 >= x2
    CLC
    ADC \5 + 1 + ENEMY_HITBOX_WIDTH ; Calculate e_enemy + w_enemy (x1+w1), assuming w2 + 8
    CMP \1                         ; Compare with x_bullet (x2)
    BCC \7                         ; Branching if x1+w1 < x2

    LDA sprite_enemy + SPRITE_Y, x ; Calculate y_enemy - h_bullet
    .if \3 > 0
    SEC
    SBC \4
    .endif
    SEC 
    SBC \6 + 1                     ; Assume h2 + 8
    CMP \2                         ; Compare with y_bullet (y2)
    BCS \7                         ; Branch if y1-h2 >= y2
    CLC
    ADC \6 + 1 + ENEMY_HITBOX_HEIGHT ; Calculate e_enemy + w_enemy (y1+h1), assuming h2 + 8
    CMP \2                         ; Compare with y_bullet (y2)
    BCC \7                         ; Branching if y1+h1 < y2
    .endm

    ; Check collision with bullet
    CheckCollisionWithEnemy sprite_bullet + SPRITE_X, sprite_bullet + SPRITE_Y, #BULLET_HIT_BOX_X, #BULLET_HIT_BOX_Y, #BULLET_HITBOX_WIDTH, #BULLET_HITBOX_HEIGHT, UpdateEnemies_NoCollision

     ; Handle Collision
    LDA #0
    STA bullet_active              ; Destroy Bullet and Enemy once it collides
    STA enemy_info + ENEMY_ALIVE, x
    LDA #$FF 
    STA sprite_bullet + SPRITE_Y 
    STA sprite_enemy + SPRITE_Y, x
    UpdateEnemies_NoCollision:

    ; Check collision with player 
    CheckCollisionWithEnemy sprite_player + SPRITE_X, sprite_player + SPRITE_Y, #0, #0, #8, #8, UpdateEnemies_NoCollisionWithPlayer
    ; Handle collision
    JSR InitilaiseGame
    JMP UpdateEnemies_End
UpdateEnemies_NoCollisionWithPlayer:

    UpdateEnemies_Next:
    DEX
    DEX
    DEX
    DEX
    BMI UpdateEnemies_End
    JMP UpdateEnemies_Loop
UpdateEnemies_End:

    ; Copy sprite data to the PPU
    LDA #0
    STA OAMADDR
    LDA #$02
    STA OAMDMA

    RTI         ; Return from interrupt

; ----------------------------------------------------------------------------------------------------------

    NametableData: ; Level design by choosing tiles from .chr file
    .db $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $26, $04, $04, $04, $04, $04, $04, $04, $04, $04, $26, $04, $04, $04, $04, $04, $26
    .db $04, $04, $04, $04, $04, $26, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $26, $04, $04, $04, $04, $04, $04, $04, $04, $04
    .db $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $26, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $26, $04
    .db $04, $04, $04, $04, $04, $04, $04, $04, $04, $26, $04, $04, $04, $04, $04, $04, $04, $26, $04, $04, $04, $04, $04, $04, $04, $04, $04, $26, $04, $04, $04, $04
    .db $04, $04, $04, $06, $07, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $26, $04, $04, $04, $26, $04, $04, $04, $04, $04, $04, $04, $04
    .db $04, $04, $04, $16, $17, $04, $04, $04, $26, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04
    .db $04, $04, $04, $04, $04, $04, $26, $04, $04, $04, $04, $04, $26, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $26, $04, $04, $26, $04, $04, $04
    .db $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $26, $04, $04, $04, $04, $26, $04, $04, $04, $04, $04, $04, $04, $04, $04, $26
    .db $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $26, $04, $04, $04, $04, $04
    .db $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04
    .db $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04
    .db $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $46, $46, $46, $04, $04, $04, $04, $04, $04, $04
    .db $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $46, $47, $46, $04, $04, $04, $04, $04, $04, $04
    .db $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $46, $46, $46, $04, $04, $04, $04, $04, $04, $04
    .db $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $46, $46, $46, $46, $46, $46, $46, $04, $46, $47, $46, $04, $04, $04, $04, $04, $04, $04
    .db $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $46, $46, $46, $46, $46, $46, $46, $04, $46, $46, $46, $04, $46, $46, $46, $46, $46, $46
    .db $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $46, $46, $47, $47, $47, $46, $46, $04, $46, $47, $46, $04, $46, $47, $47, $46, $46, $46
    .db $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $46, $46, $46, $46, $46, $46, $46, $04, $46, $47, $46, $04, $46, $47, $47, $46, $46, $46
    .db $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $46, $46, $46, $46, $46, $46, $46, $04, $46, $47, $46, $04, $46, $46, $46, $46, $46, $46
    .db $04, $04, $04, $10, $11, $12, $13, $04, $04, $04, $04, $04, $04, $04, $46, $47, $47, $46, $47, $47, $46, $04, $46, $46, $46, $04, $46, $47, $47, $46, $46, $46
    .db $04, $04, $04, $20, $21, $22, $23, $04, $04, $04, $04, $04, $04, $04, $46, $47, $47, $46, $46, $46, $46, $04, $46, $47, $46, $04, $46, $47, $47, $46, $46, $46
    .db $04, $04, $04, $30, $31, $32, $33, $04, $04, $04, $04, $04, $04, $04, $46, $46, $46, $46, $46, $46, $46, $04, $46, $46, $46, $04, $46, $46, $46, $46, $46, $46
    .db $04, $04, $04, $30, $31, $32, $33, $04, $04, $04, $04, $04, $04, $04, $46, $47, $46, $47, $47, $47, $46, $04, $46, $47, $46, $04, $46, $46, $46, $46, $46, $46
    .db $04, $04, $04, $30, $31, $32, $33, $04, $04, $04, $04, $04, $04, $04, $46, $46, $46, $46, $46, $46, $46, $04, $46, $46, $46, $04, $46, $46, $47, $47, $46, $46
    .db $04, $04, $04, $30, $31, $32, $33, $04, $04, $04, $04, $04, $04, $04, $46, $46, $46, $47, $46, $46, $46, $04, $46, $47, $46, $04, $46, $46, $47, $47, $46, $46
    .db $04, $04, $04, $30, $31, $32, $33, $04, $04, $04, $04, $04, $04, $04, $04, $04, $45, $45, $45, $04, $04, $04, $04, $45, $04, $04, $04, $04, $45, $45, $04, $04
    .db $04, $04, $04, $30, $31, $32, $33, $04, $04, $04, $04, $04, $04, $04, $04, $04, $45, $45, $45, $04, $04, $04, $04, $45, $04, $04, $04, $45, $45, $04, $04, $04
    .db $42, $43, $43, $43, $43, $43, $43, $43, $43, $43, $43, $43, $43, $43, $43, $43, $43, $43, $43, $43, $43, $43, $43, $43, $43, $43, $43, $43, $43, $43, $43, $44
    .db $42, $45, $45, $45, $45, $45, $45, $45, $45, $45, $45, $45, $45, $45, $45, $45, $45, $45, $45, $45, $45, $45, $45, $45, $45, $45, $45, $45, $45, $45, $45, $45
    .db $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04
    .db $00 ; Null terminator

; ----------------------------------------------------------------------------------------------------------



    .bank 1
    .org $FFFA
    .dw NMI
    .dw RESET
    .dw 0



    .bank 2
    .org $0000
    .incbin "SpideyMan.chr"