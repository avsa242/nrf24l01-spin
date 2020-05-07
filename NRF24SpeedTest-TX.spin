{
    --------------------------------------------
    Filename: NRF24Speedtest-TX.spin
    Author: Jesse Burt
    Description: Speed test for nRF24L01+ modules
        TX Mode
    Copyright (c) 2020
    Started Apr 30, 2020
    Updated May 7, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' User-modifiable constants
    LED         = cfg#LED1
    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200

    CE_PIN      = 0
    CS_PIN      = 1
    SCK_PIN     = 2
    MOSI_PIN    = 3
    MISO_PIN    = 5

    PKTLEN      = 32

    CLEAR       = 1
    CHANNEL     = 2

OBJ

    cfg     : "core.con.boardcfg.demoboard"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    io      : "io"
    nrf24   : "wireless.transceiver.nrf24l01.spi"

VAR

    byte _ser_cog, _nrf24_cog

PUB Main | fifo[PKTLEN/4], i

    Setup

    repeat i from 0 to PKTLEN-1
        fifo.byte[i] := 32+i

    repeat
        nrf24.TXPayload (PKTLEN, @fifo, FALSE)

PUB TXSetup | addr[2], i

    nrf24.AddressWidth(5)
    addr := string($E7, $E7, $E7, $E7, $E7)
    nrf24.TXAddr(addr, nrf24#WRITE)

    nrf24.Channel(CHANNEL)
    nrf24.TXMode
    nrf24.FlushTX
    nrf24.CRCCheckEnabled(TRUE)
    nrf24.DataRate(2000)
    nrf24.TXPower(-18)
    nrf24.PipesEnabled(%000001)
    nrf24.AutoAckEnabledPipes(%000000)
    nrf24.Powered (TRUE)
    nrf24.PayloadLen (PKTLEN, 0)

PUB Setup

    repeat until _ser_cog := ser.Start (115_200)
    time.MSleep(30)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#CR, ser#LF))

    if _nrf24_cog := nrf24.Startx (CE_PIN, CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN)
        ser.str(string("NRF24L01+ driver started", ser#CR, ser#LF))
    else
        ser.str(string("NRF24L01+ driver failed to start - halting", ser#CR, ser#LF))
        FlashLED (LED, 500)

    TXSetup

#include "lib.utility.spin"

DAT
{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}
