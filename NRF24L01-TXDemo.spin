{
    --------------------------------------------
    Filename: NRF24L01-TXDemo.spin
    Author: Jesse Burt
    Description: nRF24L01+ Transmit demo
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
    str:    "string"
    time:   "time"

VAR

    byte _payload[32]
    byte _payld_len
    byte _syncwd[5]

PUB main{} | payld_cnt, max_retrans, pkts_retrans, lost_pkts

    setup{}                                     ' start serial term. and nRF24
    longfill(@payld_cnt, 0, 4)                  ' init vars to 0

' -- User-modifiable settings (NOTE: These settings _must_ match the receive side) }
    nrf24.channel(CHANNEL)

    ' choose a transmit mode preset (250kbps, 1Mbps, 2Mbps)
    '   with optional Auto-Ack/ShockBurst (power-on default)
'    nrf24.preset_tx250k{}                       ' 250kbps
'    nrf24.preset_tx250k_noaa{}                  ' 250kbps, no Auto-Ack
'    nrf24.preset_tx1m{}                         ' 1Mbps
'    nrf24.preset_tx1m_noaa{}                    ' 1Mbps, no Auto-Ack
    nrf24.preset_tx2m{}                         ' 2Mbps
'    nrf24.preset_tx2m_noaa{}                    ' 2Mbps, no Auto-Ack

    nrf24.tx_pwr(0)                             ' -18, -12, -6, 0 (dBm)

    _payld_len := 8                             ' 1..32

    { set syncword (note: order in string() is LSB, ..., MSB) }
    nrf24.set_syncwd(string($e7, $e7, $e7, $e7, $e7))

' --

    nrf24.set_pipe_nr(0)
    nrf24.payld_len(_payld_len)
    nrf24.syncwd(@_syncwd)

    ser.clear{}
    ser.pos_xy(0, 0)
    ser.printf1(string("Transmit mode (channel %d)\n\r"), nrf24.channel(-2))

    repeat
        { payload to transmit }
        str.sprintf1(@_payload, string("TEST%04.4d"), payld_cnt++)

        { collect and display some packet statistics }
        max_retrans := nrf24.max_retrans_reached{}
        pkts_retrans := nrf24.pkts_retrans{}
        lost_pkts := nrf24.lost_pkts{}
        ser.pos_xy(0, 2)
        ser.str(string("Max retransmissions reached? "))
        ser.strln(lookupz(||(max_retrans): string("No "), string("Yes")))
        ser.printf1(string("Packets retransmitted: %2.2d\n\r"), pkts_retrans)
        ser.printf1(string("Lost packets: %2.2d\n\r"), lost_pkts)

        { display payload and transmit it }
        ser.pos_xy(0, 6)
        ser.printf5(string("Transmitting packet (to %02.2x:%02.2x:%02.2x:%02.2x:%02.2x)\n\r"), ...
                        _syncwd[4], _syncwd[3], _syncwd[2], _syncwd[1], _syncwd[0])
        ser.hexdump(@_payload, 0, 4, _payld_len, 16 <# _payld_len)
        nrf24.tx_payld(_payld_len, @_payload)

        { check for transmission error limits and clear them so transmission can continue }
        if (max_retrans)
            nrf24.int_clear(nrf24#INT_MAX_RETRANS)
        if (lost_pkts => 15)
            nrf24.channel(CHANNEL)

        { optional delay between transmissions - use as necessary to avoid abuse of the airwaves }
        time.msleep(1000)

PUB setup{}

    ser.start()
    time.msleep(30)
    ser.clear()

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

