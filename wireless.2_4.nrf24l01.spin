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

PUB CE(state)

    outa[_CE] := state

PUB Channel(ch)
' Set/Get RF Channel
'   Resulting frequency of set channel = 2400MHz + ch
'       e.g., if ch is 35, Frequency is 2435MHz
'   Valid values: 0..127 sets channel
'   Any other value polls the chip and returns the current setting
    case ch
        0..127:
            writeRegX (core#NRF24_RF_CH, 1, @ch)
        OTHER:
            readRegX (core#NRF24_RF_CH, 1, @result)

PUB CW(enabled) | tmp
' Enable continuous carrier transmit (intended for testing only)
'   Valid values: 0: Disable, TRUE or 1: Enable.
'   Any other value polls the chip and returns the current setting
    case ||enabled
        0, 1:
            enabled := ||enabled << core#FLD_CONT_WAVE
            readRegX (core#NRF24_RF_SETUP, 1, @tmp)
        OTHER:
            readRegX (core#NRF24_RF_SETUP, 1, @result)
            result := ((result >> core#FLD_CONT_WAVE) & %1) * TRUE
            return result

    tmp &= core#FLD_CONT_WAVE_MASK
    tmp := (tmp | enabled) & core#NRF24_RF_SETUP_MASK
    writeRegX (core#NRF24_RF_SETUP, 1, @tmp)

PUB LostPackets
' Count lost packets
'   Returns: Number of lost packets since last write to RF_CH reg.
'   Max value is 15
    readRegX (core#NRF24_OBSERVE_TX, 1, @result)
    result := (result >> core#FLD_PLOS_CNT) & core#MASK_PLOS_CNT

PUB PLL_Lock(enabled) | tmp
' Force PLL Lock signal (intended for testing only)
'   Valid values: 0: Disable, TRUE or 1: Enable.
'   Any other value polls the chip and returns the current setting
    case ||enabled
        0, 1:
            enabled := ||enabled << core#FLD_PLL_LOCK
            readRegX (core#NRF24_RF_SETUP, 1, @tmp)
        OTHER:
            readRegX (core#NRF24_RF_SETUP, 1, @result)
            result := ((result >> core#FLD_PLL_LOCK) & %1) * TRUE
            return result

    tmp &= core#FLD_PLL_LOCK_MASK
    tmp := (tmp | enabled) & core#NRF24_RF_SETUP_MASK
    writeRegX (core#NRF24_RF_SETUP, 1, @tmp)

PUB PowerUp(enabled) | tmp
' Power on or off
'   Valid values: 0: Disable, TRUE or 1: Enable.
'   Any other value polls the chip and returns the current setting
    case ||enabled
        0, 1:
            enabled := ||enabled << core#FLD_PWR_UP
            readRegX (core#NRF24_CONFIG, 1, @tmp)
        OTHER:
            readRegX (core#NRF24_CONFIG, 1, @result)
            result := ((result >> core#FLD_PWR_UP) & %1) * TRUE
            return result

    tmp &= core#FLD_PWR_UP_MASK
    tmp := (tmp | enabled) & core#NRF24_CONFIG_MASK
    writeRegX (core#NRF24_CONFIG, 1, @tmp)

PUB Rate(kbps) | tmp, lo, hi, tmp2, tmp3
' Set RF data rate in kbps
'   Valid values: 250, 1000, 2000
'   Any other value polls the chip and returns the current setting
    readRegX (core#NRF24_RF_SETUP, 1, @tmp)
    case kbps
        1000:
            tmp &= core#FLD_RF_DR_HIGH_MASK
            tmp &= core#FLD_RF_DR_LOW_MASK
        2000:
            tmp |= (1 << core#FLD_RF_DR_HIGH)
            tmp &= core#FLD_RF_DR_LOW_MASK
        250:
            tmp &= core#FLD_RF_DR_HIGH_MASK
            tmp |= (1 << core#FLD_RF_DR_LOW)
        OTHER:
            readRegX (core#NRF24_RF_SETUP, 1, @tmp)
            tmp := (tmp >> core#FLD_RF_DR_HIGH) & %101          'Only care about the RF_DR_x bits
            result := lookupz(tmp: 1000, 2000, 0, 0, 250)
            return result

    writeRegX (core#NRF24_RF_SETUP, 1, @tmp)

PUB RetrPackets
' Count retransmitted packets
'   Returns: Number of packets retransmitted since the start of transmission of a new packet
    readRegX (core#NRF24_OBSERVE_TX, 1, @result)
    result &= core#MASK_ARC_CNT

PUB RFPower(power) | tmp
' Set RF output power in TX mode
'   Valid values: 0: -18dBm, 1: -12dBm, 2: -6dBm, 3: 0dBm
'   Any other value polls the chip and returns the current setting
    case power
        0..3:
            power := power << core#FLD_RF_PWR
            readRegX (core#NRF24_RF_SETUP, 1, @tmp)
        OTHER:
            readRegX (core#NRF24_RF_SETUP, 1, @result)
            result := (result >> core#FLD_RF_PWR) & core#FLD_RF_PWR_BITS
            return result

    tmp &= core#FLD_RF_PWR_MASK
    tmp := (tmp | power) & core#NRF24_RF_SETUP_MASK
    writeRegX (core#NRF24_RF_SETUP, 1, @tmp)

PUB RPD
' Received Power Detector
'   Returns:
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

PUB RXPipePending
' Returns pipe number of pending data available in FIFO
'   Returns: Pipe number 0..5, or 7 if FIFO is empty
    result := (Status & core#FLD_RX_P_NO)

PUB RXTX(role) | tmp
' Set to Primary RX or TX
'   Valid values: 0: TX, 1: RX
'   Any other value polls the chip and returns the current setting
    case role
        0, 1:
            role := role << core#FLD_PRIM_RX
            readRegX (core#NRF24_CONFIG, 1, @tmp)
        OTHER:
            readRegX (core#NRF24_CONFIG, 1, @result)
            result := ((result >> core#FLD_PRIM_RX) & %1)
            return result

    tmp &= core#FLD_PRIM_RX_MASK
    tmp := (tmp | role) & core#NRF24_CONFIG_MASK
    writeRegX (core#NRF24_CONFIG, 1, @tmp)

PUB TXAddr(buf_addr)
' Writes transmit address to buffer at address buf_addr
' NOTE: This buffer must be a minimum of 5 bytes
    readRegX (core#NRF24_TX_ADDR, 5, buf_addr)

PUB TXFIFO_Full
' Returns TX FIFO full flag
'   Returns: TRUE if full, FALSE if locations available in TX FIFO
    result := (Status & core#FLD_TX_FULL) * TRUE

PUB Status
' Returns status of last SPI transaction
    readRegX (core#NRF24_STATUS, 1, @result)

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
