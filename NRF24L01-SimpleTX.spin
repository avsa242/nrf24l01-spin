{
    --------------------------------------------
    Filename: NRF24L01-SimpleTX.spin
    Author: Jesse Burt
    Description: nRF24L01+ Transmit demo
        * Minimal transmit functionality demo code
    Copyright (c) 2023
    Started Jan 5, 2023
    Updated Jan 5, 2023
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

    ser  : "com.serial.terminal.ansi"
    cfg  : "boardcfg.flip"
    nrf24: "wireless.transceiver.nrf24l01"
    str  : "string"
    time : "time"

VAR

    byte _payload[PAYLD_LEN]

PUB main{} | payld_cnt

    ser.start(SER_BAUD)
    ifnot (nrf24.startx(CE_PIN, CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN))
        ser.strln(@"NRF24L01 driver failed to start")
        repeat

    nrf24.preset_tx2m{}                         ' set up for defaults, 2Mbps speed
    nrf24.payld_len(PAYLD_LEN)                  ' send PAYLD_LEN number of bytes

    ser.clear{}

    payld_cnt := 0
    repeat
        { payload to transmit }
        str.sprintf1(@_payload, @"TEST%04.4d", payld_cnt++)
        nrf24.tx_payld(PAYLD_LEN, @_payload)

        { clear interrupt so TX can continue }
        nrf24.int_clear(nrf24.INT_MAX_RETRANS)
        time.msleep(10)

DAT
{
Copyright 2022 Jesse Burt

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
