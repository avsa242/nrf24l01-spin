{
----------------------------------------------------------------------------------------------------
    Filename:       NRF24L01-SimpleTX.spin
    Description:    nRF24L01+ Transmit demo
        * Minimal transmit functionality demo code
    Author:         Jesse Burt
    Started:        Jan 5, 2023
    Updated:        Aug 26, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

CON

    _clkmode    = xtal1+pll16x
    _xinfreq    = 5_000_000

    PAYLD_LEN   = 8


OBJ

    str:    "string"
    time:   "time"
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    radio:  "wireless.transceiver.nrf24l01" | CE=0, CS=1, SCK=2, MOSI=4, MISO=3


VAR

    byte _payload[PAYLD_LEN]


PUB main() | payld_cnt, s

    ser.start()
    time.msleep(30)
    ser.clear()
    ifnot ( radio.start() )
        ser.strln(@"NRF24L01 driver failed to start")
        repeat

    radio.preset_tx2m_noaa()                         ' set up for defaults, 2Mbps speed
    radio.payld_len(PAYLD_LEN)                  ' send PAYLD_LEN number of bytes

    ser.clear()

    payld_cnt := 0
    radio.int_mask(radio.INT_PAYLD_SENT|radio.INT_MAX_RETRANS)'radio.INT_PAYLD_SENT)
    radio.int_clear(radio.INT_PAYLD_SENT|radio.INT_MAX_RETRANS)'radio.INT_PAYLD_SENT)

    ser.printf1(@"int=%032.32b\n\r", radio.int_mask())
'    repeat
    dira[6] := 0
    repeat
        { payload to transmit }
        str.sprintf1(@_payload, @"TEST%04.4d", payld_cnt++)
        radio.tx_payld(PAYLD_LEN, @_payload)

        { clear interrupt so TX can continue }
        'repeat until radio.payld_sent()
        repeat until not ina[6]
        radio.int_clear(radio.INT_MAX_RETRANS)
        time.msleep(10)


DAT
{
Copyright 2024 Jesse Burt

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

