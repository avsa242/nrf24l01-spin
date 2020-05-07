{                                                                                                                
    --------------------------------------------
    Filename: NRF24L01-RXWithAA-PST.spin
    Author: Jesse Burt 
    Description: nRF24L01+ Receive demo that uses the radio's
        auto-acknowledge function (Enhanced ShockBurst - (TM) Nordic Semi)
        Will display data from all 5 data pipes
        Propeller Tool-compatible version
    Copyright (c) 2020
    Started Feb 6, 2020
    Updated May 7, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode        = cfg#_clkmode
    _xinfreq        = cfg#_xinfreq

    LED             = cfg#LED1
    SER_RX          = 31
    SER_TX          = 30
    SER_BAUD        = 115_200

    CE_PIN          = 0
    CSN_PIN         = 1
    SCK_PIN         = 2
    MOSI_PIN        = 3
    MISO_PIN        = 5

    CLEAR           = 1
    CHANNEL         = 2

OBJ

    ser         : "com.serial.terminal"
    cfg         : "core.con.boardcfg.flip"
    io          : "io"
    time        : "time"
    int         : "string.integer"
    nrf24       : "wireless.transceiver.nrf24l01.spi"

VAR

    long _ser_cog, _nrf24_cog
    long _fifo[2]
    byte _pktlen

PUB Main | choice

    Setup

    nrf24.Channel(CHANNEL)
    ser.str(string("Press any key to begin receiving", ser#NL, ser#LF))
    ser.CharIn

    Receive

    FlashLED(LED, 100)

PUB Receive | tmp, from_node, addr[2], i, count, recv_pipe

    _pktlen := 8

    nrf24.AddressWidth(5)                                   ' Configure for 5-byte long addresses   

    addr := string($E7, $E7, $E7, $E7, $E7)
    nrf24.RXAddr (addr, 0, nrf24#WRITE)                     ' Set pipe 0 address

    addr := string($C2, $C2, $C2, $C2, $C2)
    nrf24.RXAddr (addr, 1, nrf24#WRITE)                     ' Set pipe 1 address

    addr := $C3
    nrf24.RXAddr (@addr, 2, nrf24#WRITE)                    ' Set pipe 2 address

    addr := $C4
    nrf24.RXAddr (@addr, 3, nrf24#WRITE)                    ' Set pipe 3 address

    addr := $C5
    nrf24.RXAddr (@addr, 4, nrf24#WRITE)                    ' Set pipe 4 address

    addr := $C6
    nrf24.RXAddr (@addr, 5, nrf24#WRITE)                    ' Set pipe 5 address


    nrf24.RXMode                                            ' Set transceiver to receive mode (0 = stay in RX mode)
    nrf24.FlushRX                                           ' Empty the receive FIFO
    nrf24.CRCCheckEnabled(TRUE)                             ' TRUE, FALSE (enable CRC generation, checking)
    nrf24.CRCLength(2)                                      ' 1, 2 bytes (CRC length)
    nrf24.DataRate(2000)                                    ' 250, 1000, 2000 (kbps)
    nrf24.TXPower(-18)                                      ' -18, -12, -6, 0 (dBm)
    nrf24.PipesEnabled(%111111)                             ' %000000..%111111 (enable data pipes per bitmask)
    nrf24.Powered (TRUE)
    nrf24.PayloadReady (CLEAR)                              ' Clear interrupt
    repeat tmp from 0 to 5
        nrf24.PayloadLen (_pktlen, tmp)                     ' Payload length 0..32 (bytes), 0..5 (pipe number)

    ser.Clear
    ser.Position(0, 0)
    ser.str(string("Receive mode - "))
    ser.Dec(nrf24.CarrierFreq(-2))
    ser.str(string("MHz", ser#NL, ser#LF))

    ser.str(string("Listening for traffic on node address $"))' XXX output is misleading/incomplete; update to include all enabled pipes
    bytefill(@addr, 0, 8)
    nrf24.RXAddr(@addr, 0, nrf24#READ)                      ' Read pipe 0 address
    repeat i from 4 to 0
        ser.Hex(addr.byte[i], 2)
    ser.Newline
    count := 0
    repeat
        bytefill (@_fifo, $00, 8)                           ' Clear RX local buffer
        repeat                                              ' Wait to proceed
            ser.Position(0, 5)                              ' .
            ser.str(string("RSSI: "))                       ' .
            ser.str(int.DecPadded(nrf24.RSSI, 4))           ' .
            ser.newline                                     ' .
            ser.str(string("Packets received: "))           ' .
            ser.dec(count)                                  ' .
        until nrf24.PayloadReady(-2)                        ' until we've received at least _pktlen bytes

        recv_pipe := nrf24.RXPipePending                    ' In which pipe is the received data waiting?
        nrf24.RXPayload(_pktlen, @_fifo)                    ' Retrieve it into our local buffer
        count++                                             ' Increment received payload counter

        ser.Position(0, 8 + (recv_pipe * 4))                ' Display the payload in a terminal position
        ser.str(string("Received packet on pipe "))         '   based on the pipe number it was
        ser.dec(recv_pipe)                                  '   received on

        Hexdump(@_fifo, 0, _pktlen, _pktlen, 0, 9 + (recv_pipe * 4))

        nrf24.PayloadReady(CLEAR)                           ' Clear interrupt
        nrf24.FlushRX                                       ' Flush FIFO

PRI HexDump(buff_addr, base_addr, nr_bytes, columns, x, y) | maxcol, maxrow, digits, hexoffset, ascoffset, offset, hexcol, asccol, row, col, currbyte
' Display a hexdump of a region of memory
'   buff_addr: Start address of memory
'   base_addr: Address used to display as base address in hex dump (affects display only)
'   nr_bytes: Total number of bytes to display
'   columns: Number of bytes to display on each line
'   x, y: Terminal position to display start of hex dump
    maxcol := columns-1
    maxrow := nr_bytes / columns
    digits := 5                                             ' Number of digits used to display offset
    hexoffset := digits + 2
    ascoffset := hexoffset + (columns * 3)
    offset := 0

    repeat row from y to y+maxrow
        ser.Position (x, row)
        ser.Hex (base_addr+offset, digits)                  ' Show offset address of row in 'digits'
        ser.Str (string(": "))
        repeat col from 0 to maxcol
            currbyte := byte[buff_addr][offset]
            offset++
            hexcol := x + (col * 3) + hexoffset             ' Compute the terminal X position of the hex byte
            asccol := x + col + ascoffset                   ' and the ASCII character

            ser.Position (hexcol, row)                      ' Show the ASCII value in hex
            ser.Hex (currbyte, 2)                           '   of the current byte

            ser.Position (asccol, row)                      ' Show the ASCII character
            case currbyte                                   '   of the current byte
                32..127:                                    '   IF it's a printable character
                    ser.Char (currbyte)
                OTHER:                                      '   Otherwise, just show a period
                    ser.Char (".")
            if offset > nr_bytes-1
                return

PUB Setup

    repeat until _ser_cog := ser.StartRXTX (SER_RX, SER_TX, 0, SER_BAUD)
    time.MSleep(30)
    ser.Clear
    ser.str(string("Serial terminal started", ser#NL, ser#LF))
    if _nrf24_cog := nrf24.Startx (CE_PIN, CSN_PIN, SCK_PIN, MOSI_PIN, MISO_PIN)
        ser.str(string("nRF24L01+ driver started", ser#NL, ser#LF))
    else
        ser.str(string("nRF24L01+ driver failed to start - halting", ser#NL, ser#LF))
        FlashLED (LED, 500)

PUB FlashLED(led_pin, delay_ms)

    io.Output(led_pin)
    repeat
        io.Toggle (led_pin)
        time.MSleep (delay_ms)

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
