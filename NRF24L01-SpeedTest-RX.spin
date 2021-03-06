{
    --------------------------------------------
    Filename: NRF24L01-SpeedTest-RX.spin
    Author: Jesse Burt
    Description: Speed test for nRF24L01+ modules
        RX Mode
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

    cfg         : "core.con.boardcfg.flip"
    ser         : "com.serial.terminal.ansi"
    time        : "time"
    nrf24       : "wireless.transceiver.nrf24l01.spi"

VAR

    long _ctr_stack[50]
    long _iteration, _timer_set
    byte _rxdata[PKTLEN]
    byte _addr[5]

PUB Main{} | i, iteration, testtime, pipe_nr

    setup{}
    testtime := 1_000                           ' mSec

    bytemove(@_addr, string($E7, $E7, $E7, $E7, $E7), 5)
    nrf24.rxaddr(@_addr, 0, nrf24#WRITE)        ' set receiver address

    nrf24.powered(true)
    nrf24.channel(CHANNEL)
    nrf24.rxmode{}

' Experiment with these to observe effect on throughput
'   NOTE: The transmitter's settings _must_ match these
    nrf24.datarate(2000)                        ' 250, 1000, 2000
    nrf24.autoackenabledpipes(%000011)
    nrf24.txpower(0)                            ' -18, -12, -6, 0 (dBm)
                                                ' (for auto-ack, if enabled)
    nrf24.crccheckenabled(true)
    nrf24.crclength(1)                          ' 1, 2 (bytes)

    repeat pipe_nr from 0 to 5                  ' set pipe payload sizes
        nrf24.payloadlen(PKTLEN, pipe_nr)       ' _must_ match TX

    ser.position(0, 4)
    ser.str(string("Waiting for transmitters on "))
    repeat i from 4 to 0                        ' show address receiving on
        ser.hex(_addr[i], 2)
    ser.newline

    nrf24.flushrx{}                             ' clear rx fifo
    nrf24.intclear(%100)                        ' clear interrupt
    repeat
        iteration := 0
        _timer_set := testtime                  ' trigger the timer

        repeat while _timer_set                 ' loop while timer is >0
            repeat until nrf24.payloadready{}   ' wait for rx data
            nrf24.intclear(%100)                ' _must_ clear interrupt
            nrf24.rxpayload(PKTLEN, @_rxdata)   ' retrieve payload
            iteration++                         ' tally up # payloads rx'd

        ser.position(0, 6)
        report(testtime, iteration)             ' show the results

PUB cog_Counter | time_left

    repeat
        repeat until _timer_set                 ' wait for trigger
        time_left := _timer_set

        repeat                                  ' ~1ms loop
            time_left--
            time.msleep(1)
        while time_left > 0
        _timer_set := 0

PRI Report(testtime, iterations) | rate_iterations, rate_bytes, rate_kbits

    rate_iterations := iterations / (testtime/1000)         ' # payloads/sec
    rate_bytes := (iterations * PKTLEN) / (testtime/1000)   ' # bytes/sec
    rate_kbits := (rate_bytes * 8) / 1024                   ' # kbits/sec

    ser.str(string("Total iterations: "))
    ser.dec(iterations)
    ser.str(string(", iterations/sec: "))
    ser.dec(rate_iterations)
    ser.str(string(", Bps: "))
    ser.dec(rate_bytes)
    ser.str(string(" ("))
    ser.dec(rate_kbits)
    ser.str(string("kbps)"))
    ser.clearline{}

PUB Setup

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear
    ser.strln(string("Serial terminal started"))

    if nrf24.startx(CE_PIN, CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN)
        ser.strln(string("nRF24L01+ driver started"))
    else
        ser.strln(string("nRF24L01+ driver failed to start - halting"))
        repeat

    cognew(cog_Counter, @_ctr_stack)

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
