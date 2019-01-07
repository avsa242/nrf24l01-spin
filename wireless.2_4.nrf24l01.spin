{
    --------------------------------------------
    Filename: wireless.2_4.nrf24l01.spin
    Author: Jesse Burt
    Description: Driver for Nordic Semi. nRF24L01+
    Copyright (c) 2019
    Started Jan 6, 2019
    Updated Jan 6, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    TPOR        = 100 'ms
    TRXSETTLE   = 130 'us
    TTXSETTLE   = 130 'us
    THCE        = 10  'us

    RF_PWR_0    = %11           ' 0dBm
    RF_PWR__6   = %10           ' -6dBm
    RF_PWR__12  = %01           ' -12dBm
    RF_PWR__18  = %00           ' -18dBm

' Recommended states:
' Power down:
'   PWR_UP = 1: XO Start (wait Tpd2stby) transition to Standby I
'   Tpd2stby:
'       150uS Ext clock
'       1.5ms Ext xtal, Ls < 30mH
'       3.0ms Ext xtal, Ls < 60mH
'       4.5ms Ext xtal, Ls < 90mH

' Standby-I:
'   TX_FIFO not empty, PRIM_RX = 0, CE = 1 for >= 10uS: -> TX Settling 130uS -> TX Mode
'   TX finished with one packet, CE = 0: -> Standby-I

'   PRIM_RX = 1, CE = 1: -> RX Settling 130uS -> RX Mode
'   CE = 0 to return to Standby-I

'   PWR-UP = 0 to return to Power Down

VAR

    byte    _CE, _CSN, _SCK, _MOSI, _MISO
    word    _status

OBJ

    spi:    "SPI_Asm"
    core:   "core.con.nrf24l01"
    time:   "time"

PUB Null
''This is not a top-level object

PUB Startx(CE_PIN, CSN_PIN, SCK_PIN, MOSI_PIN, MISO_PIN): okay

    if lookdown(CE_PIN: 0..31) and lookdown(CSN_PIN: 0..31) and lookdown(SCK_PIN: 0..31) and lookdown(MOSI_PIN: 0..31) and lookdown(MISO_PIN: 0..31)
        if okay := spi.start (core#CLK_DELAY, core#CPOL)
            time.MSleep (100)
            _CE := CE_PIN
            _CSN := CSN_PIN
            _SCK := SCK_PIN
            _MOSI := MOSI_PIN
            _MISO := MISO_PIN

            outa[_CE] := 0
            dira[_CE] := 1
            outa[_CSN] := 1
            dira[_CSN] := 1

            return okay

    return FALSE                                                'If we got here, something went wrong

PUB Channel(ch)
' Set/Get RF Channel
'   Resulting frequency of set channel = 2400MHz + chan
'       e.g., if chan is 35, Frequency is 2435MHz
'   Valid values: 0..127 sets channel, -1 returns current channel
    case ch
        0..127:
            writeRegX (core#NRF24_RF_CH, 1, @ch)
        -1:
            readRegX (core#NRF24_RF_CH, 1, @result)
        OTHER:
            return FALSE

PUB RPD
' Received Power Detector
'   Returns
'   FALSE/0: No Carrier
'   TRUE/-1: Carrier Detected
    readRegX (core#NRF24_RPD, 8, @result)
    result *= TRUE

PUB RXAddr(pipe, buf_addr)
' Return address for data pipe 0 to 5 into buffer at address buf_addr
' NOTE: This buffer must be a minimum of 5 bytes
' Out-of-range values for pipe fill the buffer with (5) 0's and return FALSE
    ifnot lookdown(pipe: 0..5)
        bytefill(buf_addr, 0, 5)
        return FALSE
    readRegX (core#NRF24_RX_ADDR_P0 + pipe, 5, buf_addr)

PUB TXAddr(buf_addr)
' Writes transmit address to buffer at address buf_addr
' NOTE: This buffer must be a minimum of 5 bytes
    readRegX (core#NRF24_TX_ADDR, 5, buf_addr)

PUB Status
' Returns status of last SPI transaction
    readRegX (core#NRF24_STATUS, 1, @result)'(reg, nr_bytes, buf_addr)

PUB writeRegX(reg, nr_bytes, buf_addr) | tmp
' Write reg to MOSI
    ifnot lookdown(reg: $00..$17, $1C..$1D)                             'Validate reg - there are a few the datasheet says are for testing
        return FALSE                                                    ' only and will cause the chip to malfunction if written to.

    outa[_CSN] := 0
    case nr_bytes
        0:
            spi.SHIFTOUT (_MOSI, _SCK, core#MOSI_BITORDER, 8, core#NRF24_W_REG|reg)     'Simple command
        1..5:
            spi.SHIFTOUT (_MOSI, _SCK, core#MOSI_BITORDER, 8, core#NRF24_W_REG|reg)     'Command w/nr_bytes data bytes following
            repeat tmp from 0 to nr_bytes-1
                spi.SHIFTOUT (_MOSI, _SCK, core#MOSI_BITORDER, 8, byte[buf_addr][tmp])
        OTHER:
            result := FALSE
            buf_addr := 0
    outa[_CSN] := 1

PUB readRegX(reg, nr_bytes, buf_addr) | tmp
' Read reg from MISO
    ifnot lookdown(reg: $00..$17, $1C..$1D)                             'Validate reg - there are a few the datasheet says are for testing
        return FALSE                                                    ' only and will cause the chip to malfunction if written to.

    outa[_CSN] := 0
    spi.SHIFTOUT (_MOSI, _SCK, core#MOSI_BITORDER, 8, core#NRF24_R_REG | reg)              'Which register to query

    case nr_bytes
        1..5:
            repeat tmp from 0 to nr_bytes-1
                byte[buf_addr][tmp] := spi.SHIFTIN (_MISO, _SCK, core#MISO_BITORDER, 8)
        OTHER:
            result := FALSE
            buf_addr := 0
    outa[_CSN] := 1

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
