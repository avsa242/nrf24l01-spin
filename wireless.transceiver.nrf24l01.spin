{
    --------------------------------------------
    Filename: wireless.transceiver.nrf24l01.spin
    Author: Jesse Burt
    Description: Driver for Nordic Semi. nRF24L01+
    Copyright (c) 2022
    Started Jan 6, 2019
    Updated Oct 8, 2022
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
    INT_PAYLD_RDY   = 1 << 2
    INT_PAYLD_SENT  = 1 << 1
    INT_MAX_RETRANS = 1 << 0

' Packet length modes
    PKTLEN_FIXED    = 0
    PKTLEN_VAR      = 1

VAR

    long _CE, _CS
    word _status

OBJ

    spi     : "com.spi.bitbang-nocs"            ' PASM SPI engine (~4MHz)
    core    : "core.con.nrf24l01"               ' hw-specific constants
    time    : "time"                            ' basic timekeeping methods

PUB null{}
' This is not a top-level object

PUB startx(CE_PIN, CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN): status | tmp[2], i
' Start using custom I/O settings
    if (lookdown(CE_PIN: 0..31) and lookdown(CS_PIN: 0..31) and lookdown(SCK_PIN: 0..31) {
}   and lookdown(MOSI_PIN: 0..31) and lookdown(MISO_PIN: 0..31))
        if (status := spi.init(SCK_PIN, MOSI_PIN, MISO_PIN, core#SPI_MODE))
            longmove(@_CE, @CE_PIN, 2)
            time.usleep(core#TPOR)
            time.usleep(core#TPD2STBY)

            outa[_CE] := 0
            dira[_CE] := 1
            outa[_CS] := 1
            dira[_CS] := 1

            defaults{}                          ' nRF24L01+ has no RESET pin,
                                                '   so set defaults
            rx_addr(@tmp, 0, READ)               ' there's also no device ID, so
            repeat i from 0 to 4                '   read pipe #0's address
                if (tmp.byte[i] <> $E7)         ' doesn't match default?
                    return FALSE                ' connection prob, or no nRF24

            return                              ' nRF24 found
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB stop{}
' Stop the driver
    outa[_CS] := 1
    outa[_CE] := 0
    spi.deinit{}

PUB defaults{} | pipe_nr
' The nRF24L01+ has no RESET pin or function to restore the chip to a known initial operating state,
'   so use this method to establish default settings, per the datasheet
    crc_check_ena(TRUE)
    crc_len(1)
    sleep{}
    tx_mode{}
    auto_ack_pipes_ena(%111111)
    pipes_ena(%000011)
    addr_width(5)
    auto_retrans_dly(250)
    auto_retrans_cnt(3)
    channel(2)
    test_cw(FALSE)
    pll_lock(FALSE)
    data_rate(2_000_000)
    tx_pwr(0)
    int_clear(%111)
    rx_addr(string($E7, $E7, $E7, $E7, $E7), 0, WRITE)
    rx_addr(string($C2, $C2, $C2, $C2, $C2), 1, WRITE)
    rx_addr(string($C3), 2, WRITE)
    rx_addr(string($C4), 3, WRITE)
    rx_addr(string($C5), 4, WRITE)
    rx_addr(string($C6), 5, WRITE)
    tx_addr(string($E7, $E7, $E7, $E7, $E7), WRITE)
    repeat pipe_nr from 0 to 5
        payld_len(0, pipe_nr)
    dyn_payld_len_ena(%000000)
    payld_len_cfg(PKTLEN_FIXED)
    ack_ena(FALSE)

PUB preset_rx250k{}
' Receive mode, 250kbps (AutoAck enabled)
    rx_mode{}
    flush_rx{}
    powered(TRUE)
    int_clear(%111)
    pipes_ena(%000011)
    auto_ack_pipes_ena(%111111)
    data_rate(250_000)

PUB preset_rx250k_noaa{}
' Receive mode, 250kbps (AutoAck disabled)
    rx_mode{}
    flush_rx{}
    powered(TRUE)
    int_clear(%111)
    pipes_ena(%000011)
    auto_ack_pipes_ena(%000000)
    data_rate(250_000)

PUB preset_rx1m{}
' Receive mode, 1Mbps (AutoAck enabled)
    rx_mode{}
    flush_rx{}
    powered(TRUE)
    int_clear(%111)
    pipes_ena(%000011)
    auto_ack_pipes_ena(%111111)
    data_rate(1_000_000)

PUB preset_rx1m_noaa{}
' Receive mode, 1Mbps (AutoAck disabled)
    rx_mode{}
    flush_rx{}
    powered(TRUE)
    int_clear(%111)
    pipes_ena(%000011)
    auto_ack_pipes_ena(%000000)
    data_rate(1_000_000)

PUB preset_rx2m{}
' Receive mode, 2Mbps (AutoAck enabled)
    rx_mode{}
    flush_rx{}
    powered(TRUE)
    int_clear(%111)
    pipes_ena(%000011)
    auto_ack_pipes_ena(%111111)
    data_rate(2_000_000)

PUB preset_rx2m_noaa{}
' Receive mode, 2Mbps (AutoAck disabled)
    rx_mode{}
    flush_rx{}
    powered(TRUE)
    int_clear(%111)
    pipes_ena(%000011)
    auto_ack_pipes_ena(%000000)
    data_rate(2_000_000)

PUB preset_tx250k{}
' Transmit mode, 250kbps (AutoAck enabled)
    tx_mode{}
    flush_tx{}
    powered(true)
    auto_ack_pipes_ena(%111111)
    int_clear(%111)
    data_rate(250_000)
    auto_retrans_dly(1500)                   ' covers worst-case

PUB preset_tx250k_noaa{}
' Transmit mode, 250kbps (AutoAck disabled)
    tx_mode{}
    flush_tx{}
    powered(true)
    auto_ack_pipes_ena(%000000)
    int_clear(%111)
    data_rate(250_000)

PUB preset_tx1m{}
' Transmit mode, 1Mbit (AutoAck enabled)
    tx_mode{}
    flush_tx{}
    powered(true)
    auto_ack_pipes_ena(%111111)
    int_clear(%111)
    data_rate(1_000_000)
    auto_retrans_dly(500)                    ' covers worst-case

PUB preset_tx1m_noaa{}
' Transmit mode, 1Mbit (AutoAck disabled)
    tx_mode{}
    flush_tx{}
    powered(true)
    auto_ack_pipes_ena(%000000)
    int_clear(%111)
    data_rate(1_000_000)

PUB preset_tx2m{}
' Transmit mode, 2Mbit (AutoAck enabled)
    tx_mode{}
    flush_tx{}
    powered(true)
    auto_ack_pipes_ena(%111111)
    int_clear(%111)
    data_rate(2_000_000)
    auto_retrans_dly(500)                    ' covers worst-case

PUB preset_tx2m_noaa{}
' Transmit mode, 2Mbit (AutoAck disabled)
    tx_mode{}
    flush_tx{}
    powered(true)
    auto_ack_pipes_ena(%000000)
    int_clear(%111)
    data_rate(2_000_000)

PUB chip_ena(state)
' Set state of nRF24L01+ Chip Enable pin
'   Valid values:
'       TX mode:
'           0: Enter Idle mode
'           1: Initiate transmission of queued data
'       RX mode:
'           0: Enter Idle mode
'           1: Active receive mode
    outa[_CE] := state
    time.usleep(core#THCE)

PUB addr_width(bytes): curr_width
' Set width, in bytes, of RX/TX address field
'   Valid values: 3, 4, *5
'   Any other value polls the chip and returns the current setting
    curr_width := 0
    readreg(core#SETUP_AW, 1, @curr_width)
    case bytes
        3, 4, 5:
            bytes -= 2                          ' adjust to bitfield value
        other:
            return ((curr_width & core#AW_BITS) + 2)

    bytes := ((curr_width & core#AW_MASK) | bytes)
    writereg(core#SETUP_AW, 1, @bytes)

PUB after_rx(next_state)
' Define state to transition to after packet rcvd
'   0: Remain in active RX state, ready to receive packets
'   Any other value: Change to RX state, but immediately enter a lower-power
'       Idle/Standby state
    rx_mode{}
    if (next_state)
        idle{}
    else
        chip_ena(1)

PUB auto_ack_pipes_ena(pipe_mask): curr_mask
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
            return (curr_mask & core#EN_AA_MASK)

PUB auto_retrans_cnt(tries): curr_tries
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

    tries := ((curr_tries & core#ARC_MASK) | tries)
    writereg(core#SETUP_RETR, 1, @tries)

PUB auto_retrans_dly(delay_us): curr_dly
' Setup of automatic retransmission - Auto Retransmit Delay, in microseconds
' Delay defined from end of transmission to start of next transmission
'   Valid values: *250..4000 (in steps of 250)
'   Any other value polls the chip and returns the current setting
'   NOTE: The minimum value required for successful transmission depends on the
'       current DataRate() and PayloadLen() settings:
'       DataRate()  PayloadLen() max:   AutoRetransmitDelay() minimum:
'       2_000_000   15                  250
'       2_000_000   Any                 500
'       1_000_000   5                   250
'       1_000_000   Any                 500
'       250_000     8                   750
'       250_000     16                  1000
'       250_000     24                  1250
'       250_000     Any                 1500
    curr_dly := 0
    readreg(core#SETUP_RETR, 1, @curr_dly)
    case delay_us
        250..4000:
            delay_us := ((delay_us / 250) - 1) << core#ARD
        other:
            curr_dly := (((curr_dly >> core#ARD) & core#ARD_BITS) + 1)
            return (curr_dly * 250)

    delay_us := ((curr_dly & core#ARD_MASK) | delay_us)
    writereg(core#SETUP_RETR, 1, @delay_us)

PUB carrier_freq(freq): curr_freq
' Set carrier frequency, in MHz
'   Valid values: 2400..2525 (default 2402)
'   Any other value polls the chip and returns the current setting
    case freq
        2400..2525:
            channel(freq-2400)
        other:
            return (2400 + channel(-2))

PUB channel(number): curr_chan
' Set RF channel
'   Valid values: 0..125 (default 2)
'   Any other value polls the chip and returns the current setting
    case number
        0..125:
            writereg(core#RF_CH, 1, @number)
        other:
            readreg(core#RF_CH, 1, @curr_chan)

PUB crc_check_ena(enabled): curr_state
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
            return (((curr_state >> core#EN_CRC) & 1) == 1)

    enabled := ((curr_state & core#EN_CRC_MASK) | enabled)
    writereg(core#CFG, 1, @enabled)

PUB crc_len(length): curr_len
' Set CRC length, in bytes
'   Valid values: *1, 2
'   Any other value polls the chip and returns the current setting
    curr_len := 0
    readreg(core#CFG, 1, @curr_len)
    case length
        1, 2:
            length := (length-1) << core#CRCO
        other:
            return (((curr_len >> core#CRCO) & 1) + 1)

    length := ((curr_len & core#CRCO_MASK) | length)
    writereg(core#CFG, 1, @length)

PUB data_rate(rate): curr_rate
' Set RF data rate, in bps
'   Valid values: 250_000, 1_000_000, *2_000_000
'   Any other value polls the chip and returns the current setting
    curr_rate := 0
    readreg(core#RF_SETUP, 1, @curr_rate)
    case rate
        1_000_000:
            curr_rate &= core#RF_DR_HIGH_MASK
            curr_rate &= core#RF_DR_LOW_MASK
        2_000_000:
            curr_rate |= (1 << core#RF_DR_HIGH)
            curr_rate &= core#RF_DR_LOW_MASK
        250_000:
            curr_rate &= core#RF_DR_HIGH_MASK
            curr_rate |= (1 << core#RF_DR_LOW)
        other:
            curr_rate := ((curr_rate >> core#RF_DR_HIGH) & core#RF_DR_BITS)
            return lookupz(curr_rate: 1_000_000, 2_000_000, 0, 0, 250_000)

    writereg(core#RF_SETUP, 1, @curr_rate)

PUB dyn_ack_ena(state): curr_state
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
            return (((curr_state >> core#EN_DYN_ACK) & 1) == 1)

    state := ((curr_state & core#EN_DYN_ACK_MASK) | state)
    writereg(core#FEAT, 1, @state)

PUB dyn_payld_len_ena(mask): curr_mask
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
            return (curr_mask & core#DYNPD_MASK)

PUB ack_ena(state): curr_state
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
            return (((curr_state >> core#EN_ACK_PAY) & 1) == 1)

    state := ((curr_state & core#EN_ACK_PAY_MASK) | state)
    writereg(core#FEAT, 1, @state)

PUB flush_rx{}
' Flush receive FIFO buffer
    writereg(core#CMD_FLUSH_RX, 0, 0)

PUB flush_tx{}
' Flush transmit FIFO buffer
    writereg(core#CMD_FLUSH_TX, 0, 0)

PUB freq_dev(freq): curr_freq
' Set frequency deviation, in Hz
'   NOTE: Read-only, for compatibility only
    case data_rate(-2)
        250_000, 1_000_000:
            return 160_000
        2_000_000:
            return 320_000

PUB idle{}
' Set to idle state
    outa[_CE] := 0

PUB int_clear(mask)
' Clear interrupts
'   Valid values: [bits 2..0]
'       Bit:    Interrupt:
'       2       new data is ready in RX FIFO
'       1       data is transmitted (_and_ if ACK from RX if using auto-ack)
'       0       TX retransmits reach maximum
'   Set a bit to 1 to clear the specific interrupt, 0 for no change
'   Any other value is ignored
    case mask
        %000..%111:
            mask <<= core#MASKINT
            writereg(core#STATUS, 1, @mask)
        other:
            return

PUB int_mask(mask): curr_mask
' Control which events will trigger an interrupt on the IRQ pin,
'   Valid values: [bits 2..0]
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

    mask := ((curr_mask & core#MASKINT_MASK) | mask)
    writereg(core#CFG, 1, @mask)

PUB lost_pkts{}: pkt_cnt
' Count lost packets
'   Returns: Number of lost packets since last channel/carrier freq set
'   Max value is 15
'   NOTE: To reset, re-set the Channel or CarrierFreq
    readreg(core#OBSERVE_TX, 1, @pkt_cnt)
    return ((pkt_cnt >> core#PLOS_CNT) & core#PLOS_CNT_BITS)

PUB max_retrans_reached{}: flag
' Flag indicating maximum number of retransmit attempts reached
'   Returns: TRUE (-1) if max reached, FALSE (0) otherwise
'   NOTE: If this flag is set, it must be cleared (IntClear(%001))
'       to enable further communication.
'   NOTE: To set max number of attempts, use AutoRetransmitCount()
    flag := 0
    readreg(core#STATUS, 1, @flag)
    return (((flag >> core#MAX_RT) & 1) == 1)

PUB node_addr(ptr_addr)
' Set node address
'   NOTE: This sets the address for Receive pipe 0 as well as the Transmit
'       address
    rx_addr(ptr_addr, 0, WRITE)
    tx_addr(ptr_addr, WRITE)

PUB pkts_retrans{}: pkt_cnt
' Count retransmitted packets
'   Returns: Number of packets retransmitted since the start of transmission
'       of a new packet
    readreg(core#OBSERVE_TX, 1, @pkt_cnt)
    return (pkt_cnt & core#ARC_CNT)

PUB payld_len(length, pipe_nr): curr_len
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
                    return (curr_len & core#RX_PW_BITS)
        other:
            return

PUB payld_len_cfg(mode): curr_mode
' Set packet length mode
'   Valid values:
'       PKTLEN_FIXED (0): fixed-length packet/payload
'       PKTLEN_VAR (1): variable-length packet/payload
'   Any other value polls the chip and returns the current setting
'   NOTE: Must be PKTLEN_VAR to use the DynamicPayload() method.
    curr_mode := 0
    readreg(core#FEAT, 1, @curr_mode)
    case ||(mode)
        0, 1:
            mode := ||(mode) << core#EN_DPL
        other:
            return (((curr_mode >> core#EN_DPL) & 1) == 1)

    mode := ((curr_mode & core#EN_DPL_MASK) | mode)
    writereg(core#FEAT, 1, @mode)

PUB payld_rdy{}: flag
' Flag indicating received payload ready
'   Returns: TRUE (-1) if interrupt flag asserted, FALSE (0) otherwise
    flag := 0
    readreg(core#STATUS, 1, @flag)
    return (((flag >> core#RX_DR) & 1) == 1)

PUB payld_sent{}: flag
' Flag indicating transmitted payload sent
'   (and acknowledged by receiver, if auto-ack is in use)
    flag := 0
    readreg(core#STATUS, 1, @flag)
    return (((flag >> core#TX_DS) & 1) == 1)

PUB pipes_ena(mask): curr_mask
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
            return (curr_mask & core#EN_ADDR_MASK)

PUB pll_lock(state): curr_state
' Force PLL Lock signal (intended for testing only)
'   Valid values: *FALSE: Disable, TRUE (-1 or 1): Enable.
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#RF_SETUP, 1, @curr_state)
    case ||(state)
        0, 1:
            state := ||(state) << core#PLL_LOCK
        other:
            return (((curr_state >> core#PLL_LOCK) & 1) == 1)

    state := ((curr_state & core#PLL_LOCK_MASK) | state)
    writereg(core#RF_SETUP, 1, @state)

PUB powered(state): curr_state
' Power on or off
'   Valid values: *FALSE: Disable, TRUE (-1 or 1): Enable.
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#CFG, 1, @curr_state)
    case ||(state)
        0, 1:
            state := ||(state) << core#PWR_UP
        other:
            return (((curr_state >> core#PWR_UP) & 1) == 1)

    state := ((curr_state & core#PWR_UP_MASK) | state)
    writereg(core#CFG, 1, @state)

PUB rpd{}: flag
' Received Power Detector/Carrier Detect
'   Returns:
'       FALSE (0): No Carrier
'       TRUE (-1): Carrier Detected
    flag := 0
    readreg(core#RPD, 1, @flag)
    return (flag == 1)

PUB rssi{}: level
' RSSI (emulated)
'   Returns:
'       -64: Carrier detected
'       -255 No carrier
    return lookupz(||(rpd{}): -255, -64)

PUB rx_addr(ptr_buff, pipe, rw)
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

PUB rx_bandw(bw): curr_bw
' Set transceiver bandwidth, in Hz
'   NOTE: Read-only, for compatibility only
    case data_rate(-2)
        250_000, 1_000_000:
            return 1_000_000
        2_000_000:
            return 2_000_000

PUB rx_fifo_empty{}: flag
' Flag indicating RX FIFO empty
'   Returns:
'       TRUE (-1): RX FIFO empty
'       FALSE (0): RX FIFO contains unread data
    flag := 0
    readreg(core#FIFO_STATUS, 1, @flag)
    return ((flag & 1) == 1)

PUB rx_fifo_full{}: flag
' Flag indicating RX FIFO full
'   Returns:
'       TRUE (-1): RX FIFO full
'       FALSE (0): RX FIFO not full
    flag := 0
    readreg(core#FIFO_STATUS, 1, @flag)
    return (((flag >> core#RXFIFO_FULL) & 1) == 1)

PUB rx_mode{}
' Change chip state to RX (receive)
    rx_tx(RX)
    outa[_CE] := 1

PUB rx_payld(nr_bytes, ptr_buff)
' Receive payload stored in FIFO
'   Valid values:
'       nr_bytes: 1..32 (Any other value is ignored)
'   Any other value is ignored
    if lookdown(nr_bytes: 1..32)
        readreg(core#CMD_R_RX_PAYLOAD, nr_bytes, ptr_buff)
    else
        return

PUB rx_pipe_pending{}: pipe_nr
' Returns pipe number of pending data available in FIFO
'   Returns: Pipe number 0..5, or 7 if FIFO is empty
    return ((nrf_status{} >> core#RX_P_NO) & core#RX_P_NO_BITS)

PUB rx_tx(role): curr_role
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

    role := ((curr_role & core#PRIM_RX_MASK) | role)
    writereg(core#CFG, 1, @role)

PUB sleep{}
' Power down chip
    powered(FALSE)

PUB sync_word(ptr_syncwd): curr_syncwd
' Set syncword
    node_addr(ptr_syncwd)

PUB test_cw(state): curr_state
' Enable continuous carrier transmit (intended for testing only)
'   Valid values: *FALSE: Disable, TRUE (-1 or 1): Enable.
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#RF_SETUP, 1, @curr_state)
    case ||(state)
        0, 1:
            state := ||(state) << core#CONT_WAVE
        other:
            return (((curr_state >> core#CONT_WAVE) & 1) == 1)

    state := ((curr_state & core#CONT_WAVE_MASK) | state)
    writereg(core#RF_SETUP, 1, @state)

PUB tx_addr(ptr_addr, rw)
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

PUB tx_fifo_empty{}: flag
' Flag indicating TX FIFO empty
'   Returns TRUE if empty, FALSE if there's data in TX FIFO
    readreg(core#FIFO_STATUS, 1, @flag)
    return (((flag >> core#TXFIFO_EMPTY) & 1) == 1)

PUB tx_fifo_full{}: flag
' Flag indicating TX FIFO full
'   Returns: TRUE if full, FALSE if locations available in TX FIFO
    return ((nrf_status{} & 1) == 1)

PUB tx_mode{}
' Change chip state to TX (transmit)
    rx_tx(TX)

PUB tx_payld(nr_bytes, ptr_buff)
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

PUB tx_pwr(pwr): curr_pwr
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
            curr_pwr := ((curr_pwr >> core#RF_PWR) & core#RF_PWR_BITS)
            return lookupz(curr_pwr: -18, -12, -6, 0)

    pwr := ((curr_pwr & core#RF_PWR_MASK) | pwr)
    writereg(core#RF_SETUP, 1, @pwr)

PUB tx_will_reuse{}: flag
' Flag indicating last transmitted payload is to be re-used
'   Returns:
'       TRUE (-1): last transmitted payload reused, FALSE (0) otherwise
    readreg(core#FIFO_STATUS, 1, @flag)
    return (((flag >> core#TXFIFO_REUSE) & 1) == 1)

PRI nrf_status{}: nrf_status
' Interrupt and data available status
    readreg(core#STATUS, 1, @nrf_status)

PRI writereg(reg_nr, nr_bytes, ptr_buff) | tmp
' Write nr_bytes from ptr_buff to device
    case reg_nr
        core#CMD_W_TX_PAYLOAD:
            outa[_CS] := 0
            spi.wr_byte(reg_nr)
            spi.wrblock_lsbf(ptr_buff, nr_bytes)
            outa[_CS] := 1
        core#CMD_FLUSH_TX, core#CMD_FLUSH_RX:
            outa[_CS] := 0
            spi.wr_byte(reg_nr)
            outa[_CS] := 1
        $00..$17, $1C..$1D:
            reg_nr |= core#W_REG
            case nr_bytes
                0:
                    outa[_CS] := 0
                    spi.wr_byte(reg_nr)
                    outa[_CS] := 1
                1..5:
                    outa[_CS] := 0
                    spi.wr_byte(reg_nr)
                    spi.wrblock_lsbf(ptr_buff, nr_bytes)
                    outa[_CS] := 1
                other:
                    return
        other:
            return

PRI readreg(reg_nr, nr_bytes, ptr_buff) | tmp
' Read nr_bytes from device into ptr_buff
    case reg_nr
        core#CMD_R_RX_PAYLOAD:
            outa[_CS] := 0
            spi.wr_byte(reg_nr)
            spi.rdblock_lsbf(ptr_buff, nr_bytes)
            outa[_CS] := 1
        core#RPD:
            outa[_CS] := 0
            spi.wr_byte(reg_nr)
            byte[ptr_buff][0] := spi.rd_byte{}
            outa[_CS] := 1
        $00..$08, $0A..$17, $1C..$1D:
            case nr_bytes
                1..5:
                    outa[_CS] := 0
                    spi.wr_byte(reg_nr)
                    spi.rdblock_lsbf(ptr_buff, nr_bytes)
                    outa[_CS] := 1
                other:
                    return
        other:
            return

DAT
{
Copyright 2022 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

