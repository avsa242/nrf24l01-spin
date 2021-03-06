{
    --------------------------------------------
    Filename: wireless.transceiver.nrf24l01.spi.spin
    Author: Jesse Burt
    Description: Driver for Nordic Semi. nRF24L01+
    Copyright (c) 2021
    Started Jan 6, 2019
    Updated Apr 25, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

    PAYLD_LEN_MAX   = 32

    TX              = 0
    RX              = 1

' RXAddr and TXAddr constants
    READ            = 0
    WRITE           = 1

' Interrupt flags
    PAYLD_RDY       = 1 << 2
    PAYLD_SENT      = 1 << 1
    MAX_RETRANS     = 1 << 0

VAR

    long _CE, _CS, _SCK, _MOSI, _MISO
    word _status

OBJ

    spi     : "com.spi.bitbang"                 ' PASM SPI engine (~4MHz)
    core    : "core.con.nrf24l01"               ' hw-specific constants
    time    : "time"                            ' basic timekeeping methods
    io      : "io"                              ' I/O pin abstraction

PUB Null{}
' This is not a top-level object

PUB Startx(CE_PIN, CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN): okay | tmp[2], i

    if lookdown(CE_PIN: 0..31) and lookdown(CS_PIN: 0..31) and{
}   lookdown(SCK_PIN: 0..31) and lookdown(MOSI_PIN: 0..31) and{
}   lookdown(MISO_PIN: 0..31)
        if okay := spi.init(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN, core#SPI_MODE)
            longmove(@_CE, @CE_PIN, 5)
            time.usleep(core#TPOR)
            time.usleep(core#TPD2STBY)

            io.low(_CE)
            io.output(_CE)
            defaults{}                          ' nRF24L01+ has no RESET pin,
                                                '   so set defaults
            rxaddr(@tmp, 0, READ)               ' there's also no device ID, so
            repeat i from 0 to 4                '   read pipe #0's address
                if tmp.byte[i] <> $E7           ' doesn't match default?
                    return FALSE                ' connection prob, or no nRF24
            return okay                         ' nRF24 found
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB Stop{}

    io.high(_CS)
    io.low(_CE)
    sleep{}
    spi.deinit{}

PUB Defaults{} | pipe_nr
' The nRF24L01+ has no RESET pin or function to restore the chip to a known initial operating state,
'   so use this method to establish default settings, per the datasheet
    crccheckenabled(TRUE)
    crclength(1)
    sleep{}
    txmode{}
    autoackenabledpipes(%111111)
    pipesenabled(%000011)
    addresswidth(5)
    autoretransmitdelay(250)
    autoretransmitcount(3)
    channel(2)
    testcw(FALSE)
    pll_lock(FALSE)
    datarate(2000)
    txpower(0)
    intclear(%111)
    rxaddr(string($E7, $E7, $E7, $E7, $E7), 0, WRITE)
    rxaddr(string($C2, $C2, $C2, $C2, $C2), 1, WRITE)
    rxaddr(string($C3), 2, WRITE)
    rxaddr(string($C4), 3, WRITE)
    rxaddr(string($C5), 4, WRITE)
    rxaddr(string($C6), 5, WRITE)
    txaddr(string($E7, $E7, $E7, $E7, $E7), WRITE)
    repeat pipe_nr from 0 to 5
        payloadlen(0, pipe_nr)
    dynamicpayload(%000000)
    dynpayloadenabled(FALSE)
    enableack(FALSE)

PUB Preset_RX250k{}
' Receive mode, 250kbps (AutoAck enabled)
    rxmode{}
    flushrx{}
    powered(TRUE)
    intclear(%111)
    pipesenabled(%000011)
    autoackenabledpipes(%111111)
    datarate(250)

PUB Preset_RX250k_NoAA{}
' Receive mode, 250kbps (AutoAck disabled)
    rxmode{}
    flushrx{}
    powered(TRUE)
    intclear(%111)
    pipesenabled(%000011)
    autoackenabledpipes(%000000)
    datarate(250)

PUB Preset_RX1M{}
' Receive mode, 1Mbps (AutoAck enabled)
    rxmode{}
    flushrx{}
    powered(TRUE)
    intclear(%111)
    pipesenabled(%000011)
    autoackenabledpipes(%111111)
    datarate(1000)

PUB Preset_RX1M_NoAA{}
' Receive mode, 1Mbps (AutoAck disabled)
    rxmode{}
    flushrx{}
    powered(TRUE)
    intclear(%111)
    pipesenabled(%000011)
    autoackenabledpipes(%000000)
    datarate(1000)

PUB Preset_RX2M{}
' Receive mode, 2Mbps (AutoAck enabled)
    rxmode{}
    flushrx{}
    powered(TRUE)
    intclear(%111)
    pipesenabled(%000011)
    autoackenabledpipes(%111111)
    datarate(2000)

PUB Preset_RX2M_NoAA{}
' Receive mode, 2Mbps (AutoAck disabled)
    rxmode{}
    flushrx{}
    powered(TRUE)
    intclear(%111)
    pipesenabled(%000011)
    autoackenabledpipes(%000000)
    datarate(2000)

PUB Preset_TX250k{}
' Transmit mode, 250kbps (AutoAck enabled)
    txmode{}
    flushtx{}
    powered(true)
    autoackenabledpipes(%111111)
    intclear(%111)
    datarate(250)
    autoretransmitdelay(1500)                   ' covers worst-case

PUB Preset_TX250k_NoAA{}
' Transmit mode, 250kbps (AutoAck disabled)
    txmode{}
    flushtx{}
    powered(true)
    autoackenabledpipes(%000000)
    intclear(%111)
    datarate(250)

PUB Preset_TX1M{}
' Transmit mode, 1Mbit (AutoAck enabled)
    txmode{}
    flushtx{}
    powered(true)
    autoackenabledpipes(%111111)
    intclear(%111)
    datarate(1000)
    autoretransmitdelay(500)                    ' covers worst-case

PUB Preset_TX1M_NoAA{}
' Transmit mode, 1Mbit (AutoAck disabled)
    txmode{}
    flushtx{}
    powered(true)
    autoackenabledpipes(%000000)
    intclear(%111)
    datarate(1000)

PUB Preset_TX2M{}
' Transmit mode, 2Mbit (AutoAck enabled)
    txmode{}
    flushtx{}
    powered(true)
    autoackenabledpipes(%111111)
    intclear(%111)
    datarate(2000)
    autoretransmitdelay(500)                    ' covers worst-case

PUB Preset_TX2M_NoAA{}
' Transmit mode, 2Mbit (AutoAck disabled)
    txmode{}
    flushtx{}
    powered(true)
    autoackenabledpipes(%000000)
    intclear(%111)
    datarate(2000)

PUB CE(state)
' Set state of nRF24L01+ Chip Enable pin
'   Valid values:
'       TX mode:
'           0: Enter Idle mode
'           1: Initiate transmission of queued data
'       RX mode:
'           0: Enter Idle mode
'           1: Active receive mode
    io.set(_CE, state)
    time.usleep(core#THCE)

PUB AddressWidth(bytes): curr_width
' Set width, in bytes, of RX/TX address field
'   Valid values: 3, 4, *5
'   Any other value polls the chip and returns the current setting
    curr_width := 0
    readreg(core#SETUP_AW, 1, @curr_width)
    case bytes
        3, 4, 5:
            bytes -= 2                          ' adjust to bitfield value
        other:
            return (curr_width & core#AW_BITS) + 2

    bytes := ((curr_width & core#AW_MASK) | bytes) & core#SETUP_AW_MASK
    writereg(core#SETUP_AW, 1, @bytes)

PUB AfterRX(next_state)
' Define state to transition to after packet rcvd
'   0: Remain in active RX state, ready to receive packets
'   Any other value: Change to RX state, but immediately enter a lower-power
'       Idle/Standby state
    rxmode{}
    if next_state
        idle{}
    else
        ce(1)

PUB AutoAckEnabledPipes(pipe_mask): curr_mask
' Enable the Auto Acknowledgement function
'   (aka Enhanced ShockBurst - (TM) NORDIC Semi.)
'   per set data pipe mask:
'   Data Pipe:     5    0   5    0
'                  |....|   |....|
'   Valid values: %000000..%111111 (default %111111)
'   0 disables AA for the given pipe, 1 enables
'   Example:
'       AutoAckEnabledPipes(%001010)
'           would enable AA for data pipes 1 and 3, and disable for all others
    case pipe_mask
        %000000..%111111:
            writereg(core#EN_AA, 1, @pipe_mask)
        other:
            curr_mask := 0
            readreg(core#EN_AA, 1, @curr_mask)
            return curr_mask & core#EN_AA_MASK

PUB AutoRetransmitCount(tries): curr_tries
' Setup of automatic retransmission - Auto Retransmit Count
' Defines number of attempts to re-transmit on fail of Auto-Acknowledge
'   Valid values: 0..15 (default 3; 0 disables re-transmit)
'   Any other value polls the chip and returns the current setting
    curr_tries := 0
    readreg(core#SETUP_RETR, 1, @curr_tries)
    case tries
        0..15:
        other:
            return (curr_tries & core#ARC_BITS)

    tries := ((curr_tries & core#ARC_MASK) | tries) & core#SETUP_RETR_MASK
    writereg(core#SETUP_RETR, 1, @tries)

PUB AutoRetransmitDelay(delay_us): curr_dly
' Setup of automatic retransmission - Auto Retransmit Delay, in microseconds
' Delay defined from end of transmission to start of next transmission
'   Valid values: *250..4000 (in steps of 250)
'   Any other value polls the chip and returns the current setting
'   NOTE: The minimum value required for successful transmission depends on the
'       current DataRate() and PayloadLen() settings:
'       DataRate()  PayloadLen() max:   AutoRetransmitDelay() minimum:
'       2000        15                  250
'       2000        Any                 500
'       1000        5                   250
'       1000        Any                 500
'       250         8                   750
'       250         16                  1000
'       250         24                  1250
'       250         Any                 1500
    curr_dly := 0
    readreg(core#SETUP_RETR, 1, @curr_dly)
    case delay_us
        250..4000:
            delay_us := ((delay_us / 250) - 1) << core#ARD
        other:
            curr_dly := ((curr_dly >> core#ARD) & core#ARD_BITS) + 1
            return curr_dly * 250

    delay_us := ((curr_dly & core#ARD_MASK) | delay_us) & core#SETUP_RETR_MASK
    writereg(core#SETUP_RETR, 1, @delay_us)

PUB CarrierFreq(freq): curr_freq
' Set carrier frequency, in MHz
'   Valid values: 2400..2525 (default 2402)
'   Any other value polls the chip and returns the current setting
    case freq
        2400..2525:
            channel(freq-2400)
        other:
            return 2400 + channel(-2)

PUB Channel(number): curr_chan
' Set RF channel
'   Valid values: 0..125 (default 2)
'   Any other value polls the chip and returns the current setting
    case number
        0..125:
            writereg(core#RF_CH, 1, @number)
        other:
            readreg(core#RF_CH, 1, @curr_chan)

PUB CRCCheckEnabled(enabled): curr_state
' Enable CRC
'   Valid values: FALSE: Disable, TRUE (-1 or 1): Enable.
'   Any other value polls the chip and returns the current setting
'   NOTE: Forced on if any data pipe has AutoAck enabled
    curr_state := 0
    readreg(core#CFG, 1, @curr_state)
    case ||(enabled)
        0, 1:
            enabled := ||(enabled) << core#EN_CRC
        other:
            return ((curr_state >> core#EN_CRC) & 1) == 1

    enabled := ((curr_state & core#EN_CRC_MASK) | enabled) & core#CFG_MASK
    writereg(core#CFG, 1, @enabled)

PUB CRCLength(length): curr_len
' Set CRC length, in bytes
'   Valid values: *1, 2
'   Any other value polls the chip and returns the current setting
    curr_len := 0
    readreg(core#CFG, 1, @curr_len)
    case length
        1, 2:
            length := (length-1) << core#CRCO
        other:
            return ((curr_len >> core#CRCO) & 1) + 1

    length := ((curr_len & core#CRCO_MASK) | length) & core#CFG_MASK
    writereg(core#CFG, 1, @length)

PUB DataRate(rate): curr_rate
' Set RF data rate in kbps
'   Valid values: 250, 1000, *2000
'   Any other value polls the chip and returns the current setting
    curr_rate := 0
    readreg(core#RF_SETUP, 1, @curr_rate)
    case rate
        1000:
            curr_rate &= core#RF_DR_HIGH_MASK
            curr_rate &= core#RF_DR_LOW_MASK
        2000:
            curr_rate |= (1 << core#RF_DR_HIGH)
            curr_rate &= core#RF_DR_LOW_MASK
        250:
            curr_rate &= core#RF_DR_HIGH_MASK
            curr_rate |= (1 << core#RF_DR_LOW)
        other:
            curr_rate := (curr_rate >> core#RF_DR_HIGH) & core#RF_DR_BITS
            return lookupz(curr_rate: 1000, 2000, 0, 0, 250)

    writereg(core#RF_SETUP, 1, @curr_rate)

PUB DynamicACK(state): curr_state
' Enable selective auto-acknowledge feature
' When enabled, the receive will not auto-acknowledge packets sent to it.
' XXX expand
'   Valid values: *FALSE: Disable, TRUE (-1 or 1): Enable.
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#FEAT, 1, @curr_state)
    case ||(state)
        0, 1:
            state := ||(state) << core#EN_DYN_ACK
        other:
            return ((curr_state >> core#EN_DYN_ACK) & 1) == 1

    state := ((curr_state & core#EN_DYN_ACK_MASK) | state) & core#FEAT_MASK
    writereg(core#FEAT, 1, @state)

PUB DynamicPayload(mask): curr_mask
' Control which data pipes (0 through 5) have dynamic payload length enabled, using a 6-bit mask
'   Data pipe:     5    0   5    0
'                  |....|   |....|
'   Valid values: %000000..%111111 (default %000000)
    case mask
        %000000..%111111:
            writereg(core#DYNPD, 1, @mask)
        other:
            curr_mask := 0
            readreg(core#DYNPD, 1, @curr_mask)
            return curr_mask & core#DYNPD_MASK

PUB DynPayloadEnabled(state): curr_state
' Enable Dynamic Payload Length
'   Valid values: *FALSE: Disable, TRUE (-1 or 1): Enable.
'   Any other value polls the chip and returns the current setting
'   NOTE: Must be state to use the DynamicPayload method.
    curr_state := 0
    readreg(core#FEAT, 1, @curr_state)
    case ||(state)
        0, 1:
            state := ||(state) << core#EN_DPL
        other:
            return ((curr_state >> core#EN_DPL) & 1) == 1

    state := ((curr_state & core#EN_DPL_MASK) | state) & core#FEAT_MASK
    writereg(core#FEAT, 1, @state)

PUB EnableACK(state): curr_state
' Enable payload with ACK
' XXX Add timing notes/code from datasheet, p.63, note d
'   Valid values: *FALSE: Disable, TRUE (-1 or 1): Enable.
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#FEAT, 1, @curr_state)
    case ||(state)
        0, 1:
            state := ||(state) << core#EN_ACK_PAY
        other:
            return ((curr_state >> core#EN_ACK_PAY) & 1) == 1

    state := ((curr_state & core#EN_ACK_PAY_MASK) | state) & core#FEAT_MASK
    writereg(core#FEAT, 1, @state)

PUB FlushRX{}
' Flush receive FIFO buffer
    writereg(core#CMD_FLUSH_RX, 0, 0)

PUB FlushTX{}
' Flush transmit FIFO buffer
    writereg(core#CMD_FLUSH_TX, 0, 0)

PUB FreqDeviation(freq): curr_freq
' Set frequency deviation, in Hz
'   NOTE: Read-only, for compatibility only
    case datarate(-2)
        250, 1000:
            return 160_000
        2000:
            return 320_000

PUB Idle{}
' Set to idle state
    ce(0)

PUB IntClear(mask)
' Clear interrupts
'           Bits:  210   210
'                  |||   |||
'   Valid values: %000..%111
'       Bit:    Interrupt:
'       2       new data is ready in RX FIFO
'       1       data is transmitted (_and_ if ACK from RX if using auto-ack)
'       0       TX retransmits reach maximum
'   Any other value polls the chip and returns the current setting
    case mask
        %000..%111:
            mask := (mask << core#MASKINT) & core#STATUS_MASK
            writereg(core#STATUS, 1, @mask)
        other:
            return

PUB IntMask(mask): curr_mask
' Control which events will trigger an interrupt on the IRQ pin,
'   using a 3-bit mask
'           Bits:  210   210
'                  |||   |||
'   Valid values: %000..%111 (default is %000)
'       Bit:    Interrupt will be asserted on IRQ pin if:
'       2       new data is ready in RX FIFO
'       1       data is transmitted (_and_ if ACK from RX if using auto-ack)
'       0       TX retransmits reach maximum
'   Set a bit to 0 to disable the specific interrupt, 1 to enable
'   Any other value polls the chip and returns the current setting
    curr_mask := 0
    readreg(core#CFG, 1, @curr_mask)
    case mask
        %000..%111:
            mask := (!mask) << core#MASKINT     ' invert bits: chip internal
        other:                                  '   logic is inverse
            return !((curr_mask >> core#MASKINT) & core#MASKINT_BITS)

    mask := ((curr_mask & core#MASKINT_MASK) | mask) & core#CFG_MASK
    writereg(core#CFG, 1, @mask)

PUB LostPackets{}: pkt_cnt
' Count lost packets
'   Returns: Number of lost packets since last channel/carrier freq set
'   Max value is 15
'   NOTE: To reset, re-set the Channel or CarrierFreq
    readreg(core#OBSERVE_TX, 1, @pkt_cnt)
    return (pkt_cnt >> core#PLOS_CNT) & core#PLOS_CNT_BITS

PUB MaxRetransReached{}: flag
' Flag indicating maximum number of retransmit attempts reached
'   Returns: TRUE (-1) if max reached, FALSE (0) otherwise
'   NOTE: If this flag is set, it must be cleared (IntClear(%001))
'       to enable further communication.
'   NOTE: To set max number of attempts, use AutoRetransmitCount()
    flag := 0
    readreg(core#STATUS, 1, @flag)
    return ((flag >> core#MAX_RT) & 1) == 1

PUB NodeAddress(ptr_addr)
' Set node address
'   NOTE: This sets the address for Receive pipe 0 as well as the Transmit
'       address
    rxaddr(ptr_addr, 0, WRITE)
    txaddr(ptr_addr, WRITE)

PUB PacketsRetransmitted{}: pkt_cnt
' Count retransmitted packets
'   Returns: Number of packets retransmitted since the start of transmission
'       of a new packet
    readreg(core#OBSERVE_TX, 1, @pkt_cnt)
    return pkt_cnt & core#ARC_CNT

PUB PayloadLen(length, pipe_nr): curr_len
' Set length of static payload, in bytes
'   Returns number of bytes in RX payload in data pipe, or 0 if pipe unused
'   Valid values:
'       pipe: 0..5
'       length: 0..32 (default 0)
'   Any other value for pipe is ignored
'   Any other value for length polls the chip and returns the current setting
'   NOTE: Setting a length of 0 effectively disables the pipe
    curr_len := 0
    case pipe_nr
        0..5:
            readreg(core#RX_PW_P0 + pipe_nr, 1, @curr_len)
            case length
                0..32:
                    writereg(core#RX_PW_P0 + pipe_nr, 1, @length)
                    return length
                other:
                    return curr_len & core#RX_PW_BITS

        other:
            return

PUB PayloadReady{}: flag
' Flag indicating received payload ready
'   Returns: TRUE (-1) if interrupt flag asserted, FALSE (0) otherwise
    flag := 0
    readreg(core#STATUS, 1, @flag)
    return ((flag >> core#RX_DR) & 1) == 1

PUB PayloadSent{}: flag
' Flag indicating transmitted payload sent
'   (and acknowledged by receiver, if auto-ack is in use)
    flag := 0
    readreg(core#STATUS, 1, @flag)
    return ((flag >> core#TX_DS) & 1) == 1

PUB PipesEnabled(mask): curr_mask
' Control which data pipes (0 through 5) are enabled, using a 6-bit mask
'   Data pipe:     5    0   5    0
'                  |....|   |....|
'   Valid values: %000000..%111111 (default %000011)
    case mask
        %000000..%111111:
            writereg(core#EN_RXADDR, 1, @mask)
        other:
            curr_mask := 0
            readreg(core#EN_RXADDR, 1, @curr_mask)
            return curr_mask & core#EN_ADDR_MASK

PUB PLL_Lock(state): curr_state
' Force PLL Lock signal (intended for testing only)
'   Valid values: *FALSE: Disable, TRUE (-1 or 1): Enable.
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#RF_SETUP, 1, @curr_state)
    case ||(state)
        0, 1:
            state := ||(state) << core#PLL_LOCK
        other:
            return ((curr_state >> core#PLL_LOCK) & 1) == 1

    state := ((curr_state & core#PLL_LOCK_MASK) | state) & core#RF_SETUP_MASK
    writereg(core#RF_SETUP, 1, @state)

PUB Powered(state): curr_state
' Power on or off
'   Valid values: *FALSE: Disable, TRUE (-1 or 1): Enable.
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#CFG, 1, @curr_state)
    case ||(state)
        0, 1:
            state := ||(state) << core#PWR_UP
        other:
            return ((curr_state >> core#PWR_UP) & 1) == 1

    state := ((curr_state & core#PWR_UP_MASK) | state) & core#CFG_MASK
    writereg(core#CFG, 1, @state)

PUB RPD{}: flag
' Received Power Detector/Carrier Detect
'   Returns:
'       FALSE (0): No Carrier
'       TRUE (-1): Carrier Detected
    flag := 0
    readreg(core#RPD, 1, @flag)
    return (flag == 1)

PUB RSSI{}: level
' RSSI (emulated)
'   Returns:
'       -64: Carrier detected
'       -255 No carrier
    return lookupz(||(rpd{}): -255, -64)

PUB RXAddr(ptr_buff, pipe, rw)
' Set receive address of pipe number 'pipe' from buffer at address ptr_buff
'   Valid values:
'       ptr_buff:
'           Address of buffer containing nRF24L01+ recieve address
'           For pipes 0 and 1, must be a buffer at least 5 bytes long
'           For pipes 2..5, must be a buffer at least 1 byte long
'       pipe: 0..5
'           Any other value is ignored
'       rw:
'           0: Read current address
'           1: Write new address
'           Any other value reads current address
'   Default pipe addresses:
'   0: $E7E7E7E7E7
'   1: $C2C2C2C2C2
'   2: $C3
'   3: $C4
'   4: $C5
'   5: $C6
    case pipe
        0, 1:
            case rw
                1:
                    writereg(core#RX_ADDR_P0 + pipe, 5, ptr_buff)
                other:
                    readreg(core#RX_ADDR_P0 + pipe, 5, ptr_buff)
                    return
        2..5:                                   ' Pipes 2..5 are limited to
            case rw                             ' 1 unique byte
                1:                              ' (hardware limitation)
                    writereg(core#RX_ADDR_P0 + pipe, 1, ptr_buff)
                other:
                    readreg(core#RX_ADDR_P0 + pipe, 1, ptr_buff)
                    return
        other:                                  ' Invalid pipe
            return

PUB RXBandwidth(bw): curr_bw
' Set transceiver bandwidth, in Hz
'   NOTE: Read-only, for compatibility only
    case datarate(-2)
        250, 1000:
            return 1_000_000
        2000:
            return 2_000_000

PUB RXFIFOEmpty{}: flag
' Flag indicating RX FIFO empty
'   Returns:
'       TRUE (-1): RX FIFO empty
'       FALSE (0): RX FIFO contains unread data
    flag := 0
    readreg(core#FIFO_STATUS, 1, @flag)
    return (flag & 1) == 1

PUB RXFIFOFull{}: flag
' Flag indicating RX FIFO full
'   Returns:
'       TRUE (-1): RX FIFO full
'       FALSE (0): RX FIFO not full
    flag := 0
    readreg(core#FIFO_STATUS, 1, @flag)
    return ((flag >> core#RXFIFO_FULL) & 1) == 1

PUB RXMode{}
' Change chip state to RX (receive)
    rxtx(RX)
    ce(1)

PUB RXPayload(nr_bytes, ptr_buff)
' Receive payload stored in FIFO
'   Valid values:
'       nr_bytes: 1..32 (Any other value is ignored)
'   Any other value is ignored
    if lookdown(nr_bytes: 1..32)
        readreg(core#CMD_R_RX_PAYLOAD, nr_bytes, ptr_buff)
    else
        return

PUB RXPipePending{}: pipe_nr
' Returns pipe number of pending data available in FIFO
'   Returns: Pipe number 0..5, or 7 if FIFO is empty
    return (status{} >> core#RX_P_NO) & core#RX_P_NO_BITS

PUB RXTX(role): curr_role
' Set to Primary RX or TX
'   Valid values: *0: TX, 1: RX
'   Any other value polls the chip and returns the current setting
    curr_role := 0
    readreg(core#CFG, 1, @curr_role)
    case role
        0, 1:
            role := role << core#PRIM_RX
        other:
            return ((curr_role >> core#PRIM_RX) & 1)

    role := ((curr_role & core#PRIM_RX_MASK) | role) & core#CFG_MASK
    writereg(core#CFG, 1, @role)

PUB Sleep{}
' Power down chip
    powered(FALSE)

PUB Syncword(ptr_syncwd): curr_syncwd
' Set syncword
    nodeaddress(ptr_syncwd)

PUB TESTCW(state): curr_state
' Enable continuous carrier transmit (intended for testing only)
'   Valid values: *FALSE: Disable, TRUE (-1 or 1): Enable.
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#RF_SETUP, 1, @curr_state)
    case ||(state)
        0, 1:
            state := ||(state) << core#CONT_WAVE
        other:
            return ((curr_state >> core#CONT_WAVE) & 1) == 1

    state := ((curr_state & core#CONT_WAVE_MASK) | state) & core#RF_SETUP_MASK
    writereg(core#RF_SETUP, 1, @state)

PUB TXAddr(ptr_addr, rw)
' Set transmit address
'   Valid values:
'       ptr_addr:
'           Address of buffer containing nRF24L01+ address to transmit to
'       rw:
'           0: Read current address
'           1: Write new address
'           Any other value reads current address
'   Default address: $E7E7E7E7E7
'   NOTE: Buffer at ptr_addr must be a minimum of 5 bytes
    case rw
        1:
            writereg(core#TX_ADDR, 5, ptr_addr)
        other:
            readreg(core#TX_ADDR, 5, ptr_addr)
            return

PUB TXFIFOEmpty{}: flag
' Flag indicating TX FIFO empty
'   Returns TRUE if empty, FALSE if there's data in TX FIFO
    readreg(core#FIFO_STATUS, 1, @flag)
    return ((flag >> core#TXFIFO_EMPTY) & 1) == 1

PUB TXFIFOFull{}: flag
' Flag indicating TX FIFO full
'   Returns: TRUE if full, FALSE if locations available in TX FIFO
    return (status{} & 1) == 1

PUB TXMode{}
' Change chip state to TX (transmit)
    rxtx(TX)

PUB TXPayload(nr_bytes, ptr_buff)
' Queue payload to be transmitted
'   Valid values:
'       nr_bytes: 1..32 (Any other value is ignored)
    case nr_bytes
        1..32:
            writereg(core#CMD_W_TX_PAYLOAD, nr_bytes, ptr_buff)
            outa[_CE] := 1
            time.usleep(core#THCE)
            outa[_CE] := 0
        other:
            return

PUB TXPower(pwr): curr_pwr
' Set transmit mode RF output power, in dBm
'   Valid values: -18, -12, -6, *0
'   Any other value polls the chip and returns the current setting
    curr_pwr := 0
    readreg(core#RF_SETUP, 1, @curr_pwr)
    case pwr
        -18, -12, -6, 0:
            pwr := lookdownz(pwr: -18, -12, -6, 0)
            pwr := pwr << core#RF_PWR
        other:
            curr_pwr := (curr_pwr >> core#RF_PWR) & core#RF_PWR_BITS
            return lookupz(curr_pwr: -18, -12, -6, 0)

    pwr := ((curr_pwr & core#RF_PWR_MASK) | pwr) & core#RF_SETUP_MASK
    writereg(core#RF_SETUP, 1, @pwr)

PUB TXReuse{}: flag
' Flag indicating last transmitted payload is to be re-used
'   Returns:
'       TRUE (-1): last transmitted payload reused, FALSE (0) otherwise
    readreg(core#FIFO_STATUS, 1, @flag)
    return ((flag >> core#TXFIFO_REUSE) & 1) == 1

PRI Status{}: nrf_status
' Interrupt and data available status
    readreg(core#STATUS, 1, @nrf_status)

PRI writeReg(reg_nr, nr_bytes, ptr_buff) | tmp
' Write nr_bytes from ptr_buff to device
    case reg_nr
        core#CMD_W_TX_PAYLOAD:
            spi.deselectafter(false)
            spi.wr_byte(reg_nr)
            spi.deselectafter(true)
            spi.wrblock_lsbf(ptr_buff, nr_bytes)
        core#CMD_FLUSH_TX, core#CMD_FLUSH_RX:
            spi.deselectafter(true)
            spi.wr_byte(reg_nr)
        $00..$17, $1C..$1D:
            reg_nr |= core#W_REG
            case nr_bytes
                0:
                    spi.deselectafter(true)
                    spi.wr_byte(reg_nr)
                1..5:
                    spi.deselectafter(false)
                    spi.wr_byte(reg_nr)
                    spi.deselectafter(true)
                    spi.wrblock_lsbf(ptr_buff, nr_bytes)
                other:
                    return
        other:
            return

PRI readreg(reg_nr, nr_bytes, ptr_buff) | tmp
' Read nr_bytes from device into ptr_buff
    case reg_nr
        core#CMD_R_RX_PAYLOAD:
            spi.deselectafter(false)
            spi.wr_byte(reg_nr)
            spi.deselectafter(true)
            spi.rdblock_lsbf(ptr_buff, nr_bytes)
        core#RPD:
            spi.deselectafter(false)
            spi.wr_byte(reg_nr)
            spi.deselectafter(true)
            byte[ptr_buff][0] := spi.rd_byte{}
        $00..$08, $0A..$17, $1C..$1D:
            case nr_bytes
                1..5:
                    spi.deselectafter(false)
                    spi.wr_byte(reg_nr)
                    spi.deselectafter(true)
                    spi.rdblock_lsbf(ptr_buff, nr_bytes)
                other:
                    return
        other:
            return

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
