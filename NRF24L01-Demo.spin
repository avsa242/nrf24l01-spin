{
    --------------------------------------------
    Filename:
    Author:
    Description:
    Copyright (c) 20__
    Started Month Day, Year
    Updated Month Day, Year
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode = cfg#_clkmode
    _xinfreq = cfg#_xinfreq

OBJ

    cfg   : "core.con.boardcfg.flip"
    ser   : "com.serial.terminal"
    time  : "time"
    nrf24 : "wireless.2_4.nrf24l01"
    int   : "string.integer"

VAR

    byte _ser_cog, _nrf_cog

PUB Main

    dira[26] := 1
    Setup
    Power
'    Sweep(1)
'    CW_Test
'    Rate
    flash
'    CW (5)
 '   repeat

    Read_RXPipe_Addr
    Read_TXPipe_Addr
    Channel
    RPD
    flash

PUB flash

    repeat
        !outa[26]
        time.MSleep (100)

PUB Power | tmp

    nrf24.RFPower (0)
    ser.Str (string("RF Power = "))
    ser.Dec (nrf24.RFPower (-2))
    ser.NewLine

    nrf24.RFPower (-6)
    ser.Str (string("RF Power = "))
    ser.Dec (nrf24.RFPower (-2))
    ser.NewLine

    nrf24.RFPower (-12)
    ser.Str (string("RF Power = "))
    ser.Dec (nrf24.RFPower (-2))
    ser.NewLine

    nrf24.RFPower (-18)
    ser.Str (string("RF Power = "))
    ser.Dec (nrf24.RFPower (-2))
    ser.NewLine

PUB Rate | tmp

    ser.Str (string("Data rate = "))
    ser.Dec (nrf24.Rate (-2))
    ser.NewLine

    nrf24.Rate (1000)'06
    ser.Str (string("Data rate = "))
    ser.Dec (nrf24.Rate (-2))
    ser.NewLine

    nrf24.Rate (2000)'0E
    ser.Str (string("Data rate = "))
    ser.Dec (nrf24.Rate (-2))
    ser.NewLine

    nrf24.Rate (250)'26
    ser.Str (string("Data rate = "))
    ser.Dec (nrf24.Rate (-2))
    ser.NewLine

PUB CW_Test | tmp
' Set pwr_up = 1 and prim_rx = 0 (CONFIG)
' wait 1.5ms
' CONT_WAVE = 1
' PLL_LOCK = 1
' RF_PWR = x
' Set CH
' High (CE)

    nrf24.PowerUp (TRUE)
    ser.Str (string("PowerUp = "))
    ser.Dec (nrf24.PowerUp (-2))
    ser.NewLine

    nrf24.RXTX (0)
    ser.Str (string("RX/TX = "))
    ser.Dec (nrf24.RXTX (-2))
    ser.NewLine

    time.USleep (1500)

    nrf24.CW (TRUE)
    ser.Str (string("CW = "))
    ser.Dec (nrf24.CW (-2))
    ser.NewLine

    nrf24.PLL_Lock (TRUE)
    ser.Str (string("PLL_LOCK = "))
    ser.Dec (nrf24.PLL_Lock (-2))
    ser.NewLine

    nrf24.RFPower (%00)
    ser.Str (string("RF Power = "))
    ser.Dec (nrf24.RFPower (-2))
    ser.NewLine

    nrf24.Channel (2)
    ser.Str (string("CH = "))
    ser.Dec (nrf24.Channel (-2))
    ser.NewLine

    nrf24.CE (1)
    ser.Str (string("CE = "))
    ser.Dec (ina[0])
    ser.NewLine

    repeat until ser.CharIn == 13
    nrf24.CE (0)
    ser.Str (string("CE = "))
    ser.Dec (ina[0])
    ser.NewLine

PUB CW(reps) | cw_set, tmp

    repeat tmp from 1 to reps
        cw_set := nrf24.CW (2)
        case cw_set
            FALSE:
                nrf24.CW (TRUE)
            TRUE:
                nrf24.CW (FALSE)
        ser.Position (0, 2+tmp)
        ser.Str (string("Current CW setting: "))
        ser.Dec (cw_set)
        time.Sleep (1)

PUB Sweep(reps) | ch, list

    repeat reps
        repeat ch from 0 to 127
            ser.Position (0, 2)
            ser.Str (string("Scanning channel "))
            ser.Str (int.DecPadded (ch, 3))
            nrf24.Channel (ch)
            if nrf24.RPD
                list++
                ser.Position (0, list + 4)
                ser.Str (int.DecPadded (ch, 3))
            time.MSleep (100)

PUB Channel | ch

    ser.Str (string("RF Channel = "))
    ser.Dec (ch := nrf24.Channel (-1))
    ser.Str (string(" ("))
    ser.Dec (2400+ch)
    ser.Str (string("MHz)"))
    ser.Str (string("  status = "))
    ser.Hex (nrf24.Status, 8)
    ser.NewLine

    ch := 62
    ser.Str (string("Set RF Channel = "))
    ser.Dec (ch)
    nrf24.Channel (ch)
    ser.Str (string(" ("))
    ser.Dec (2400+ch)
    ser.Str (string("MHz). Readback channel = "))
    ser.Dec (nrf24.Channel (-1))
    ser.Str (string("  status = "))
    ser.Hex (nrf24.Status, 8)
    ser.NewLine

PUB RPD

    ser.Str (string("Received Power Detector = "))
    ser.Dec (nrf24.RPD)
    ser.Str (string("  status = "))
    ser.Hex (nrf24.Status, 8)
    ser.NewLine

PUB Read_RXPipe_Addr | pipe, addr[2], tmp, status

    repeat pipe from 0 to 5
        nrf24.RXAddr (pipe, @addr)
        status := nrf24.Status
        ser.Str (string("Pipe "))
        ser.Dec (pipe)
        ser.Str (string(" address = "))
        repeat tmp from 0 to 4
            ser.Hex (addr.byte[tmp], 2)
        ser.Str (string("  status = "))
        ser.Hex (status, 8)
        ser.NewLine
    ser.NewLine

PUB Read_TXPipe_Addr | addr[2], tmp

    nrf24.TXAddr (@addr)
    ser.Str (string("TX address = "))
    repeat tmp from 0 to 4
        ser.Hex (addr.byte[tmp], 2)
    ser.Str (string("  status = "))
    ser.Hex (nrf24.Status, 8)
    ser.NewLine
    
PUB Setup

    repeat until _ser_cog := ser.Start (115_200)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#NL))
    repeat until _nrf_cog := nrf24.Startx (0, 1, 2, 3, 4)'(CE_PIN, CSN_PIN, SCK_PIN, MOSI_PIN, MISO_PIN)
    ser.Str(string("nRF24L01+ driver started", ser#NL))

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
