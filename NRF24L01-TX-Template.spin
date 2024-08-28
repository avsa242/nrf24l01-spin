{
----------------------------------------------------------------------------------------------------
    Filename:       NRF24L01-TX-Template.spin
    Description:    NRF24L01 Transmit code template
        To use: Copy this file into a new file to use as a basis for a nRF24L01+
            transmit application.
    Author:         ____________
    Started:        MMM DD, YYYY
    Updated:        MMM DD, YYYY
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

CON

    _clkmode    = xtal1+pll16x
    _xinfreq    = 5_000_000

' -- User-modifiable constants
    PAYLD_LEN   = 8                             ' 1..32
' --


OBJ

    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    radio:  "wireless.transceiver.nrf24l01" | CE=0, CS=1, SCK=2, MOSI=3, MISO=4
    time:   "time"


VAR

    byte _payload[PAYLD_LEN]


PUB main()

    setup()

    ' your transmit code here

    repeat


PUB setup()

    ser.start()
    time.msleep(30)
    ser.clear()

    ifnot ( radio.start() )
        ser.strln(@"NRF24L01 driver failed to start")
        { double-check I/O pins if the driver doesn't start }
        repeat

    radio.preset_tx2m()                         ' set up for defaults, TX, 2Mbps speed
    radio.payld_len(PAYLD_LEN)                  ' set data/payload size to PAYLD_LEN number of bytes


DAT
{
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

