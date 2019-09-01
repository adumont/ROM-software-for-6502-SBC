*-------------------------------------------------------------------------------
*--
*--   Serial Management routines
*--   Handle a 6850 ACIA by default, can switch  to 6551
*--
*-------------------------------------------------------------------------------

                DSK	  Serial.bin
                ORG   $FE00
                TYP   $06

ACIA6551        EQU   1
ACIA_Base       EQU   $A000          ; ACIA is located at $A000

                DO    ACIA6551

TDREBIT         EQU   #%00010000     ; Transmit Data Register Empty bit
RDRFBIT         EQU   #%00001000     ; Receive Data Buffer Full bit
ACIAControlbits EQU   #%00011110     ; 1 stop, 8bits, 9600 bauds 
ACIACommandbits EQU   #%00001011     ;

                ELSE 

TDREBIT         EQU   #%00000010     ; Transmit Data Register Empty bit
RDRFBIT         EQU   #%00000001     ; Receive Data Buffer Full bit
ACIACONFIG      EQU   #%00010100     ; 8bit + 1 stop

                FIN

CTRLCCODE       EQU   #$03           ; Control-C ASCII Code

                DO    ACIA6551

ACIA_Control    EQU   ACIA_Base + 3  ; Control Register Address
ACIA_Command    EQU   ACIA_Base + 2  ; Command Register Address
ACIA_Status     EQU   ACIA_Base + 1  ; Status Register Address
ACIA_Data       EQU   ACIA_Base      ; TXDATA and RXDATA shares same address
                
                ELSE

ACIA_Control    EQU   ACIA_Base + 0  ; Control and Status Register are at the
ACIA_Status     EQU   ACIA_Base + 0  ; same base address
ACIA_Data       EQU   ACIA_Base + 1  ; TXDATA and RXDATA also sharing address

                FIN

*-------------------------------------------------------------------------------
*-- BIOSCFGACIA Configure ACIA Speed, bits, etc
*-------------------------------------------------------------------------------

BIOSCFGACIA     ENT
                PHA                     ; Save accumulator

                DO    ACIA6551                
                LDA   ACIAControlbits   ; Load the configuration bit
                STA   ACIA_Control      ; Send configuration to ACIA
                LDA   ACIACommandbits   ;
                STA   ACIA_Command      ;
                
                ELSE
                
                LDA   ACIACONFIG    ; Load the configuration bit
                STA   ACIA_Control  ; Send configuration to ACIA
                
                FIN
                
                PLA                     ; Restore Accumulator
                RTS                     ; Job done, return

*-------------------------------------------------------------------------------
*-- BIOSCHOUT handle display of a character on Serial Output
*-- Character must be placed in Accumulator
*-------------------------------------------------------------------------------

BIOSCHOUT       ENT                 ; Global entry point
                PHA                 ; Save the character on the stack
SERIALOUTBUSY   LDA   ACIA_Status   ; Get Status from ACIA
	            AND	  TDREBIT       ; Mask to keep only TDREBIT
	            CMP	  TDREBIT       ; Check if ACIA is available
	            BNE	  SERIALOUTBUSY ; If ACIA is not ready, check again
	            PLA                 ; Restore Character from Stack
	            STA	  ACIA_Data     ; Actually send the character to ACIA
	            RTS                 ; Job done, return

*-------------------------------------------------------------------------------
*-- BIOSCHGET Retrieve character from ACIA Buffer
*-- Character,if any, will be placed in Accumulator
*-- Carry set if data has been retrieved, cleared if we got nothing
*-------------------------------------------------------------------------------

BIOSCHGET       ENT                 ; Global entry point
                LDA	  ACIA_Status   ; Get status from ACIA
	            AND	  RDRFBIT       ; Mask to keep only RDRFBIT
	            CMP	  RDRFBIT       ; Is there someting to read ?
	            BNE	  ACIAEMPTY     ; Nothing to read
	            LDA	  ACIA_Data     ; Acrually get data from ACIA
	            SEC		            ; Set Carry if we got somehing
	            RTS                 ; Job done, return
ACIAEMPTY       CLC                 ; We gor norhing, clear Carry
                RTS                 ; Job done, return

*-------------------------------------------------------------------------------
*-- BIOSCHISCTRLC Get a character and check if it s CTRL-C
*-- Character,if any, will be placed in Accumulator
*-- Carry set if data has been retrieved, cleared if we got nothing
*-------------------------------------------------------------------------------

BIOSCHISCTRLC   ENT                   ; Global entry point
                JSR   BIOSCHGET       ; Get a charachter
                BCC   NOTCTRLC        ; Carry clear, we didn't get anything
                CMP   CTRLCCODE       ; Check the ASCII code
                BNE   NOTCTRLC        ; We got somehing else
                SEC                   ; Control-C ! Set Carry and return.
                RTS                   ; Job done, return
NOTCTRLC        CLC                   ; Clear Carry, we got something else
                RTS                   ;Job done, return


END