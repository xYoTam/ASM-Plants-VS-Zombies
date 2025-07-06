IDEAL

; Author- Yotam Barkan

MODEL small
STACK 0E900h

macro printChar char, Color
push ax
push bx
push cx

	mov ah, 0Ah
	mov al, char
	mov bl, Color
	mov cx, 1
	int 10h
	
pop cx
pop bx
pop ax
endm printChar

SCREEN_WIDTH = 320


SHOOT_WIDTH = 12
SHOOT_HEIGHT = 12

PEA_WIDTH = 12
PEA_HEIGHT = 12

BMP_BUY_PLANTS_HEIGHT = 22
BMP_BUY_PLANTS_WIDTH = 45

BMP_ZOMB_HEIGHT = 32
BMP_ZOMB_WIDTH = 20

BMP_START_HEIGHT = 60
BMP_START_WIDTH = 60
BMP_START_LEFT = 143	; 138+5
BMP_START_RIGHT = 194  	;138+60-4
BMP_START_UP = 159		;137+22
BMP_START_DOWN = 175		;137+38


BMP_PSSF_BUY_LEFT = 7
BMP_PSSF_BUY_RIGHT = 52

BMP_PS_BUY_UP = 30
BMP_PS_BUY_DOWN = 52
BMP_SF_BUY_UP = BMP_PS_BUY_UP + 30
BMP_SF_BUY_DOWN = BMP_PS_BUY_DOWN + 30

GRASS_WIDTH = 245
GRASS_HEIGHT = 169
GRASS_X = 72
GRASS_Y = 12


;;;;GARDEN CUBES ROWS
ROW_ONE = 20
ROW_TWO = 53
ROW_THREE = 84
ROW_FOUR = 117
ROW_FIVE = 146
ROW_END = 179

;;;;GARDEN CUBES COLS
COL_ONE = 78
COL_TWO = 104
COL_THREE = 130
COL_FOUR = 156
COL_FIVE = 180
COL_SIX = 204
COL_SEVEN = 229
COL_EIGHT = 253
COL_NINE = 279
COL_END = 309

HOUSE_X_POSITION = COL_ONE - 12

END_OF_SHOOT_X = 300

PINK = 0EFh



DATASEG
	ScrLine 	db SCREEN_WIDTH dup (0)  ; One Color line read buffer

	;BMP File data
	mapName 	db 'garden.bmp' ,0
	startUp		db 'startUp.bmp' ,0
	peaBS db 'peab.bmp',0
	SunflowerBS db 'sunB.bmp', 0
	startButton db 'start.bmp', 0
	peaShooterStand db 'peash.bmp', 0
	sunFlowerStand db 'sf.bmp', 0
	bullets db 'shoot.bmp', 0
	zombie db 'zomb.bmp', 0
	win db 'win.bmp', 0
	defeat db 'L.bmp', 0
	grass db 'grass2.bmp', 0
	
	
	FileHandle	dw ?
	Header 	    db 54 dup(0)
	Palette 	db 400h dup (0)
	
	ErrorFile           db 0
	
	;this matrixes will be to print the entities who can be deleted
	zombiePixels db 640 dup(0)
	shootPixels db 144 dup(0)
	peaPixels db 625 dup(0)
	sunflowerPixels db 625 dup(0)
	startWithPink db 1 	;this will be at the start of the game to get the pixels with pink color (pink is the color to remove background
	
	
	
	BmpLeft dw ?
	BmpTop dw ?
	BmpWidth dw ?
	BmpHeight dw ?
	
	gameOver db 0
	money dw 50
	
	loopCounter dw 1
	
	isBuyPress db 0
	
	;the squares in the game
	row1 db 0, 0, 0, 0, 0, 0, 0, 0, 0
	row2 db 0, 0, 0, 0, 0, 0, 0, 0, 0
	row3 db 0, 0, 0, 0, 0, 0, 0, 0, 0
	row4 db 0, 0, 0, 0, 0, 0, 0, 0, 0
	row5 db 0, 0, 0, 0, 0, 0, 0, 0, 0
	
	;sunflower info
	howManySf db 0
	sfX dw 15 dup(0)
	sfY dw 15 dup(0)
	
	;peashooter info
	peaX dw 15 dup (0)
	peaY dw 15 dup (0)
	peaIndex db 0
	isTherePea db 0
	isFired db 15 dup (0)
	
	;bullet info
	ShootX dw 15 dup (0)
	shootY dw 15 dup (0)
	shotHit db 0
	
	;zombies info
	zombieIndex db -1
	zombieX dw 50 dup (0)
	zombieY dw 50 dup (0)
	zombieLife db 50 dup (3)
	curZombieIndex db 0;to check if the current zombie was hit
	dontDrawPlants db 0;if were in the middle of returning the background of shoot or zombie, we cant orint plants because half of them will be deleted
	
	;to the save background proc
	curPointX dw 0
	curPointY dw 0
	curHowManyCols db 0
	
	PicLeft dw ?
	PicTop dw ?
	PicWidth dw ?
	PicHeight dw ?
	
	;zombies var to change the frequency zombies come
	zombieLoop dw 29999
	zombFreq dw 30000
	alreadyChanged db 0
	
	isChecking db 0		;flag to check if its the middle of cheking hit
	
	NoteE2      equ 3619  ; 329.63 Hz
	NoteF2      equ 3416  ; 349.23 Hz
	NoteG2      equ 3043  ; 391.00 Hz
	NoteA2      equ 2711  ; 440.00 Hz
	NoteB2      equ 2415  ; 493.88 Hz
	NoteC2      equ 4560  ; 261.63 Hz
	NoteD2      equ 4063  ; 293.66 Hz

	
	winSong  	dw NoteE2, NoteG2, NoteA2, NoteA2, NoteG2, NoteA2
				dw NoteB2, NoteC2, NoteD2, NoteE2, NoteE2, NoteD2, NoteE2, NoteF2, NoteG2
		
CODESEG
    ORG 100h
start:

	 mov ax, @data
	 mov ds,ax
	
	;initializations	
	call far LoadGame
	call ShowMouse
	call CheckPress
GAME:
	call PrintAllPlants
	call zombies	;create and move zombies, shoot and move bullets
	call shoot
	
	call _ZombieDelay
	call _ShootDelay
		
	call PrintMoney			;print how much money you got
	call addSfMoney			;adds the money from the sunflowers
	
	; call _ZombieDelay
	; call _ShootDelay
	
	call DeleteAll
	
	
	cmp [gameOver], 1
	je Victory
	cmp [gameOver], 2
	je Lost
	
	inc [loopCounter]
	
	mov ah, 1
	int 16h
	cmp ax, 011Bh	
	jne GAME
	jmp Lost
	
	
Victory:
	call PrintAllPlants
	mov dx, offset win
	mov [BmpLeft],110
	mov [BmpTop],10
	mov [BmpWidth], 130
	mov [BmpHeight] ,180
	
	call HideMouse
	call OpenShowBmp
	
@@song:	
	call PlaySong
	mov ah, 1
	int 16h
	cmp ax, 011Bh	
	jne @@song	
	jmp EXIT
	
Lost:
	call zombies
	mov dx, offset defeat
	mov [BmpLeft],35
	mov [BmpTop],5
	mov [BmpWidth], 250
	mov [BmpHeight] , 190
	
	;open and print startUp BMP. check if error
	call HideMouse
	call OpenShowBmp
	
	mov cx, 10
@@EndDelay:
	call _200MiliSecDelay
	loop @@EndDelay
	
EXIT:
	mov ah,0
	int 16h
	
	mov ax,2
	int 10h

	
	
	mov ax, 4C00h ; returns control to dos
  	int 21h
  
  
;---------------------------

proc PlaySong
    mov cx, 15                 ; Initialize loop counter with the number of notes to play
    lea si, [winSong]          ; Load the address of the note sequence into SI

NextNote:
    push cx                    ; Save the current value of CX (loop counter) on the stack
    
    mov bx, [word ptr si]      ; Load the current note frequency from the winSong array into BX
    mov al, 10110110b          ; Load control word 10110110b (182 in decimal) into AL
                               ; This configures the PIT for mode 3 (square wave generator)
    out 43h, al                ; Send the control word to the PIT control port (port 43h)
    
    mov ax, bx                 ; Move the frequency value from BX to AX
    out 42h, al                ; Send the low byte of the frequency value to PIT channel 2 (port 42h)
    mov al, ah                 ; Move the high byte of the frequency value to AL
    out 42h, al                ; Send the high byte of the frequency value to PIT channel 2 (port 42h)
    
    in al, 61h                 ; Read the current state of the speaker control port (port 61h)
    or al, 00000011b           ; Set bits 0 and 1 to enable the speaker and connect it to the PIT output
    out 61h, al                ; Write the modified value back to port 61h to turn on the speaker
    
    call _200MiliSecDelay      ; Call a subroutine to create a delay of approximately 200 milliseconds
    
    inc si                     ; Increment SI to point to the next note (low byte)
    inc si                     ; Increment SI to point to the next note (high byte)
    
    pop cx                     ; Restore the loop counter from the stack
    loop NextNote              ; Decrement CX and repeat the loop if CX is not zero
    
    in al, 61h                 ; Read the current state of the speaker control port (port 61h)
    and al, 11111100b          ; Clear bits 0 and 1 to disable the speaker and disconnect it from the PIT output
    out 61h, al                ; Write the modified value back to port 61h to turn off the speaker
    
    ret                        ; Return from the PlaySong procedure
endp PlaySong








proc DeleteAll
	;delete everything by printing the grass
	mov dx, offset grass
	mov [BmpLeft], GRASS_X
	mov [BmpTop], GRASS_Y
	mov [BmpWidth], GRASS_WIDTH
	mov [BmpHeight] ,GRASS_HEIGHT	
	call HideMouse
	call OpenShowBmp
	call ShowMouse
	
	ret
endp DeleteAll



proc PrintAllPlants
	;print all peashooters:
	xor cx, cx
	mov cl, [peaIndex]
	mov bx, 0
	cmp [isTherePea], 0;check if there are peas in the game
	je @@sunflower
	
@@PrintNextPea:
	push cx
	push bx
	mov ax, [peaY+bx]
	mov bx, 320
	mov dx, 0
	mul BX
	pop bx
	add ax, [peaX+bx]
	push bx
	mov di, ax
	
	mov dx, 25
	mov cx, 25
	mov si, offset peaPixels
	call PrintColorArray
	pop bx
	pop cx
	add bx, 2
	loop @@PrintNextPea
	
	
@@sunflower:
	mov cl, [howManySf]
	mov bx, 0
	cmp [howManySf], 0
	je @@EXIT
@@PrintNextSF:
	push cx
	push bx
	mov ax, [sfY+bx]
	mov bx, 320
	mov dx, 0
	mul BX
	pop bx
	add ax, [sfX+bx]
	push bx
	mov di, ax
	
	mov dx, 25
	mov cx, 25
	mov si, offset sunflowerPixels
	call PrintColorArray
	pop bx
	pop cx
	add bx, 2
	loop @@PrintNextSF
	
	
@@EXIT:	
	ret
endp PrintAllPlants




proc printPeashooter
	xor bx, BX
	mov bl, [peaIndex]
	mov ax, 2
	mul bl
	mov bl, al
	
	mov [BmpLeft], COL_SEVEN
	mov [BmpTop], ROW_ONE
	
	mov dx, [BmpLeft]
	mov [peaX+BX], dx
	
	mov dx, [BmpTop]
	mov [peaY+BX], dx
	
	mov [isTherePea], 1
	inc [peaIndex]
	
	mov dx, offset peaShooterStand
	mov [BmpWidth], 25
	mov [BmpHeight] ,25
	
	sub [money], 100;remove the money of the purchase
	
@@PrintBmp:
	;;;;;;;;;;;open and print peash BMP. check if error
	call HideMouse	
	call OpenShowBmp
	call ShowMouse
	mov [isBuyPress], 0




	ret
endp printPeashooter




proc zombies
	push ax
	push BX
	push cx

	cmp [zombFreq], 5;check if win
	ja @@cont2
	mov cx, 10
	mov bx, 39
@@checkWin:
	cmp [zombieLife+bx], 0
	jne @@moveZombies
	inc bx
	loop @@checkWin
	mov [gameOver], 1
	
@@cont2:	
	cmp [isTherePea], 1
	jne @@cont1
;change freq because there are peashooters in the game so every main iteration is longer
	cmp [alreadyChanged], 1
	je @@cont1
	mov [alreadyChanged], 1
	mov [zombFreq], 200
	mov [zombieLoop], 50
@@cont1:
	add [zombieLoop], 20
	mov ax, [zombFreq]
	cmp [zombieLoop], ax
	jb @@moveZombies
	
	mov [zombieLoop], 0
	sub [zombFreq], 4
	
	cmp [zombFreq], 5;check if win
	ja @@printZombie
	jmp @@EXIT
	
@@printZombie:	;print zombie at random row
	call randomZombie
	
@@moveZombies:	;move all of the zombies
	xor cx, cx
	mov cl, [zombieIndex]
	cmp cl, -1
	je @@EXIT
	inc cx
	
	mov bx, 0
	mov si, 0
	
@@nextOne:
	push cx	
	cmp [zombieLife+si], 0
	je @@contNext
	call MoveSpecZombie;move this specific zombie
	
@@contNext:	
	pop cx
	add bx, 2
	add si, 1
	loop @@nextOne

@@EXIT:
	pop cx
	pop bx
	pop ax
	ret
endp zombies



proc MoveSpecZombie
	push cx
	push si
	push BX
	
	sub	[zombieX+BX], 6
	mov ax, [zombieX+bx]
	mov [curZombieIndex], bl
	
	cmp [zombieLife+si], 0
	je @@EXITONE
	
	mov [curPointX], ax
	
	mov ax, [zombieY+bx]
	mov [curPointY], ax
	;print zombie with array
	mov bx, 320
	mov dx, 0
	mul BX
	add ax, [curPointX]
	mov di, ax
	
	mov dx, BMP_ZOMB_WIDTH
	mov cx, BMP_ZOMB_HEIGHT
	mov si, offset zombiePixels
	
	call PrintColorArray
	jmp @@isLoose
	
@@EXITONE:
	jmp @@EXIT
	
@@isLoose:
	cmp [curPointX], HOUSE_X_POSITION
	ja @@END
	mov [gameOver], 2
@@END:
	pop BX
	pop si
	pop cx
	
	
	cmp [zombieLife+si], 0
	je @@KillZombie
	jmp @@EXIT
	
@@KillZombie:
	mov [zombieX+bx], 0
	mov [zombieY+bx], 0
	
	
	
@@EXIT:	
	ret
endp MoveSpecZombie





; ax is the x position of the current bullet
;bx is the index of current peashooter and bullets (dw index)
proc CheckHit
	push si
	push dx
	push bx
	push ax
	push cx
	mov [isChecking], 1
	mov [shotHit], 0
	
	xor cx, cx
	mov cl, [zombieIndex]
	cmp cl, -1
	je @@EXIT
	inc cx
	mov si, 0;to check all zombies
	
@@NextZombie:
	push ax
	push cx
	push bx
	
	;add ax, SHOOT_WIDTH;to check the right side of the shoot
	;dec ax
	
	mov dx, [peaX+bx]	;dx = x of peashooter
	cmp dx, [zombieX+si];compare x of peashooter to x of zombie
	ja @@EXIT			;if the peashooter is to the right of the zombie its bullets cannot reach the zombie so leave
	
	cmp ax, [zombieX+si];check if the bullet passed the zombie
	jb @@EXIT;if the bullet is to the left of the zombie it means it didnt reach the zombie so leave
	
	mov ax, [shootY+BX]
	cmp ax, [zombieY+si]
	jne @@EXIT;if the y position of the bullet is not the same as the zombie its not in the same row so doesnt hit
	
	
	mov ax, si
	mov dx, 0
	mov bx, 2
	div bx
	mov bx, ax
	
	cmp [zombieLife+bx], 0
	jbe @@EXIT;if the zombie already dead but still there leave
	
	dec [zombieLife+bx]
	mov [shotHit], 1
	
@@EXIT:
	pop bx
	pop cx
	pop ax
	add si, 2
	loop @@NextZombie
	
	mov [isChecking], 0
	pop cx
	pop ax
	pop bx
	pop dx
	pop si
	ret
endp CheckHit







proc randomZombie
;get random row and put the zombie in it
	mov bx, 5
	call GetRandom
	cmp ax, 1
	je @@row2
	cmp ax, 2
	je @@row3
	cmp ax, 3
	je @@row4
	cmp ax, 4
	je @@row5
;row1:
	mov [curPointY], ROW_ONE
	jmp @@continue
@@row2:
	mov [curPointY], ROW_TWO
	jmp @@continue
@@row3:
	mov [curPointY], ROW_THREE
	jmp @@continue
@@row4:
	mov [curPointY], ROW_FOUR
	jmp @@continue
@@row5:
	mov [curPointY], ROW_FIVE
	
@@continue:	
	mov [curPointX], COL_END
	sub [curPointX], 10

;print zombie with array
	mov ax, [curPointY]
	mov bx, 320
	mov dx, 0
	mul BX
	add ax, [curPointX]
	mov di, ax
	
	mov dx, 20
	mov cx, 32
	mov si, offset zombiePixels
	call PrintColorArray
	
	
	;put in the zombie place arrays the new zombie position
	inc [zombieIndex]
	xor ax, ax
	mov al, [zombieIndex]
	mov bx, 2
	mul bl
	mov bx, ax
	mov ax, [curPointX]
	mov [zombieX+bx], ax
	mov ax, [curPointY]
	mov [zombieY+bx], ax
	

	ret
endp randomZombie




;dx = how many cols 
;cx how many rows
;si - the array of colors
;di start byte in screen (0 64000 -1)
proc PrintColorArray
	push ax
	push di
	
	call HideMouse
	
	mov ax, 0A000h; Set ES to point to VGA memory segment
	mov es, ax
	cld ; for movsb direction si --> di
	
@@NextRow:	
	push cx
	
	mov cx, dx
	
@@DRAWLINE:
    cmp [byte ptr si], PINK
    jnz @@NotPinkDraw
    
    inc si
    inc di
    jmp @@DontDraw
    
@@NotPinkDraw:
    movsb ; Copy line to the screen

@@DontDraw:
    loop @@DRAWLINE
	
	
	
	sub di,dx ; returns back to the begining of the line 
	add di, 320 ; go down one line by adding 320
	
	
	pop cx
	loop @@NextRow
	
		
	call ShowMouse	
	pop di
	pop ax
    ret
endp PrintColorArray


;cx = how many rows 
;[curHowManyCols] = how many cols
;curPointX = where to start the save on screen (X)
;curPointY = where to start the save on screen (Y)
;si = offset of where to save
proc saveBG
	push dx 
	push ax
	push bx 
	push di
	call HideMouse
	
	mov di, 0
	mov bx, 0
	mov dx, [curPointY]
@@NextRow:
	push cx
	xor cx, cx
	mov cl, [curHowManyCols];do a loop for all cols then go down one line
	@@saveCol:
		push cx
		mov bh, 0
		mov cx, [curPointX]
		add cx, di
		mov ah, 0dh
		int 10h;get pixel
		mov [si], al;put in array
		inc si	;increase index of array
		inc di
		pop cx
		loop @@saveCol
	pop cx
	inc dx
	mov di, 0
	loop @@NextRow
	
	call ShowMouse
	pop di
	pop bx
	pop ax
	pop dx
	ret
endp saveBG



;;peashooter info
	; peaX dw 50 dup (0)
	; peaY dw 50 dup (0)
	; peaIndex db 0
	; isTherePea db 0
	; isFired db 50 dup (0)
	
;;bullet info
	; shootPrinted db 50 dup(0) 
	; ShootX dw 50 dup (0)
	; shootY dw 50 dup (0)
	; shootTouched db 50 dup(0)
proc shoot
	push ax
	push bx
	push cx
	
	xor cx, cx
	mov cl, [peaIndex]
	mov bx, 0
	mov si, 0
	
	cmp [isTherePea], 0;check if there are peas in the game
	je @@EXITONE
	
@@shoot:
	cmp [isFired+si], 0;check if the peashooter has already shooted
	je @@fireExit 	   ;jmp to where it shot the first one
	
	mov ax, [ShootX+BX]
	cmp ax, END_OF_SHOOT_X
	jae @@RemoveShotExit;jump if out of boundaries
	
	call CheckHit
	cmp [shotHit], 1
	je @@RemoveShotExit
	
moveTheShoot:;this will move the shoot 5 pixels Right
push cx
push BX
push si

add [ShootX+BX], 10
;save background of where we are printing
	mov ax, [ShootX+bx]
	mov [curPointX], ax

	mov ax, [shootY+bx]
	mov [curPointY], ax

	
	;print the shot
	mov ax, [curPointY]
	mov bx, 320
	mov dx, 0
	mul BX
	add ax, [curPointX]
	mov di, ax
	
	mov dx, SHOOT_WIDTH
	mov cx, SHOOT_HEIGHT
	mov si, offset shootPixels
	
	call PrintColorArray	
	;call _ShootDelay
	
	jmp @@continue
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
@@EXITONE:	
jmp @@EXIT	
@@shootExit:
jmp @@shoot
@@fireExit:
jmp @@fire
@@RemoveShotExit:
jmp @@RemoveShot
@@ContMoveTheShoot:
jmp moveTheShoot
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
@@continue:
	pop si
	pop BX
	pop cx
	
	
@@doAgain:
	add bx, 2
	inc si
	loop @@shootExit
	jmp @@EXIT


@@RemoveShot:;this will remove the current pea's shot from the game
	mov [isFired+si], 0
	mov [ShootX+bx], 0
	mov [shootY+bx], 0
	
	jmp @@doAgain





@@fire:;this fire the shot of the current pea if he didnt shoot yet
	push cx
	push BX
	push si
	
	mov ax, [peaX+BX]
	add ax, 26
	mov [curPointX], ax
	
	mov ax, [peaY+bx]
	mov [curPointY], ax
	
	;print the shot
	mov ax, [curPointY]
	mov bx, 320
	mov dx, 0
	mul BX
	add ax, [curPointX]
	mov di, ax
	
	mov dx, SHOOT_WIDTH
	mov cx, SHOOT_HEIGHT
	mov si, offset shootPixels
	call PrintColorArray
	
	;;;;remove the shot from the screen
	; mov ax, [curPointY]
	; mov bx, 320
	; mov dx, 0
	; mul BX
	; add ax, [curPointX]
	; mov di, ax
	
	; mov dx, 12
	; mov cx, 12
	; mov si, offset shotBG
	; call PrintColorArray;delete the shot bu recoloring the BG with the array
	
	
	pop si
	pop BX
	pop cx
	
	;update to the shoot data structure
	mov [isFired+si], 1
	mov ax, [curPointY]
	mov [shootY+BX], ax
	mov ax, [curPointX]
	mov [ShootX+BX], ax
	jmp @@doAgain
	
@@EXIT:	
	pop cx
	pop bx
	pop ax
	ret
endp shoot




proc PrintMoney
push dx
push ax
	mov dh, 2
	mov dl, 3
	call SetCursorPosition
	mov ax, [money]
	call ShowAxDecimal
pop ax
pop dx
	ret
endp PrintMoney



proc addSfMoney;If loop counter divides by ??? add the sunflower money (if theres any)
	push ax
	push bx
	push dx
	
	cmp [loopCounter], 0
	je @@EXIT
	cmp [money], 999;max of money is 999
	je @@EXIT
	
	mov dx, 0
	mov ax, [loopCounter]
	mov bx, 10;only if loop counter divides by 60000
	div bx
	cmp dx, 0
	jne @@EXIT
	mov bl, [howManySf];mul every sunflower by 25 and add it to the current money
	mov ax, 25
	mul bl
	add [money], ax
	
	cmp [money], 999;max money is 999 so if theres more just delete it
	jbe @@EXIT
	mov [money], 999
		
@@EXIT:	
	pop dx
	pop bx
	pop ax
	ret
endp addSfMoney



;Asynchronous check if click button has been pressed or released
proc CheckPress
	push ds
	pop  es	 
	mov cx, 00000110b
	mov ax, seg PlaceCheckPlant
	mov es, ax
	mov dx, offset PlaceCheckPlant
	mov ax, 0ch
	int 33h
		
@@EXIT:	
	ret
endp CheckPress



proc PlaceCheckPlant far
	;;;;;CHECK IF PRESSED IN THE PLANTS BUYING 
	;;;;;AND CHECK WHICH PLANT IS IT
	shr cx, 1
	
	cmp [isChecking], 1
	je @@EXITONE
	
	cmp ax, 4
	je @@Released
	
;;;;;Left Click was pressed
	cmp cx, BMP_PSSF_BUY_LEFT	;check if its int the right of the left edge
	jb @@ExitOne					;of both peashooter and Sunflower
	
	cmp cx, BMP_PSSF_BUY_RIGHT	;check if its in the left of the right edge
	ja @@ExitOne					;of both peashooter and sunflower
	
	;;;CHECK IF PEASHOOTER
	cmp dx, BMP_PS_BUY_UP	;check if its below the high side
	jb @@ExitOne				;jmp to exit beacuse the sunflower is higher than peashooter so it doesnt matter
		
	cmp dx, BMP_PS_BUY_DOWN	;check if its above the low side
	ja @@checkIfSf 
	
	mov [isBuyPress], 1		;means PEASHOOTERBUY was pressed, 2 for sunflower
	jmp @@ExitOne
	
@@checkIfSf:
	;;;CHECK IF SUNFLOWER
	cmp dx, BMP_SF_BUY_UP	;check if its below the high side
		jb @@ExitOne
		
	cmp dx, BMP_SF_BUY_DOWN	;check if its above the low side
		ja @@ExitOne
	mov [isBuyPress], 2		;means sunflower was pressed, 2 for PEASHOOTERBUY
	
@@ExitOne:
	jmp @@EXIT

@@Released:
	cmp [dontDrawPlants], 1
	je @@ExitOne
	cmp [isBuyPress], 0
	je @@ExitOne
	cmp [money], 50
	jb @@ExitOne
	
	cmp cx, COL_ONE
	jb @@ExitOne
	cmp cx, COL_END
	ja @@ExitOne
	cmp dx, ROW_ONE
	jb @@ExitOne
	cmp dx, ROW_END
	ja @@ExitOne
	
	cmp dx, ROW_TWO
	jb @@RowOne
	cmp dx, ROW_THREE
	jb @@RowTwo
	cmp dx, ROW_FOUR
	jb @@RowThree
	cmp dx, ROW_FIVE
	jb @@RowFour
	jmp @@RowFive
	
@@RowOne:
	mov [BmpTop], ROW_ONE
	mov si, offset row1
	jmp @@checkCols
@@RowTwo:
	mov [BmpTop], ROW_TWO
	mov si, offset row2
	jmp @@checkCols
@@RowThree:
	mov [BmpTop], ROW_THREE
	mov si, offset row3
	jmp @@checkCols
@@RowFour:
	mov [BmpTop], ROW_FOUR
	mov si, offset row4
	jmp @@checkCols
@@RowFive:
	mov [BmpTop], ROW_FIVE
	mov si, offset row5
	
@@checkCols:
	cmp cx, COL_TWO
	jb @@ColOne
	cmp cx, COL_THREE
	jb @@ColTwo
	cmp cx, COL_FOUR
	jb @@ColThree
	cmp cx, COL_FIVE
	jb @@ColFour
	cmp cx, COL_SIX
	jb @@ColFive
	cmp cx, COL_SEVEN
	jb @@ColSix
	cmp cx, COL_EIGHT
	jb @@ColSeven
	cmp cx, COL_NINE
	jb @@ColEight
	jmp @@ColNine
	
@@ColOne:
	mov [BmpLeft], COL_ONE
	add si, 0
	jmp @@Print
@@ColTwo:
	mov [BmpLeft], COL_TWO
	add si, 1
	jmp @@Print
@@ColThree:
	mov [BmpLeft], COL_THREE
	add si, 2
	jmp @@Print
@@ColFour:
	mov [BmpLeft], COL_FOUR
	add si, 3
	jmp @@Print
@@ColFive:
	mov [BmpLeft], COL_FIVE
	add si, 4
	jmp @@Print
@@ColSix:
	mov [BmpLeft], COL_SIX
	add si, 5
	jmp @@Print
@@ColSeven:
	mov [BmpLeft], COL_SEVEN
	add si, 6
	jmp @@Print
@@ColEight:
	mov [BmpLeft], COL_EIGHT
	add si, 7
	jmp @@Print
@@ColNine:
	mov [BmpLeft], COL_NINE
	add si, 8
	
@@Print:
	cmp [byte ptr si], 0;if theres already a plant there dont plant it
	jne @@EXITTWO
	cmp [isBuyPress], 2
	je @@SunFlowerPrint
	
@@PeashooterPrint:;put info of bmp of Peashooter stand
	cmp [peaIndex], 14
	je @@EXITTWO
	cmp [money], 100
	jb @@EXITTWO

	
	;update to all places of peashooter that there is a new one and update his info
	xor bx, BX
	mov bl, [peaIndex]
	mov ax, 2
	mul bl
	mov bl, al
	
	mov dx, [BmpLeft]
	mov [peaX+BX], dx
	
	mov dx, [BmpTop]
	mov [peaY+BX], dx
	
	mov [isTherePea], 1
	inc [peaIndex]
	
	mov dx, offset peaShooterStand
	mov [BmpWidth], 25
	mov [BmpHeight] ,25
	
	mov [byte ptr si], 1;put in the array
	sub [money], 100;remove the money of the purchase
	jmp @@PrintBmp

@@EXITTWO:
	jmp @@EXIT
	
@@SunFlowerPrint:;put info of bmp of SunFlower stand, wait for start/ rules
	cmp [howManySf], 15
	je @@EXIT
	mov dx, offset sunFlowerStand
	mov [BmpWidth], 25
	mov [BmpHeight] ,25
	mov [byte ptr si], 2;put in the array
	sub [money], 50;remove the money of the purchase
	
	xor bx, BX
	mov bl, [howManySf]
	mov ax, 2
	mul bl
	mov bl, al
	
	mov dx, [BmpLeft]
	mov [sfX+BX], dx
	
	mov dx, [BmpTop]
	mov [sfY+BX], dx
	
	inc [howManySf]

@@PrintBmp:
	;;;;;;;;;;;open and print peash BMP. check if error
	call HideMouse	
	call OpenShowBmp
	call ShowMouse
	mov [isBuyPress], 0

	
@@EXIT:	
	; mov ah, 0
	; mov al, [isBuyPress]
	; call ShowAxDecimal
	
	retf
endp PlaceCheckPlant






;----------
;Give a random number by the current hundredths
;input: in bx which number you want from 1 to bx (BX MAX IS 100)
;output: Random number in ax
;----------
proc GetRandom
	push dx
	push cx
	
	mov ah, 2Ch
	int 21h
	
	mov dh, 0
	mov ax, dx 
	mov dx, bx
	div dl
	
	mov al, ah
	mov ah, 0

	pop cx 	
	pop dx
	ret
endp GetRandom



;DH = row
;DL = column
proc SetCursorPosition
	mov ah, 2
	mov bh, 0
	int 10h

	ret
endp SetCursorPosition



proc LoadGame far
	;set graphic Mode
	call SetGraphic

	;install mouse
	mov ax, 0
	int 33h
	
	mov [startWithPink], 0
	call firstGameScreen	;prints the start up page (start button and plants button) and wait for start button to be pressed	
							;Right after it was pressed start initialize the variables of the Game:
	mov [gameOver], 0
	mov [money], 150
	mov [loopCounter], 1
	
	call HideMouse
	mov [startWithPink], 1
	call GetEntitiesPixels	;get the pixels of zombie and shoot
	mov [startWithPink], 0
	
	call PrintTheMainGame	;print the game itself (Map, buy section ETC.)
	
	
	ret
endp LoadGame
	
	

	
	
;print zombie and shoot, get pixels of them and delete them
proc GetEntitiesPixels

	;put info of bmp of zombie
	mov dx, offset zombie
	mov [BmpLeft],0
	mov [BmpTop],0
	mov [BmpWidth], 20
	mov [BmpHeight] ,32
	;open and print zomb BMP
	call OpenShowBmp
	
	;save BG of zombie
	mov cx, 32
	mov [curHowManyCols], 20
	mov [curpointX], 0
	mov [curPointY], 0
	mov si, offset zombiePixels
	call saveBG
	
	
	;put info of bmp of bullet
	mov dx, offset bullets
	mov [BmpLeft],0
	mov [BmpTop],0
	mov [BmpWidth], 12
	mov [BmpHeight] ,12
	;open and print shoot BMP
	call OpenShowBmp
	
	;save BG of bullet
	mov cx, 12
	mov [curHowManyCols], 12
	mov [curpointX], 0
	mov [curPointY], 0
	mov si, offset shootPixels
	call saveBG
	
	
	;put info of bmp of peashooter
	mov dx, offset peaShooterStand
	mov [BmpLeft],0
	mov [BmpTop],0
	mov [BmpWidth], 25
	mov [BmpHeight] , 25
	;open and print shoot BMP
	call OpenShowBmp
	
	;save BG of peaShooterStand
	mov cx, 25
	mov [curHowManyCols], 25
	mov [curpointX], 0
	mov [curPointY], 0
	mov si, offset peaPixels
	call saveBG
	
	
	;put info of bmp of sunflower
	mov dx, offset sunFlowerStand
	mov [BmpLeft],0
	mov [BmpTop],0
	mov [BmpWidth], 25
	mov [BmpHeight] , 25
	;open and print shoot BMP
	call OpenShowBmp
	
	;save BG of sunflower
	mov cx, 25
	mov [curHowManyCols], 25
	mov [curpointX], 0
	mov [curPointY], 0
	mov si, offset sunflowerPixels
	call saveBG
	
	ret
endp GetEntitiesPixels



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



proc firstGameScreen;print start up picture and wait for start


	;put info of bmp of loading screen, wait for start/ rules
	mov dx, offset startUp
	mov [BmpLeft],0
	mov [BmpTop],0
	mov [BmpWidth], 320
	mov [BmpHeight] ,200
	
	;open and print startUp BMP. check if error
	call OpenShowBmp


	;put info of bmp of start Button
	mov dx, offset startButton
	mov [BmpLeft],138
	mov [BmpTop],137
	mov [BmpWidth], BMP_START_WIDTH
	mov [BmpHeight] ,BMP_START_HEIGHT
	
	;open and print start Button BMP. check if error
	call OpenShowBmp	
	call ShowMouse
	
	
	
@@waitForPress:	;WAIT for the LEFT CLICK on the start button
	mov ax, 5
	mov bx, 0
	int 33h
	shr cx, 1
	
	cmp ax, 00000001b		;check if pressed
		jne @@waitForPress
	cmp cx, BMP_START_LEFT	;check if its int the right of the left edge
		jb @@waitForPress
	cmp cx, BMP_START_RIGHT	;check if its in the left of the right edge
		ja @@waitForPress
	cmp dx, BMP_START_UP	;check if its below the high side
		jb @@waitForPress
	cmp dx, BMP_START_DOWN	;check if its above the low side
		ja @@waitForPress	
		
	jmp @@EXIT
	


@@EXIT:
	ret
endp firstGameScreen



proc PrintTheMainGame
	
	;;;;puts the info of bmp of map
	mov dx, offset mapName
	mov [BmpLeft],0
	mov [BmpTop],0
	mov [BmpWidth], 320
	mov [BmpHeight] ,200
	
	;;;;open and print garden BMP. check if error
	call OpenShowBmp
	
	
	
	;;;;draw the buy section rectangle (cx = col dx= row al = color si = height di = width)
	mov dx, 10
	mov cx, 5
	mov al, 67
	mov si, 130
	mov di, 58
	call Rect
	
	;;;;move the cursor to the place where it says " $: "
	mov dh, 2
	mov dl, 1
	call SetCursorPosition
	
	printChar '$', 02h;color green 02h
	
	inc dl
	call SetCursorPosition
	printChar ':', 02h;color green 02h
	
	
	
	;;;;puts the info of peashooter buy section.
	mov dx, offset peaBS
	mov [BmpLeft],7
	mov [BmpTop],30
	mov [BmpWidth], BMP_BUY_PLANTS_WIDTH
	mov [BmpHeight] ,BMP_BUY_PLANTS_HEIGHT
	
	;;;;open and print BMP. check if error
	call OpenShowBmp

	
	
	
	;;;;puts the info of Sunflower buy section.
	mov dx, offset SunflowerBS
	mov [BmpTop],60

	
	;;;;;open and print BMP. check if error
	call OpenShowBmp

	JMP @@EXIT



	
	
	
@@EXIT:
	ret
endp PrintTheMainGame





proc ShowMouse
	push ax
	mov ax, 01
	int 33h
	pop ax
	ret
endp ShowMouse


proc HideMouse
	push ax
	mov ax, 02
	int 33h
	pop ax
	ret
endp HideMouse


proc  SetGraphic
	mov ax,13h   ; 320 X 200 
				 ;Mode 13h is an IBM VGA BIOS mode. It is the specific standard 256-color mode 
	int 10h
	ret
endp 	SetGraphic



proc OpenShowBmp near
	mov [ErrorFile],0
	 
	call OpenBmpFile;open the file
	cmp [ErrorFile],1
	je @@ExitProc
	
	call ReadBmpHeader
	
	call ReadBmpPalette
	
	call CopyBmpPalette
	
	call  ShowBmp
	
@@cont:	
	call CloseBmpFile
@@ExitProc:
	ret
endp OpenShowBmp






; input dx filename to open
proc OpenBmpFile	near						 
	mov ah, 3Dh
	xor al, al
	int 21h
	jc @@ErrorAtOpen
	mov [FileHandle], ax
	jmp @@ExitProc
	
@@ErrorAtOpen:
	mov [ErrorFile],1
@@ExitProc:	
	ret
endp OpenBmpFile



proc CloseBmpFile near
	mov ah,3Eh
	mov bx, [FileHandle]
	int 21h
	ret
endp CloseBmpFile







; Read 54 bytes the Header
proc ReadBmpHeader	near					
	push cx
	push dx
	
	mov ah, 3fh
	mov bx, [FileHandle]
	mov cx, 54
	mov dx	, offset Header
	int 21h
	
	pop dx
	pop cx
	ret
endp ReadBmpHeader






proc ReadBmpPalette near ; Read BMP file color palette, 256 colors * 4 bytes (400h)
						 ; 4 bytes for each color BGR + null)			
	push cx
	push dx
	
	mov ah,3fh
	mov cx,400h
	mov dx,offset Palette
	int 21h
	
	pop dx
	pop cx
	
	ret
endp ReadBmpPalette




; Will move out to screen memory the colors
; video ports are 3C8h for number of first color
; and 3C9h for all rest
proc CopyBmpPalette		near					
										
	push cx
	push dx
	
	mov si,offset Palette
	mov cx,256
	mov dx,3C8h
	mov al,0  ; black first							
	out dx,al ;3C8h
	inc dx	  ;3C9h
CopyNextColor:
	mov al,[si+2] 		; Red				
	shr al,2 			; divide by 4 Max (cos max is 63 and we have here max 255 ) (loosing color resolution).				
	out dx,al 						
	mov al,[si+1] 		; Green.				
	shr al,2            
	out dx,al 							
	mov al,[si] 		; Blue.				
	shr al,2            
	out dx,al 							
	add si,4 			; Point to next color.  (4 bytes for each color BGR + null)				
								
	loop CopyNextColor
	
	pop dx
	pop cx
	
	ret
endp CopyBmpPalette






proc ShowBMP
; BMP graphics are saved upside-down.
; Read the graphic line by line (BmpHeight lines in VGA format),
; displaying the lines from bottom to top.
	push cx
	
	mov ax, 0A000h
	mov es, ax
	
 
	mov ax,[BmpWidth] ; row size must dived by 4 so if it less we must calculate the extra padding bytes
	mov bp, 0
	and ax, 3
	jz @@row_ok
	mov bp,4
	sub bp,ax

@@row_ok:	
	mov cx,[BmpHeight]
    dec cx
	add cx,[BmpTop] ; add the Y on entire screen
	; next 5 lines  di will be  = cx*320 + dx , point to the correct screen line
	mov di,cx
	shl cx,6
	shl di,8
	add di,cx
	add di,[BmpLeft]
	cld ; Clear direction flag, for movsb forward
	
	mov cx, [BmpHeight]
@@NextLine:
	push cx
 
	; small Read one line
	mov ah,3fh
	mov cx,[BmpWidth]  
	add cx,bp  ; extra  bytes to each row must be divided by 4
	mov dx,offset ScrLine
	int 21h
	cmp [startWithPink], 1
	je @@WithPink		;if we need to get the pink pixels too so jump to normal print
	; Copy one line into video memory es:di
	mov cx,[BmpWidth]  
	mov si,offset ScrLine
	
	
;rep movsb ; Copy line to the screen
 @@DRAWLINE:
    
    cmp [byte ptr si], PINK
    jnz @@NotPinkDraw
    
    inc si
    inc di
    jmp @@DontDraw
    
@@NotPinkDraw:
    
    movsb ; Copy line to the screen
    
@@DontDraw:
    loop @@DRAWLINE	
	
	
	sub di,[BmpWidth]    ; return to left bmp
	sub di,SCREEN_WIDTH  ; jump one screen line up
	
	pop cx
	loop @@NextLine
	jmp @@EXIT
	
	
@@WithPink:		;this is the normal bmp print
	mov cx,[BmpWidth]  
	mov si,offset ScrLine
	rep movsb ; Copy line to the screen
	sub di,[BmpWidth]            ; return to left bmp
	sub di,SCREEN_WIDTH  ; jump one screen line up
	
	pop cx
	loop @@NextLine
	
	
	
@@EXIT:	
	pop cx
	ret
endp ShowBMP





proc DrawHorizontalLine	near
	push si
	push cx
DrawLine:
	cmp si,0
	jz ExitDrawLine	
	 
    mov ah,0ch	
	int 10h    ; put pixel
	 
	
	inc cx
	dec si
	jmp DrawLine
	
	
ExitDrawLine:
	pop cx
    pop si
	ret
endp DrawHorizontalLine






proc DrawVerticalLine	near
	push si
	push dx
 
@@DrawVertical:
	cmp si,0;Check if length = 0
	jz @@ExitDrawLine	
	 
    mov ah,0ch	
	int 10h    ; put pixel
	
	 
	
	inc dx;to go to next pixel
	dec si;decrease length by one
	jmp @@DrawVertical
	
	
@@ExitDrawLine:
	pop dx
    pop si
	ret
endp DrawVerticalLine




; cx = col dx= row al = color si = height di = width 
proc Rect
	push cx
	push di
NextVerticalLine:	
	
	cmp di,0
	jz @@EndRect
	
	cmp si,0
	jz @@EndRect
	call DrawVerticalLine
	inc cx
	dec di
	jmp NextVerticalLine
	
	
@@EndRect:
	pop di
	pop cx
	ret
endp Rect







proc ShowAxDecimal
	push ax
	push bx
	push cx
	push dx

	 
	; check if negative
	test ax,08000h
	jz PositiveAx
		
	;  put '-' on the screen
	push ax
	mov dl,'-'
	mov ah,2
	int 21h
	pop ax

	neg ax ; make it positive
PositiveAx:
	mov cx,0   ; will count how many time we did push 
	mov bx,10  ; the divider

put_mode_to_stack:
	xor dx,dx
	div bx
	add dl,30h
	; dl is the current LSB digit 
	; we cant push only dl so we push all dx
	push dx    
	inc cx
	cmp ax,9   ; check if it is the last time to div
	jg put_mode_to_stack

	cmp ax,0
	jz pop_next  ; jump if ax was totally 0
	add al,30h  
	mov dl, al    
	mov ah, 2h
	int 21h        ; show first digit MSB
	   
pop_next: 
	pop ax    ; remove all rest LIFO (reverse) (MSB to LSB)
	mov dl, al
	mov ah, 2h
	int 21h        ; show all rest digits
	loop pop_next

	;mov dl, ','
	mov dl, ' '
	mov ah, 2h
	int 21h
	mov dl, ' '
	mov ah, 2h
	int 21h

	
	pop dx
	pop cx
	pop bx
	pop ax

	ret
endp ShowAxDecimal




proc _200MiliSecDelay
	push cx
	
	mov cx ,1000 
@@Self1:
	
	push cx
	mov cx,600 

@@Self2:	
	loop @@Self2
	
	pop cx
	loop @@Self1
	
	pop cx
	ret
endp _200MiliSecDelay


proc _ZombieDelay
	push cx
	push ax
	push dx
	
	; mov ax ,2000
	; xor cx, cx
	; mov cl, [zombieIndex]
	; cmp cx, 0
	; je @@regular
	; cmp cx, -1
	; je @@regular
	; mov dx, 0
	; div cx
	; mov cx, ax
	; jmp @@Self1

@@regular:
	mov cx, 1000
	
@@Self1:
	
	push cx
	mov cx,300 

@@Self2:	
	loop @@Self2
	
	pop cx
	loop @@Self1

@@EXIT:
	pop dx
	pop ax
	pop cx
	ret
endp _ZombieDelay




proc _ShootDelay
	push cx
	push ax
	push dx
	
	mov ax ,700 
	xor cx, cx
	mov cl, [peaIndex]
	cmp cx, 0
	je @@regular
	mov dx, 0
	div cx
	mov cx, ax
	jmp @@Self1

@@regular:
	mov cx, 700
	
@@Self1:
	
	push cx
	mov cx,300 

@@Self2:	
	loop @@Self2
	
	pop cx
	loop @@Self1

@@EXIT:
	pop dx
	pop ax
	pop cx
	ret
endp _ShootDelay

proc PrintEveryPeash
	call HideMouse	
	mov [BmpLeft],COL_ONE
	mov [BmpTop],ROW_ONE
	mov dx, offset peaShooterStand
	mov [BmpWidth], 25
	mov [BmpHeight] ,25
	
	;;;;;;;;;;;open and print peash BMP. check if error
	call OpenShowBmp
	
	mov [BmpLeft], COL_TWO
	mov [BmpTop],ROW_ONE
	mov dx, offset peaShooterStand
	mov [BmpWidth], 25
	mov [BmpHeight] ,25
	call OpenShowBmp
	
	mov [BmpLeft], COL_THREE
	mov [BmpTop],ROW_ONE
	mov dx, offset peaShooterStand
	mov [BmpWidth], 25
	mov [BmpHeight] ,25
	call OpenShowBmp
	
	mov [BmpLeft], COL_FOUR
	mov [BmpTop],ROW_ONE
	mov dx, offset peaShooterStand
	mov [BmpWidth], 25
	mov [BmpHeight] ,25
	call OpenShowBmp
	
	mov [BmpLeft], COL_FIVE
	mov [BmpTop],ROW_ONE
	mov dx, offset peaShooterStand
	mov [BmpWidth], 25
	mov [BmpHeight] ,25
	call OpenShowBmp
	
	mov [BmpLeft], COL_SIX
	mov [BmpTop],ROW_ONE
	mov dx, offset peaShooterStand
	mov [BmpWidth], 25
	mov [BmpHeight] ,25
	call OpenShowBmp
	
	mov [BmpLeft], COL_SEVEN
	mov [BmpTop],ROW_ONE
	mov dx, offset peaShooterStand
	mov [BmpWidth], 25
	mov [BmpHeight] ,25
	call OpenShowBmp
	
	mov [BmpLeft], COL_EIGHT
	mov [BmpTop],ROW_ONE
	mov dx, offset peaShooterStand
	mov [BmpWidth], 25
	mov [BmpHeight] ,25
	call OpenShowBmp
	
	mov [BmpLeft], COL_NINE
	mov [BmpTop],ROW_ONE
	mov dx, offset peaShooterStand
	mov [BmpWidth], 25
	mov [BmpHeight] ,25
	call OpenShowBmp
	
	call ShowMouse
	
	ret
endp PrintEveryPeash



proc PrintTheCollsArrangment
push cx
push dx
push ax
push si

	mov cx, COL_ONE
	mov dx, 0
	mov si, 200
	mov al, 0
	call DrawVerticalLine
	mov cx, COL_TWO
	call DrawVerticalLine
	mov cx, COL_THREE
	call DrawVerticalLine
	mov cx, COL_FOUR
	call DrawVerticalLine
	mov cx, COL_FIVE
	call DrawVerticalLine
	mov cx, COL_SIX
	call DrawVerticalLine
	mov cx, COL_SEVEN
	call DrawVerticalLine
	mov cx, COL_EIGHT
	call DrawVerticalLine
	mov cx, COL_NINE
	call DrawVerticalLine
	mov cx, COL_END
	call DrawVerticalLine

pop si
pop ax
pop dx
pop cx
	ret
endp PrintTheCollsArrangment



;---------------------------




END start