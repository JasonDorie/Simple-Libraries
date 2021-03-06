{{Propeller Board of Education.spin

Configuration Methods for Propeller Board
of Education system clock.

See end of file for author, version,
copyright and terms of use.

IMPORTANT  This object simplifies configuring
           the Propeller chip's system clock.
           Most Propeller example programs for
           other boards use _CLKMODE and
           _XINFREQ in a CON block.  Look those
           two terms up in the Propeller Manual
           for examples.

BUGS       Please send bug reports, questions, 
&          suggestions, and improved versions 
UPDATES    of this object to alindsay@parallax.com.
           Also, check learn.parallax.com
           periodically for updated versions.
           
}}
VAR
  long  XINFreq   'Propeller XIN frequency

PUB Clock(clockfreq) | i, pll
{{Set the Propeller chip's system clock rate.

Parameter:

  clockfreq = Clock rate in Hz.
                Valid clockfreq values:
                5_000_000,10_000_000,
                20_000_000, 40_000_000,  
                80_000_000

Example - Propeller system clock to 80 MHz.

  ' Sets Propeller System Clock to run at
  ' 80 MHz.
  OBJ
    system : "Propeller Board of Education"

  PUB Go
    system.Clock(80_000_000)
}}

  i := lookdown(clockfreq:5000000,10000000,20000000,40000000,80000000)
  pll := lookup(i:pll1x, pll2x, pll4x, pll8x, pll16x) 
  OscFreq(5_000_000)
  ClockSet(xtal1 + pll)

PUB OscFreq(XINFrequency)
{{Call this before first call to SetClock.

Parameters:

  XINFrequency = Frequency (in Hz) that
                 external crystal/clock is
                 driving into XIN pin.  Use
                 0 if no external clock
                 source connected to
                 the Propeller.
}}
   XINFreq := XINFrequency

PUB ClockSet(Mode): NewFreq | PLLx, XTALx, RCx
{{Set System Clock to Mode.
Exits without modifying System Clock if Mode
is invalid.

Parameters:

  Mode = a combination of RCSLOW, RCFAST, XINPUT,
         XTALx and PLLx clock setting constants.

RETURNS:

New clock frequency.

}}                                                                                                      
  if Valid(Mode)                                                                                           'If Mode is valid                                                                     'The following is the enumerated   
    RCx   := Mode & $3                                                                                     '  Get RCSLOW, RCFAST setting                                                         'clock setting constants that are  
    XTALx := Mode >> 2 & $F                                                                                '  Get XINPUT, XTAL1, XTAL2, XTAL3 setting                                            'used for the Mode parameter.      
    PLLx  := Mode >> 6 & $1F                                                                               '  Get PLL1X, PLL2X, PLL4X, PLL8X, PLL16X setting                                     ' ┌──────────┬───────┬──────┐      
                                                                                                                                                                                                 ' │ Clock    │       │ Mode │      
           '┌───────────────────────────────── New CLK Register Value ─────────────────────────────────┐                                                                                         ' │ Setting  │ Value │ Bit  │      
           '┌────── PLLENA & OSCENA (6&5) ─────┐   ┌── OSCMx (4:3) ───┐   ┌─────── CLKSELx (2:0) ───────┐                                                                                        ' │ Constant │       │      │      
    Mode := $60 & (PLLx > 0) | $20 & (XTALx > 0) | >| (XTALx >> 1) << 3 | $12 >> (3 - RCx) & $3 + >| PLLx  '  Calculate new clock mode (CLK Register Value)                                      ' ├──────────┼───────┼──────┤      
           '└── any PLLx? ─┘   └ XTALx/XINPUT? ┘   └───── XTALx ──────┘   └── RCx and XINPUT ─┘   └─PLLx┘                                                                                        ' │  PLL16x  │ 1024  │  10  │      
                                                                                                                                                                                                 ' │  PLL8x   │  512  │   9  │      
    NewFreq := XINFreq*(PLLx#>||(RCx==0)) + 12_000_000*RCx&$1 + 20_000*RCx>>1                              '  Calculate new system clock frequency                                               ' │  PLL4x   │  256  │   8  │      
                                                                                                                                                                                                 ' │  PLL2x   │  128  │   7  │      
    if not ((clkmode < $20) and (Mode > $20))                                                              '  If not switching from internal to external plus oscillator and PLL circuits        ' │  PLL1x   │   64  │   6  │      
      clkset(Mode, NewFreq)                                                                                '    Switch to new clock mode immediately (and set new frequency)                     ' │  XTAL3   │   32  │   5  │      
    else                                                                                                   '  Else                                                                               ' │  XTAL2   │   16  │   4  │      
      clkset(Mode & $78 | clkmode & $07, clkfreq)                                                          '    Rev up the oscillator and PLL circuits first                                     ' │  XTAL1   │    8  │   3  │      
      waitcnt(clkfreq / 50 + cnt)                                                                         '    Wait 10 ms for them to stabilize                                                 ' │  XINPUT  │    4  │   2  │      
      clkset(Mode, NewFreq)                                                                                '    Then switch to external clock (and set new frequency)                            ' │  RCSLOW  │    2  │   1  │      
                                                                                                                                                                                                 ' │  RCFAST  │    1  │   0  │      
  NewFreq := clkfreq                                                                                       'Return clock frequency                                                               ' └──────────┴───────┴──────┘      
                                                                                                                                                                                         
PRI Valid(Mode): YesNo
{Returns True if Mode (combined with XINFreq)
is a valid clock mode, False otherwise.}

  YesNo := OneBit(Mode & $03F) and OneBit(Mode & $7C3) and not ((Mode & $7C0) and not (Mode & $3C)) and not ((XINFreq == 0) and (Mode & $3C <> 0))
  

PRI OneBit(Bits): YesNo
{Returns True if Bits has less than 2 bits
set, False otherwise. This is a "mutually-
exclusive" test; if any bit is set, all
other bits must be clear or the test fails.
}

  YesNo := Bits == |< >| Bits >> 1

DAT                                           

{{
file:      Propeller Board of Education.spin
Date:      2012.01.30
Version:   0.31
Authors:   Clock method - Andy Lindsay
           All other methods were copied from
           Jeff Martin's Clock object, which
           is in the Propeller Tool
           software's Propeller Library.
Copyright: (c) 2012 Parallax Inc. 

┌────────────────────────────────────────────┐
│TERMS OF USE: MIT License                   │
├────────────────────────────────────────────┤
│Permission is hereby granted, free of       │
│charge, to any person obtaining a copy      │
│of this software and associated             │
│documentation files (the "Software"),       │
│to deal in the Software without             │
│restriction, including without limitation   │
│the rights to use, copy, modify, merge,     │
│publish, distribute, sublicense, and/or     │
│sell copies of the Software, and to permit  │
│persons to whom the Software is furnished   │
│to do so, subject to the following          │
│conditions:                                 │
│                                            │
│The above copyright notice and this         │
│permission notice shall be included in all  │
│copies or substantial portions of the       │
│Software.                                   │
│                                            │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT   │
│WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,   │
│INCLUDING BUT NOT LIMITED TO THE WARRANTIES │
│OF MERCHANTABILITY, FITNESS FOR A           │
│PARTICULAR PURPOSE AND NONINFRINGEMENT. IN  │
│NO EVENT SHALL THE AUTHORS OR COPYRIGHT     │
│HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR │
│OTHER LIABILITY, WHETHER IN AN ACTION OF    │
│CONTRACT, TORT OR OTHERWISE, ARISING FROM,  │
│OUT OF OR IN CONNECTION WITH THE SOFTWARE   │
│OR THE USE OR OTHER DEALINGS IN THE         │
│SOFTWARE.                                   │
└────────────────────────────────────────────┘
}}  
  