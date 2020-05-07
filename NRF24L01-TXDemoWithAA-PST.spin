{
    --------------------------------------------
    Filename: NRF24L01-TXDemoWithAA-PST.spin
    Author: Jesse Burt
    Description: nRF24L01+ Transmit demo that uses the radio's
        auto-acknowledge function (Enhanced ShockBurst - (TM) Nordic Semi)
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

    CE_PIN          = 5
    CSN_PIN         = 4
    SCK_PIN         = 1
    MOSI_PIN        = 2
    MISO_PIN        = 0

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
    long _fifo[16]
    byte _pktlen

PUB Main | choice

    Setup

    nrf24.Channel(CHANNEL)
    ser.str(string("Press any key to begin transmitting", ser#NL, ser#LF))
    ser.CharIn

    Transmit

PUB Transmit | count, tmp, addr[2], to_node, i, max_retrans, pkts_retrans, lost_pkts, countdown

    _pktlen := 8

    nrf24.AddressWidth(5)
                                                            ' Address (Note: byte order is reversed within the string. $C4 is actually the LSB of the address, i.e., the address is actually C2C2C2C2C4)
                                                            ' Uncomment one of the following, or define your own:
    addr := string($E7, $E7, $E7, $E7, $E7)                 ' Default RX Pipe 0 address
'    addr := string($C2, $C2, $C2, $C2, $C2)                ' Default RX Pipe 1 address
'    addr := string($C3, $C2, $C2, $C2, $C2)                ' Default RX Pipe 2 address - only the first byte can be changed. The remaining four will be ignored.
'    addr := string($C4, $C2, $C2, $C2, $C2)                ' Default RX Pipe 3 address - only the first byte can be changed. The remaining four will be ignored.
'    addr := string($C5, $C2, $C2, $C2, $C2)                ' Default RX Pipe 4 address - only the first byte can be changed. The remaining four will be ignored.
'    addr := string($C6, $C2, $C2, $C2, $C2)                ' Default RX Pipe 5 address - only the first byte can be changed. The remaining four will be ignored.
    nrf24.NodeAddress (addr)                                ' Set TX and RX address to the same
                                                            ' (RX pipe is used for receipt of Auto-Acknowledgement)

    nrf24.TXMode                                            ' Set to Transmit mode and
    nrf24.FlushTX                                           '   empty the transmit FIFO
    nrf24.CRCCheckEnabled(TRUE)                             ' TRUE, FALSE (enable CRC generation, checking)
    nrf24.CRCLength (2)                                     ' 1 or 2 bytes (CRC length)
    nrf24.DataRate(2000)                                    ' 250, 1000, 2000 (kbps)
    nrf24.TXPower(-18)                                      ' -18, -12, -6, 0 (dBm)
    nrf24.PipesEnabled(%000001)                             ' %000000..%111111 (enable data pipes per bitmask)
    nrf24.Powered (TRUE)
    nrf24.PayloadReady (CLEAR)                              ' Clear interrupts
    nrf24.PayloadSent (CLEAR)                               '
    nrf24.MaxRetransReached (CLEAR)                         '
    nrf24.PayloadLen (_pktlen, 0)                           ' Payload length 0..32 (bytes), 0..5 (pipe number)

    ser.Clear
    ser.Position(0, 0)
    ser.str(string("Transmit mode - "))
    ser.dec(nrf24.CarrierFreq(-2))
    ser.str(string("MHz", ser#NL, ser#LF))
    ser.str(string("Transmitting to node $"))
    nrf24.TXAddr(@addr, nrf24#READ)
    repeat i from 4 to 0
        ser.Hex(addr.byte[i], 2)

    _fifo.byte[0] := "T"                                    ' Start of payload
    _fifo.byte[1] := "E"
    _fifo.byte[2] := "S"
    _fifo.byte[3] := "T"

    countdown := 20
    count := 0
    repeat
        max_retrans := nrf24.MaxRetransReached(-2)          '
        pkts_retrans := nrf24.PacketsRetransmitted          ' Collect some packet statistics
        lost_pkts := nrf24.LostPackets                      '
        ser.position(0, 5)
        ser.str(string("Max retrans: "))
        ser.dec(max_retrans)
        ser.str(string(ser#NL, ser#LF, "Packets retransmitted: "))
        ser.dec(pkts_retrans)
        ser.str(string(ser#NL, ser#LF, "Lost packets: "))
        ser.dec(lost_pkts)

        if max_retrans == TRUE                              ' If max number of retransmissions reached,
            nrf24.MaxRetransReached(CLEAR)                  '   clear the interrupt so we can continue to TX

        if lost_pkts => 15                                  ' If number of packets lost exceeds 15
            nrf24.Channel(CHANNEL)                          '   clear the interrupt so we can continue to TX

        if countdown == 20                                  ' Transmit, if it's the start of the countdown
            tmp := int.DecZeroed(count++, 4)                ' Tack a counter onto the
            bytemove(@_fifo.byte[4], tmp, 4)                '   end of the payload
            ser.position(0, 10)
            ser.str(string("Sending"))
            Hexdump(@_fifo, 0, _pktlen, _pktlen, 0, 11)
            nrf24.TXPayload (_pktlen, @_fifo, FALSE)        ' Transmit _fifo contents immediately

        time.MSleep(50)                                     ' Don't abuse the airwaves - wait between packets
        if countdown-- < 0
            countdown := 20

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
        ser.str(string("NRF24L01+ driver started", ser#NL, ser#LF))
    else
        ser.str(string("NRF24L01+ driver failed to start - halting", ser#NL, ser#LF))
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
