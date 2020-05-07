{
    --------------------------------------------
    Filename: NRF24L01-Speedtest-RX.spin
    Author: Jesse Burt
    Description: Speed test for nRF24L01+ modules
        RX Mode
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

    cfg         : "core.con.boardcfg.quickstart-hib"
    ser         : "com.serial.terminal.ansi"
    time        : "time"
    io          : "io"
    nrf24       : "wireless.transceiver.nrf24l01.spi"
    int         : "string.integer"

VAR

    long _ctr_stack[50]
    long _iteration, _timer_set
    byte _ser_cog, _nrf24_cog

PUB Main | i, fifo[PKTLEN/4], iteration, testtime

    Setup
    testtime := 1_000
    repeat
        _timer_set := testtime
        iteration := 0

        repeat while _timer_set
            repeat until nrf24.PayloadReady(-2)
            nrf24.PayloadReady(CLEAR)
            nrf24.RXPayload(PKTLEN, @fifo)
            iteration++

        ser.position(0, 3)
        Report(testtime, iteration)

PUB RXSetup | addr[2]

    nrf24.AddressWidth(5)
    addr := string($E7, $E7, $E7, $E7, $E7)
    nrf24.RXAddr (addr, 0, nrf24#WRITE)

    nrf24.Channel(CHANNEL)
    nrf24.RXMode
    nrf24.FlushRX
    nrf24.CRCCheckEnabled(TRUE)
    nrf24.DataRate(2000)
    nrf24.TXPower(-18)
    nrf24.PipesEnabled(%000001)
    nrf24.AutoAckEnabledPipes(%000000)
    nrf24.Powered (TRUE)
    nrf24.PayloadLen (PKTLEN, 0)

PUB cog_Counter | time_left

    repeat until _ser_cog := ser.StartRXTX (SER_RX, SER_TX, 0, SER_BAUD)
    ser.clear
    ser.str(string("Serial terminal started (P2 @"))
    ser.dec(clkfreq / 1_000_000)
    ser.str(string("MHz", ser#CR, ser#LF))
    repeat until _nrf24_cog
    ser.str(string("nRF24L01+ driver started", ser#CR, ser#LF))

    repeat
        repeat until _timer_set
        time_left := _timer_set

        repeat
            time_left--
            time.MSleep(1)
        while time_left > 0
        _timer_set := 0

PRI Report(testtime, iterations) | rate_iterations, rate_bytes, rate_kbits

    rate_iterations := iterations / (testtime/1000)
    rate_bytes := (iterations * PKTLEN) / (testtime/1000)
    rate_kbits := (rate_bytes * 8) / 1024

    ser.str(string("Total iterations: "))
    ser.dec(iterations)
    ser.str(string(", iterations/sec: "))
    ser.dec(rate_iterations)
    ser.str(string(", Bps: "))
    ser.dec(rate_bytes)
    ser.str(string(" ("))
    ser.dec(rate_kbits)
    ser.str(string("kbps)"))
    ser.ClearLine(ser#CLR_CUR_TO_END)

PRI Decimal(scaled, divisor) | whole[4], part[4], places, tmp
' Display a fixed-point scaled up number in decimal-dot notation - scale it back down by divisor
'   e.g., Decimal (314159, 100000) would display 3.14159 on the termainl
'   scaled: Fixed-point scaled up number
'   divisor: Divide scaled-up number by this amount
    whole := scaled / divisor
    tmp := divisor
    places := 0

    repeat
        tmp /= 10
        places++
    until tmp == 1
    part := int.DecZeroed(||(scaled // divisor), places)

    ser.Dec (whole)
    ser.Char (".")
    ser.Str (part)

PUB Setup

    cognew(cog_Counter, @_ctr_stack)

    _nrf24_cog := nrf24.Startx (CE_PIN, CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN)

    RXSetup

#include "lib.utility.spin"
