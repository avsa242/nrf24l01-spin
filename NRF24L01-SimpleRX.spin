{
    --------------------------------------------
    Filename: NRF24L01-SimpleRX.spin
    Author: Jesse Burt 
    Description: nRF24L01+ Receive demo
        * Minimal receive functionality demo code
    Copyright (c) 2023
    Started Jan 5, 2023
    Updated Jul 17, 2023
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    SER_BAUD    = 115_200
' --

    PAYLD_LEN   = 8

OBJ

    ser:    "com.serial.terminal.ansi"
    cfg:    "boardcfg.flip"
    nrf24:  "wireless.transceiver.nrf24l01" | CE=0, CS=1, SCK=2, MOSI=3, MISO=4
    time:   "time"

VAR

    byte _payload[PAYLD_LEN]

PUB main{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ifnot ( nrf24.start() )
        ser.strln(@"NRF24L01 driver failed to start")
        { double-check I/O pins if the driver doesn't start }
        repeat

    nrf24.preset_rx2m{}                         ' set up for defaults, 2Mbps speed
    nrf24.payld_len(PAYLD_LEN)                  ' expect to receive PAYLD_LEN number of bytes

    ser.clear{}

    repeat
        repeat until nrf24.payld_rdy{}
        nrf24.rx_payld(PAYLD_LEN, @_payload)
        ser.printf1(@"Received: %s\n\r", @_payload)

        { clear interrupt so RX can continue }
        nrf24.int_clear(nrf24#INT_PAYLD_RDY)

DAT
{
Copyright 2023 Jesse Burt

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

