{
    --------------------------------------------
    Filename: NRF24L01-SpeedTest-TX.spin
    Author: Jesse Burt
    Description: Speed test for nRF24L01+ modules
        TX Mode
    Copyright (c) 2023
    Started Apr 30, 2020
    Updated Dec 31, 2023
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    PKTLEN      = 32                            ' 1..32 (bytes)
    CHANNEL     = 2                             ' 0..125 (2.400..2.525GHz)
' --

    CLEAR       = 1

OBJ

    cfg:    "boardcfg.flip"
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    time:   "time"
    nrf24:  "wireless.transceiver.nrf24l01" | CE=0, CS=1, SCK=2, MOSI=3, MISO=4

VAR

    byte _txdata[PKTLEN]
    byte _syncwd[5]

PUB main{} | i

    setup{}

    bytemove(@_syncwd, string($E7, $E7, $E7, $E7, $E7), 5)
    nrf24.set_syncwd(@_syncwd)                  ' set syncword

    nrf24.channel(CHANNEL)
    nrf24.tx_mode{}
    nrf24.powered(true)
    nrf24.set_pipe_nr(0)
    nrf24.payld_len(PKTLEN)                     ' set pipe 0 to 32 bytes width

' Experiment with these to observe effect on throughput
'   NOTE: The receiver's settings _must_ match these (except tx_pwr())
    nrf24.data_rate(2_000_000)                  ' 250_000, 1_000_000, 2_000_000
    nrf24.auto_ack_pipes_ena(%000011)           ' pipe mask [5..0]
    nrf24.tx_pwr(0)                             ' -18, -12, -6, 0 (dBm)
    nrf24.crc_check_ena(true)                   ' ignored (always on) if auto-ack is used
    nrf24.crc_len(1)                            ' 1, 2 bytes

    repeat i from 0 to PKTLEN-1                 ' fill transmit buffer with
        _txdata.byte[i] := 32+i                 ' ASCII 32..32+(PKTLEN-1)

    ser.pos_xy(0, 3)
    ser.str(string("Transmitting "))
    ser.dec(PKTLEN)
    ser.str(string(" byte payloads to "))
    repeat i from 0 to 4                        ' show the syncword
        ser.hex(_syncwd[i], 2)
    ser.newline{}

    nrf24.flush_tx{}
    if (nrf24.auto_ack_pipes_ena(-2))           ' decide which loop to run
        repeat                                  ' based on whether auto-ack
            if (nrf24.max_retrans_reached{})    ' is enabled...
                nrf24.int_clear(%001)
            nrf24.tx_payld(PKTLEN, @_txdata)
    else                                        ' ...or not
        repeat
            nrf24.tx_payld(PKTLEN, @_txdata)

PUB setup{}

    ser.start()
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    if ( nrf24.start() )
        ser.strln(string("NRF24L01+ driver started"))
    else
        ser.strln(string("NRF24L01+ driver failed to start - halting"))
        repeat

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

