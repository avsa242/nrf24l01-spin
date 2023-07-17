{
    --------------------------------------------
    Filename: NRF24L01-PacketLoss-TX.spin
    Author: Jesse Burt
    Description: nRF24L01+ Transmit demo
        * Packet loss measurement
        Run this transmitter on one node, and monitor the receiving node
        for packet loss with NRF24L01-PacketLoss-RX.spin.
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

    PAYLD_LEN   = 2

OBJ

    ser:    "com.serial.terminal.ansi"
    cfg:    "boardcfg.flip"
    radio:  "wireless.transceiver.nrf24l01" | CE=0, CS=1, SCK=2, MOSI=3, MISO=4
    str:    "string"
    time:   "time"

PUB main{} | payld_cnt

    ser.start(SER_BAUD)
    time.msleep(30)
    ifnot ( radio.start() )
        ser.strln(@"NRF24L01 driver failed to start")
        repeat

    radio.preset_tx2m{}                         ' set up for defaults, 2Mbps speed
    radio.payld_len(PAYLD_LEN)                  ' send PAYLD_LEN number of bytes
    ser.clear{}

    payld_cnt := 0
    repeat
        ser.pos_xy(0, 0)
        ser.printf1(string("Packets transmitted: %5.5d"), payld_cnt)

        { payload to transmit }
        radio.tx_payld(PAYLD_LEN, @payld_cnt)
        payld_cnt++

        { clear interrupt so TX can continue }
        radio.int_clear(radio.INT_MAX_RETRANS)
        time.msleep(100)

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

