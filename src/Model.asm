 MODULE DETECT

;; Useful info from here:
;; http://www.cpcwiki.eu/forum/programming/how-do-i-detect-a-cpc-plus-in-assembly/


@ModelNames:
TxtUnknown: db "UNKNOWN", 0
TxtModelCPC464: db "CPC 464", 0 
TxtModelCPC664: db "CPC 664", 0 
TxtModelCPC6128: db "CPC 6128", 0 
;;TxtModel464Plus: db "464 PLUS", 0 
;;TxtModel6128PLUS: db "6128 PLUS", 0 
;;TxtModelGX4000: db "GX4000", 0 
TxtModelPlusRange: db "PLUS/GX4000", 0 

;; Offsets from ModelNames

@ModelNameTableOffset:
	db 0
	db TxtModelCPC464 - TxtUnknown
	db TxtModelCPC664 - TxtUnknown
	db TxtModelCPC6128 - TxtUnknown
	db TxtModelPlusRange - TxtUnknown
	db TxtModelPlusRange - TxtUnknown
	db TxtModelPlusRange - TxtUnknown

@MODEL_UNKNOWN 		EQU 0
@MODEL_CPC464 		EQU 1
@MODEL_CPC664 		EQU 2
@MODEL_CPC6128 		EQU 3
@MODEL_464PLUS 		EQU 4
@MODEL_C6128PLUS 	EQU 5
@MODEL_GX4000	 	EQU 6




;; OUT:	(ModelType) - best guess about the Amstrad model
;;	(KeyboardLanguage) - keyboard language on CPC models
@DetectModel:
	;; First see if it's a Plus/GX4000
	call	UnlockPlus
	call	CanAccessPlusASIC
      	jr	z, .notPlus

      	;; TODO: Tell 464, 6128, and GX4000 apart
      	ld	a, MODEL_C6128PLUS
	ld	(ModelType), a

	;; We can't tell the keyboard language on Plus models, so leave it as English by default
	jr	.englishKeyboard

.notPlus:
	ld	ix, #0006
	call	ReadFromLowerROM
	ld	a, l
	cp	#91
	jr	nz, .not6128
	ld	a, h
	cp	#05
	jr	nz, .not6128

	;; 6128
	ld	a, MODEL_CPC6128
	ld	(ModelType), a

	ld	ix, #069E
	call	ReadFromLowerROM
	;; Check that the word we read is 'x3' where x is the language. If the 3 isn't there, leave it in English
	ld	a, h
	cp	'3'
	jr	nz, .englishKeyboard
	jr	.checkLanguageFromVersionString


.not6128::
	;; 464 or 664
	cp	#7B
	jr	nz, .not664

	;; 664
      	ld	a, MODEL_CPC664
	ld	(ModelType), a
	jr	.englishKeyboard

	;; 464
.not664:
      	ld	a, MODEL_CPC464
	ld	(ModelType), a

	ld	ix, #0682
	call	ReadFromLowerROM

.checkLanguageFromVersionString:
	ld	a, l
	cp	's'
	jr	z, .spanishKeyboard

	ld	a, l
	cp	'f'
	jr	z, .frenchKeyboard

	;;jr	.englishKeyboard

.englishKeyboard:	
	ld	a, KEYBOARD_LANGUAGE_ENGLISH
	ld	(KeyboardLanguage), a
	ret

.spanishKeyboard:
	ld	a, KEYBOARD_LANGUAGE_SPANISH
	ld	(KeyboardLanguage), a
	ret

.frenchKeyboard:
	ld	a, KEYBOARD_LANGUAGE_FRENCH
	ld	(KeyboardLanguage), a
	ret


// http://cpctech.cpc-live.com/docs/arnold5a.html
UnlockPlus:
	ld	b, #BC
	ld 	hl, PlusUnlockSequence
	ld 	d, PlusUnlockSequenceLen
.loop:
	inc	b
	outi
	dec 	d
	jr 	nz, .loop
	ret

PlusUnlockSequence:
	defb #FF, #00, #FF, #77, #B3, #51, #A8, #D4, #62, #39, #9C, #46, #2B, #15, #8A, #CD, #EE
PlusUnlockSequenceLen EQU $-PlusUnlockSequence

 ENDMODULE
