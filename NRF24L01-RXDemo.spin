{
    --------------------------------------------
    Filename: NRF24L01-RXDemo.spin
    Author: Jesse Burt 
    Description: nRF24L01+ Receive demo
        Will display data from all 6 data pipes
    Copyright (c) 2023
    Started Nov 23, 2019
    Updated Dec 31, 2023
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    CHANNEL     = 2                             ' 0..125
' --

OBJ

    cfg:    "boardcfg.flip"
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    nrf24:  "wireless.transceiver.nrf24l01" | CE=0, CS=1, SCK=2, MOSI=3, MISO=4
    time:   "time"

VAR

    byte _payload[32]
    byte _payld_len
    byte _syncwd[5]

PUB main{} | payld_cnt, recv_pipe, pipe_nr

    setup{}                                     ' start serial term. and nRF24

' -- User-modifiable settings (NOTE: These settings _must_ match the transmit side) }
    nrf24.channel(CHANNEL)

    _payld_len := 8                             ' 1..32

    { set syncword (note: order in string() is LSB, ..., MSB) }
    nrf24.set_pipe_nr(0)
    nrf24.set_syncwd(string($e7, $e7, $e7, $e7, $e7))

    ' choose a receive mode preset (250kbps, 1Mbps, 2Mbps)
    '   with optional Auto-Ack/ShockBurst  (power-on default)
'    nrf24.preset_rx250k{}                       ' 250kbps
'    nrf24.preset_rx250k_noaa{}                  ' 250kbps, No Auto-Ack
'    nrf24.preset_1m{}                           ' 1Mbps
'    nrf24.preset_1m_noaa{}                      ' 1Mbps, No Auto-Ack
    nrf24.preset_rx2m{}                         ' 2Mbps
'    nrf24.preset_rx2m_noaa{}                    ' 2Mbps, No Auto-Ack
' --

    { set all pipes to the same payload length }
    repeat pipe_nr from 0 to 5
        nrf24.set_pipe_nr(pipe_nr)
        nrf24.payld_len(_payld_len)

    ser.clear{}
    ser.pos_xy(0, 0)
    ser.printf1(string("Receive mode (channel %d)\n\r"), nrf24.channel(-2))
    ser.strln(string("Listening for transmitters..."))

    payld_cnt := 0
    repeat
        { clear local buffer and wait until a payload is received }
        bytefill(@_payload, 0, 32)
        repeat
            ser.pos_xy(0, 3)
            ser.printf1(string("Payloads received: %d "), payld_cnt)
        until nrf24.payld_rdy{}

        { check which pipe the data was received in and retrieve the payload into local buffer }
        recv_pipe := nrf24.rx_pipe_pending{}
        nrf24.syncwd(@_syncwd)
        nrf24.rx_payld(_payld_len, @_payload)
        payld_cnt++

        { display payload received through each pipe number on a separate line }
        ser.pos_xy(0, 5 + (recv_pipe * 4))
        ser.printf1(string("Received packet on pipe %d "), recv_pipe)
        ser.printf5(string("(%02.2x:%02.2x:%02.2x:%02.2x:%02.2x)\n\r"), {
}       _syncwd[4], _syncwd[3], _syncwd[2], _syncwd[1], _syncwd[0])
        ser.hexdump(@_payload, 0, 4, _payld_len, _payld_len)

        { clear interrupt and receive buffer for next loop }
        nrf24.int_clear(nrf24#INT_PAYLD_RDY)
        nrf24.flush_rx{}

PUB setup{}

    ser.start()
    time.msleep(30)
    if ( nrf24.start() )
        ser.strln(string("nRF24L01+ driver started"))
    else
        ser.strln(string("nRF24L01+ driver failed to start - halting"))
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

