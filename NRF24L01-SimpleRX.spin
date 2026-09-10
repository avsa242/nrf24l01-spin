{
----------------------------------------------------------------------------------------------------
    Filename:       NRF24L01-SimpleRX.spin
    Description:    nRF24L01+ Receive demo
        * Minimal receive functionality demo code
    Author:         Jesse Burt
    Started:        Jan 5, 2023
    Updated:        Sep 10, 2026
    Copyright (c) 2026 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

CON

    _clkmode    = xtal1+pll16x
    _xinfreq    = 5_000_000

    PAYLD_LEN   = 8
    NRF_INT_PIN = 14


OBJ

    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    radio:  "wireless.transceiver.nrf24l01" | CE=1, CS=2, SCK=3, MOSI=4, MISO=5
    time:   "time"


VAR

    byte _payload[PAYLD_LEN]


PUB main()

    ser.start()
    time.msleep(30)
    ifnot ( radio.start() )
        ser.strln(@"NRF24L01 driver failed to start")
        { double-check I/O pins if the driver doesn't start }
        repeat

    radio.preset_rx2m()                         ' set up for defaults, 2Mbps speed
    radio.payld_len(PAYLD_LEN)                  ' expect to receive PAYLD_LEN number of bytes
    radio.int_mask(radio.INT_PAYLD_RDY)         ' assert interrupt when payload is received
    ser.clear()

'{  ' Register polling method
    repeat
        repeat
        until radio.payld_rdy()
        radio.rx_payld(PAYLD_LEN, @_payload)
        ser.printf(@"Received: %s\n\r", @_payload)

        ' clear interrupt so RX can continue
        radio.int_clear(radio.INT_PAYLD_RDY)
'}

{   ' Interrupt pin polling method
    dira[NRF_INT_PIN] := 0                      ' interrupt pin: input
    radio.int_mask(radio.INT_PAYLD_RDY)         ' assert interrupt when payload is received
    repeat
        repeat
        until ina[NRF_INT_PIN] == 0             ' wait for nRF24 interrupt (active low)
        radio.rx_payld(PAYLD_LEN, @_payload)
        ser.printf(@"Received: %s\n\r", @_payload)

        ' clear interrupt so RX can continue
        radio.int_clear(radio.INT_PAYLD_RDY)
}


DAT
{
Copyright 2026 Jesse Burt

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

