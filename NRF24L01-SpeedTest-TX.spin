{
    --------------------------------------------
    Filename: NRF24L01-SpeedTest-TX.spin
    Author: Jesse Burt
    Description: Speed test for nRF24L01+ modules
        TX Mode
    Copyright (c) 2020
    Started Apr 30, 2020
    Updated Oct 19, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    CE_PIN      = 8
    CS_PIN      = 9
    SCK_PIN     = 10
    MOSI_PIN    = 11
    MISO_PIN    = 12

    PKTLEN      = 32                            ' 1..32 (bytes)
    CHANNEL     = 2                             ' 0..125 (2.400..2.525GHz)
' --

    CLEAR       = 1

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    nrf24   : "wireless.transceiver.nrf24l01.spi"

VAR

    byte _txdata[PKTLEN]
    byte _addr[5]

PUB Main{} | i

    setup{}

    bytemove(@_addr, string($E7, $E7, $E7, $E7, $E7), 5)
    nrf24.nodeaddress(@_addr)                   ' set transmitter address

    nrf24.channel(CHANNEL)
    nrf24.txmode{}
    nrf24.powered(true)
    nrf24.payloadlen(PKTLEN, 0)                 ' set pipe 0 to 32 bytes width

' Experiment with these to observe effect on throughput
'   NOTE: The receiver's settings _must_ match these (except txpower())
    nrf24.datarate(2000)                        ' 250, 1000, 2000 (kbits/sec)
    nrf24.txpower(0)                            ' -18, -12, -6, 0 (dBm)
    nrf24.crccheckenabled(true)
    nrf24.crclength(1)                          ' 1, 2 bytes
    nrf24.autoackenabledpipes(%000011)          ' pipe mask [5..0]

    repeat i from 0 to PKTLEN-1                 ' fill transmit buffer with
        _txdata.byte[i] := 32+i                 ' ASCII 32..32+(PKTLEN-1)

    ser.position(0, 3)
    ser.str(string("Transmitting "))
    ser.dec(PKTLEN)
    ser.str(string(" byte payloads to "))
    repeat i from 0 to 4                        ' show the address being
        ser.hex(_addr[i], 2)                    ' transmitted to
    ser.newline

    nrf24.flushtx{}
    if nrf24.autoackenabledpipes(-2)            ' decide which loop to run
        repeat                                  ' based on whether auto-ack
            if nrf24.maxretransreached{}        ' is enabled...
                nrf24.intclear(%001)
            nrf24.txpayload(PKTLEN, @_txdata)
    else                                        ' ...or not
        repeat
            nrf24.txpayload(PKTLEN, @_txdata)

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    if nrf24.startx(CE_PIN, CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN)
        ser.strln(string("NRF24L01+ driver started"))
    else
        ser.strln(string("NRF24L01+ driver failed to start - halting"))
        repeat

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
