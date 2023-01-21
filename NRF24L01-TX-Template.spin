{
    --------------------------------------------
    Filename: NRF24L01-TX-Template.spin
    Author: 
    Description: NRF24L01 Transmit code template
        To use: Copy this file into a new file to use as a basis for a nRF24L01+
            transmit application.
    Copyright (c) YYYY
    Started MMM DD, YYYY
    Updated MMM DD, YYYY
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    { SPI configuration }
    CE_PIN      = 0
    CS_PIN      = 1
    SCK_PIN     = 2
    MOSI_PIN    = 3
    MISO_PIN    = 4
' --

    PAYLD_LEN   = 8

OBJ

    ser:    "com.serial.terminal.ansi"
    cfg:    "boardcfg.flip"
    nrf24:  "wireless.transceiver.nrf24l01"
    time:   "time"
    str:    "string"

VAR

    byte _payload[PAYLD_LEN]

PUB main{}

    setup{}

    ' your transmit code here

    repeat

PUB setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ifnot (nrf24.startx(CE_PIN, CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN))
        ser.strln(@"NRF24L01 driver failed to start")
        { double-check I/O pins if the driver doesn't start }
        repeat

    nrf24.preset_tx2m{}                         ' set up for defaults, TX, 2Mbps speed
    nrf24.payld_len(PAYLD_LEN)                  ' expect to receive PAYLD_LEN number of bytes

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

