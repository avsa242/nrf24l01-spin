{
    --------------------------------------------
    Filename: NRF24L01-PacketLoss-RX.spin
    Author: Jesse Burt 
    Description: nRF24L01+ Receive demo
        * Packet loss measurement
        Run NRF24L01-PacketLoss-TX.spin on another node, and monitor this node
            for packet loss.
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
    time:   "time"

PUB main{} | rxcnt, pkt_cnt, prev_cnt, diff, pkts_lost

    ser.start(SER_BAUD)
    time.msleep(30)
    ifnot ( radio.start() )
        ser.strln(string("NRF24L01 driver failed to start"))
        { double-check I/O pins if the driver doesn't start }
        repeat

    radio.preset_rx2m{}                         ' set up for defaults, 2Mbps speed
    radio.payld_len(PAYLD_LEN)                  ' expect to receive PAYLD_LEN number of bytes

    ser.clear{}

    pkts_lost := 0
    rxcnt := prev_cnt := 0

    repeat
        ser.pos_xy(0, 0)
        ser.printf2(string("Packets received: %5.5d    lost: %5.5d"), rxcnt, pkts_lost)

        repeat until radio.payld_rdy{}
        radio.rx_payld(PAYLD_LEN, @pkt_cnt)
        rxcnt++

        { if the serial number of this packet is less than the previous one,
            assume the transmitter restarted, and reset the counters }
        if (pkt_cnt < prev_cnt)
            prev_cnt := pkt_cnt
            pkts_lost := 0
            rxcnt := 0

        { if the serial number of this packet is different by more than 1,
            we know we missed one or more packets }
        diff := (pkt_cnt-prev_cnt)
        prev_cnt := pkt_cnt
        if (diff > 1)
            pkts_lost := (pkts_lost + diff)

        { clear interrupt so RX can continue }
        radio.int_clear(radio#INT_PAYLD_RDY)

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

