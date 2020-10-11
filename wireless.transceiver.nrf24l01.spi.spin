{
    --------------------------------------------
    Filename: wireless.transceiver.nrf24l01.spi.spin
    Author: Jesse Burt
    Description: Driver for Nordic Semi. nRF24L01+
    Copyright (c) 2020
    Started Jan 6, 2019
    Updated Oct 5, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    ROLE_TX     = 0
    ROLE_RX     = 1

' RXAddr and TXAddr constants
    READ        = 0
    WRITE       = 1

' Can be used as a parameter for PayloadReady, PayloadSent, MaxRetransReached to clear interrupts
    CLEAR       = 1

VAR

    byte    _CE, _CSN, _SCK, _MOSI, _MISO
    word    _status

OBJ

    spi     : "com.spi.bitbang"
    core    : "core.con.nrf24l01"
    time    : "time"
    io      : "io"

PUB Null
''This is not a top-level object

PUB Startx(CE_PIN, CSN_PIN, SCK_PIN, MOSI_PIN, MISO_PIN): okay | tmp[2], i

    if lookdown(CE_PIN: 0..31) and lookdown(CSN_PIN: 0..31) and lookdown(SCK_PIN: 0..31) and lookdown(MOSI_PIN: 0..31) and lookdown(MISO_PIN: 0..31)
        if okay := spi.start (CSN_PIN, SCK_PIN, MOSI_PIN, MISO_PIN)
            _CE := CE_PIN
            _CSN := CSN_PIN
            _SCK := SCK_PIN
            _MOSI := MOSI_PIN
            _MISO := MISO_PIN
            time.USleep(core#TPOR)
            time.USleep(core#TPD2STBY)

            io.Low(_CE)
            io.Output(_CE)

            Defaults                                            ' The nRF24L01+ has no RESET pin or function,
                                                                '   so set defaults
            RXAddr(@tmp, 0, READ)                               ' There's also no 'ID' register, so read in the
            repeat i from 0 to 4                                '   address for pipe #0.
                if tmp.byte[i] <> $E7                           ' If bytes read back are different from the default,
                    return FALSE                                '   there's either a connection problem, or
            return okay                                         '   no nRF24L01+ connected.
                                                                ' NOTE: This is only guaranteed to work after
                                                                '   setting defaults.
    return FALSE                                                ' If we got here, something went wrong

PUB Stop

    io.High(_CSN)
    io.Low(_CE)
    Sleep
    spi.Stop

PUB Defaults | tmp[2]
' The nRF24L01+ has no RESET pin or function to restore the chip to a known initial operating state,
'   so use this method to establish default settings, per the datasheet
    CRCCheckEnabled(TRUE)
    CRCLength(1)
    Sleep
    TXMode
    AutoAckEnabledPipes(%111111)
    PipesEnabled(%000011)
    AddressWidth(5)
    AutoRetransmitDelay(250)
    AutoRetransmitCount(3)
    Channel(2)
    TESTCW(FALSE)
    PLL_Lock(FALSE)
    DataRate(2000)
    TXPower(0)
    PayloadReady(CLEAR)
    PayloadSent(CLEAR)
    MaxRetransReached(CLEAR)
    tmp := string($E7, $E7, $E7, $E7, $E7)
    RXAddr(tmp, 0, WRITE)
    tmp := string($C2, $C2, $C2, $C2, $C2)
    RXAddr(tmp, 1, WRITE)
    tmp := $C3
    RXAddr(@tmp, 2, WRITE)
    tmp := $C4
    RXAddr(@tmp, 3, WRITE)
    tmp := $C5
    RXAddr(@tmp, 4, WRITE)
    tmp := $C6
    RXAddr(@tmp, 5, WRITE)
    tmp := string($E7, $E7, $E7, $E7, $E7)
    TXAddr(tmp, WRITE)
    repeat tmp from 0 to 5
        PayloadLen(0, tmp)
    DynamicPayload(%000000)
    DynPayloadEnabled(FALSE)
    EnableACK(FALSE)

PUB CE(state)
' Set state of nRF24L01+ Chip Enable pin
'   Valid values:
'       TX mode:
'           0: Enter Idle mode
'           1: Initiate transmission of queued data
'       RX mode:
'           0: Enter Idle mode
'           1: Active receive mode
    io.Set(_CE, state)
    time.USleep (core#THCE)

PUB AddressWidth(bytes): curr_width
' Set width, in bytes, of RX/TX address field
'   Valid values: 3, 4, 5
'   Any other value polls the chip and returns the current setting
    curr_width := 0
    readReg (core#SETUP_AW, 1, @curr_width)
    case bytes
        3, 4, 5:
            bytes -= 2                          ' adjust to bitfield value
        OTHER:
            return (curr_width & core#AW_BITS) + 2

    bytes := ((curr_width & core#AW_MASK) | bytes) & core#SETUP_AW_REGMASK
    writeReg (core#SETUP_AW, 1, @bytes)

PUB AfterRX (next_state)
' Define state to transition to after packet rcvd
'   0: Remain in active RX state, ready to receive packets
'   Any other value: Change to RX state, but immediately enter a lower-power Idle/Standby state
    RXTX(ROLE_RX)
    if next_state
        Idle
    else
        CE(1)

PUB AutoAckEnabledPipes(pipe_mask): curr_mask
' Enable the Auto Acknowledgement function (aka Enhanced ShockBurst - (TM) NORDIC Semi.)
'   per set data pipe mask:
'   Data Pipe:     5    0   5    0
'                  |....|   |....|
'   Valid values: %000000..%111111
'   0 disables AA for the given pipe, 1 enables
'   Example:
'       AutoAckEnabledPipes(%001010)
'           would enable AA for data pipes 1 and 3, and disable for all others
    curr_mask := 0
    readReg (core#EN_AA, 1, @curr_mask)
    case pipe_mask
        %000000..%111111:
        OTHER:
            return curr_mask & core#EN_AA_REGMASK

    writeReg (core#EN_AA, 1, @pipe_mask)

PUB AutoRetransmitDelay(delay_us): curr_dly
' Setup of automatic retransmission - Auto Retransmit Delay, in microseconds
' Delay defined from end of transmission to start of next transmission
'   Valid values: 250..4000
'   Any other value polls the chip and returns the current setting
    curr_dly := 0
    readReg (core#SETUP_RETR, 1, @curr_dly)
    case delay_us := lookdown(delay_us: 250, 500, 750, 1000, 1250, 1500, 1750, 2000, 2250, 2500, 2750, 3000, 3250, 3500, 3750, 4000)
        1..16:
            delay_us := (delay_us - 1) << core#ARD
        OTHER:
            curr_dly := ((curr_dly >> core#ARD) & core#ARD_BITS) + 1
            return lookup(curr_dly: 250, 500, 750, 1000, 1250, 1500, 1750, 2000, 2250, 2500, 2750, 3000, 3250, 3500, 3750, 4000)

    delay_us := ((curr_dly & core#ARD_MASK) | delay_us) & core#SETUP_RETR_REGMASK
    writeReg (core#SETUP_RETR, 1, @delay_us)

PUB AutoRetransmitCount(tries): curr_tries
' Setup of automatic retransmission - Auto Retransmit Count
' Defines number of attempts to re-transmit on fail of Auto-Acknowledge
'   Valid values: 0..15 (0 disables re-transmit)
'   Any other value polls the chip and returns the current setting
    curr_tries := 0
    readReg (core#SETUP_RETR, 1, @curr_tries)
    case tries
        0..15:
        OTHER:
            return (curr_tries & core#ARC_BITS)

    tries := ((curr_tries & core#ARC_MASK) | tries) & core#SETUP_RETR_REGMASK
    writeReg (core#SETUP_RETR, 1, @tries)

PUB CarrierFreq(MHz): curr_freq
' Set carrier frequency, in MHz
'   Valid values: 2400..2527
'   Any other value polls the chip and returns the current setting
    case MHz
        2400..2527:
            Channel(MHz-2400)
        OTHER:
            return 2400 + Channel(-2)

PUB Channel(number): curr_chan
' Set RF channel
'   Valid values: 0..127
'   Any other value polls the chip and returns the current setting
    case number
        0..127:
            writeReg (core#RF_CH, 1, @number)
        OTHER:
            readReg (core#RF_CH, 1, @curr_chan)

PUB CRCCheckEnabled(enabled): curr_state
' Enable CRC
' NOTE: Forced on if any data pipe has AutoAck enabled
'   Valid values: FALSE: Disable, TRUE (-1 or 1): Enable.
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readReg (core#CONFIG, 1, @curr_state)
    case ||enabled
        0, 1:
            enabled := ||enabled << core#EN_CRC
        OTHER:
            return ((curr_state >> core#EN_CRC) & %1) == 1

    enabled := ((curr_state & core#EN_CRC_MASK) | enabled) & core#CONFIG_REGMASK
    writeReg (core#CONFIG, 1, @enabled)

PUB CRCLength(bytes): curr_len
' Choose CRC Encoding scheme, in bytes
'   Valid values: 1, 2
'   Any other value polls the chip and returns the current setting
    curr_len := 0
    readReg (core#CONFIG, 1, @curr_len)
    case bytes
        1, 2:
            bytes := (bytes-1) << core#CRCO
        OTHER:
            return ((curr_len >> core#CRCO) & %1) + 1

    bytes := ((curr_len & core#CRCO_MASK) | bytes) & core#CONFIG_REGMASK
    writeReg (core#CONFIG, 1, @bytes)

PUB DataRate(kbps): curr_rate
' Set RF data rate in kbps
'   Valid values: 250, 1000, 2000
'   Any other value polls the chip and returns the current setting
    curr_rate := 0
    readReg (core#RF_SETUP, 1, @curr_rate)
    case kbps
        1000:
            curr_rate &= core#RF_DR_HIGH_MASK
            curr_rate &= core#RF_DR_LOW_MASK
        2000:
            curr_rate |= (1 << core#RF_DR_HIGH)
            curr_rate &= core#RF_DR_LOW_MASK
        250:
            curr_rate &= core#RF_DR_HIGH_MASK
            curr_rate |= (1 << core#RF_DR_LOW)
        OTHER:
            curr_rate := (curr_rate >> core#RF_DR_HIGH) & %101  'Only care about the RF_DR_x bits
            return lookupz(curr_rate: 1000, 2000, 0, 0, 250)

    writeReg (core#RF_SETUP, 1, @curr_rate)

PUB DynamicACK(enabled): curr_state
' Enable selective auto-acknowledge feature
' When enabled, the receive will not auto-acknowledge packets sent to it.
' XXX expand
'   Valid values: FALSE: Disable, TRUE (-1 or 1): Enable.
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readReg (core#FEATURE, 1, @curr_state)
    case ||enabled
        0, 1:
            enabled := ||enabled << core#EN_DYN_ACK
        OTHER:
            return ((curr_state >> core#EN_DYN_ACK) & %1) == 1

    enabled := ((curr_state & core#EN_DYN_ACK_MASK) | enabled) & core#FEATURE_REGMASK
    writeReg (core#FEATURE, 1, @enabled)

PUB DynamicPayload(mask): curr_mask
' Control which data pipes (0 through 5) have dynamic payload length enabled, using a 6-bit mask
'   Data pipe:     5    0   5     0
'                  |....|   |.....|
'   Valid values: %000000..%1111111
    curr_mask := 0
    readReg (core#DYNPD, 1, @curr_mask)
    case mask
        %000000..%111111:
'            mask := (mask << core#ERX_P0)      ' shows what _would_ be done
        OTHER:
            return curr_mask & core#DYNPD_REGMASK

    writeReg (core#DYNPD, 1, @mask)

PUB DynPayloadEnabled(enabled): curr_state
' Enable Dynamic Payload Length
' NOTE: Must be enabled to use the DynamicPayload method.
'   Valid values: FALSE: Disable, TRUE (-1 or 1): Enable.
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readReg (core#FEATURE, 1, @curr_state)
    case ||enabled
        0, 1:
            enabled := ||enabled << core#EN_DPL
        OTHER:
            return ((curr_state >> core#EN_DPL) & core#EN_DPL) == 1

    enabled := ((curr_state & core#EN_DPL_MASK) | enabled) & core#FEATURE_REGMASK
    writeReg (core#FEATURE, 1, @enabled)

PUB EnableACK(enabled): curr_state
' Enable payload with ACK
' XXX Add timing notes/code from datasheet, p.63, note d
'   Valid values: FALSE: Disable, TRUE (-1 or 1): Enable.
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readReg (core#FEATURE, 1, @curr_state)
    case ||(enabled)
        0, 1:
            enabled := ||(enabled) << core#EN_ACK_PAY
        OTHER:
            return ((curr_state >> core#EN_ACK_PAY) & core#EN_ACK_PAY) == 1

    enabled := ((curr_state & core#EN_ACK_PAY_MASK) | enabled) & core#FEATURE_REGMASK
    writeReg (core#FEATURE, 1, @enabled)

PUB FlushRX{}
' Flush receive FIFO buffer
    writeReg (core#CMD_FLUSH_RX, 0, 0)

PUB FlushTX{}
' Flush transmit FIFO buffer
    writeReg (core#CMD_FLUSH_TX, 0, 0)

PUB Idle{}
' Set to idle state
    CE(0)

PUB IntMask(mask): curr_mask
' Control which events will trigger an interrupt on the IRQ pin, using a 3-bit mask
'           Bits:  210   210
'                  |||   |||
'   Valid values: %000..%111
'       Bit:    Interrupt will be asserted on IRQ pin if:
'       2       new data is ready in RX FIFO
'       1       data is transmitted (_and_ if ACK from RX if using auto-ack)
'       0       TX retransmits reach maximum
'   Set a bit to 0 to disable the specific interrupt, 1 to enable
'   Any other value polls the chip and returns the current setting
    curr_mask := 0
    readReg (core#CONFIG, 1, @curr_mask)
    case mask
        %000..%111:
            mask := !(mask << core#MASKINT)     ' invert bits: chip internal
        OTHER:                                  '   logic is inverse
            return !(curr_mask >> core#MASKINT) & core#MASKINT_BITS

    mask := ((curr_mask & core#MASKINT_MASK) | mask) & core#CONFIG_REGMASK
    writeReg (core#CONFIG, 1, @mask)

PUB LostPackets{}: pkt_cnt
' Count lost packets
'   Returns: Number of lost packets since last channel/carrier freq set
'   Max value is 15
'   NOTE: To reset, re-set the Channel or CarrierFreq
    readReg (core#OBSERVE_TX, 1, @pkt_cnt)
    return (pkt_cnt >> core#PLOS_CNT) & core#PLOS_CNT_BITS

PUB MaxRetransReached(clear_intr): flag
' Query or clear Maximum number of TX retransmits interrupt
'   Valid values: TRUE (-1 or 1): Clear interrupt flag
'   Any other value returns TRUE when max number of retransmits reached, FALSE otherwise
'   NOTE: If this flag is set, it must be cleared to enable further communication.
    flag := 0
    readReg (core#STATUS, 1, @flag)
    case ||(clear_intr)
        1:
            clear_intr := %1 << core#MAX_RT
        OTHER:
            return ((flag >> core#MAX_RT) & %1) == 1

    clear_intr := ((flag & core#MAX_RT_MASK) | clear_intr) & core#STATUS_REGMASK
    writeReg (core#STATUS, 1, @clear_intr)

PUB NodeAddress(addr_ptr)
' Set node address
'   NOTE: This sets the address for Receive pipe 0 as well as the Transmit address
    RXAddr(addr_ptr, 0, WRITE)
    TXAddr(addr_ptr, WRITE)

PUB PacketsRetransmitted{}: pkt_cnt
' Count retransmitted packets
'   Returns: Number of packets retransmitted since the start of transmission of a new packet
    readReg (core#OBSERVE_TX, 1, @pkt_cnt)
    return pkt_cnt & core#ARC_CNT

PUB PayloadLen(width, pipe_nr): curr_len
' Set length of static payload, in bytes
'   Returns number of bytes in RX payload in data pipe, or 0 if pipe unused
'   Valid values:
'       pipe: 0..5 (default 0)
'       width: 0..32
'   Any other value for pipe is ignored
'   Any other value for width polls the chip and returns the current setting
'   NOTE: Setting a width of 0 effectively disables the pipe
    curr_len := 0
    case pipe_nr
        0..5:
            readReg (core#RX_PW_P0 + pipe_nr, 1, @curr_len)
            case width
                0..32:
                    writeReg (core#RX_PW_P0 + pipe_nr, 1, @width)
                    return width
                OTHER:
                    return curr_len & core#RX_PW_BITS

        OTHER:
            return FALSE

PUB PayloadReady(clear_intr): flag
' Query or clear Data Ready RX FIFO interrupt
'   Valid values: TRUE (-1 or 1): Clear interrupt flag
'   Any other value queries the chip and returns TRUE if new data in FIFO, FALSE otherwise
    flag := 0
    readReg (core#STATUS, 1, @flag)
    case ||(clear_intr)
        1:
            clear_intr := ||(clear_intr) << core#RX_DR
        OTHER:
            return ((flag >> core#RX_DR) & %1) == 1

    clear_intr := ((flag & core#MASKINT_RX_DR_MASK) | clear_intr) & core#STATUS_REGMASK
    writeReg (core#STATUS, 1, @clear_intr)

PUB PayloadSent(clear_intr): flag
' Query or clear Data Sent TX FIFO interrupt
'   Valid values: TRUE (-1 or 1): Clear interrupt flag
'   Any other value polls the chip and returns TRUE if packet transmitted, FALSE otherwise
    flag := 0
    readReg (core#STATUS, 1, @flag)
    case ||(clear_intr)
        1:
            clear_intr := ||(clear_intr) << core#TX_DS
        OTHER:
            return ((flag >> core#TX_DS) & %1) == 1

    clear_intr := ((flag & core#MASKINT_TX_DS_MASK) | clear_intr) & core#STATUS_REGMASK
    writeReg (core#STATUS, 1, @clear_intr)

PUB PipesEnabled(mask): curr_mask
' Control which data pipes (0 through 5) are enabled, using a 6-bit mask
'   Data pipe:     5    0   5    0
'                  |....|   |....|
'   Valid values: %000000..%111111
    case mask
        %000000..%111111:
            writeReg (core#EN_RXADDR, 1, @mask)
        OTHER:
            curr_mask := 0
            readreg(core#EN_RXADDR, 1, @curr_mask)
            return curr_mask & core#EN_RXADDR_MASK

PUB PLL_Lock(enabled): flag
' Force PLL Lock signal (intended for testing only)
'   Valid values: FALSE: Disable, TRUE (-1 or 1): Enable.
'   Any other value polls the chip and returns the current setting
    flag := 0
    readReg (core#RF_SETUP, 1, @flag)
    case ||(enabled)
        0, 1:
            enabled := ||(enabled) << core#PLL_LOCK
        OTHER:
            return ((flag >> core#PLL_LOCK) & %1) == 1

    enabled := ((flag & core#PLL_LOCK_MASK) | enabled) & core#RF_SETUP_REGMASK
    writeReg (core#RF_SETUP, 1, @enabled)

PUB Powered(enabled): curr_state
' Power on or off
'   Valid values: FALSE: Disable, TRUE (-1 or 1): Enable.
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readReg (core#CONFIG, 1, @curr_state)
    case ||(enabled)
        0, 1:
            enabled := ||(enabled) << core#PWR_UP
        OTHER:
            return ((curr_state >> core#PWR_UP) & %1) == 1

    enabled := ((curr_state & core#PWR_UP_MASK) | enabled) & core#CONFIG_REGMASK
    writeReg (core#CONFIG, 1, @enabled)

PUB RPD{}: flag
' Received Power Detector
'   Returns:
'       FALSE (0): No Carrier
'       TRUE (-1): Carrier Detected
    flag := 0
    readReg (core#RPD, 1, @flag)
    return flag == 1

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
    case pipe
        0, 1:
            case rw
                1:
                    writeReg (core#RX_ADDR_P0 + pipe, 5, ptr_buff)
                OTHER:
                    readReg (core#RX_ADDR_P0 + pipe, 5, ptr_buff)
                    return
        2..5:                                   ' Pipes 2..5 are limited to
            case rw                             ' 1 unique byte
                1:                              ' (hardware limitation)
                    writeReg (core#RX_ADDR_P0 + pipe, 1, ptr_buff)
                OTHER:
                    readReg (core#RX_ADDR_P0 + pipe, 1, ptr_buff)
                    return
        OTHER:                                  ' Invalid pipe
            return

PUB RXFIFOEmpty{}: flag
' Flag indicating RX FIFO empty
'   Returns:
'       TRUE (-1): RX FIFO empty
'       FALSE (0): RX FIFO contains unread data
    flag := 0
    readReg (core#FIFO_STATUS, 1, @flag)
    return (flag & %1) == 1

PUB RXFIFOFull{}: flag
' Flag indicating RX FIFO full
'   Returns:
'       TRUE (-1): RX FIFO full
'       FALSE (0): RX FIFO not full
    flag := 0
    readReg (core#FIFO_STATUS, 1, @flag)
    return ((flag >> core#RXFIFO_FULL) & %1) == 1

PUB RXMode{}
' Change chip state to RX (receive)
    RXTX(ROLE_RX)
    CE(1)

PUB RXPayload(nr_bytes, ptr_buff)
' Receive payload stored in FIFO
'   Valid values:
'       nr_bytes: 1..32 (Any other value is ignored)
'   Any other value is ignored
    case nr_bytes
        1..32:
            readReg (core#CMD_R_RX_PAYLOAD, nr_bytes, ptr_buff)
        OTHER:
            return

PUB RXPipePending{}: pipe_nr
' Returns pipe number of pending data available in FIFO
'   Returns: Pipe number 0..5, or 7 if FIFO is empty
    return (Status{} >> core#RX_P_NO) & core#RX_P_NO_BITS

PUB RXTX(role): curr_role
' Set to Primary RX or TX
'   Valid values: 0: TX, 1: RX
'   Any other value polls the chip and returns the current setting
    curr_role := 0
    readReg (core#CONFIG, 1, @curr_role)
    case role
        0, 1:
            role := role << core#PRIM_RX
        OTHER:
            return ((curr_role >> core#PRIM_RX) & %1)

    role := ((curr_role & core#PRIM_RX_MASK) | role) & core#CONFIG_REGMASK
    writeReg (core#CONFIG, 1, @role)

PUB Sleep{}
' Power down chip
    Powered(FALSE)

PUB TESTCW(enabled): curr_state
' Enable continuous carrier transmit (intended for testing only)
'   Valid values: FALSE: Disable, TRUE (-1 or 1): Enable.
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readReg (core#RF_SETUP, 1, @curr_state)
    case ||(enabled)
        0, 1:
            enabled := ||(enabled) << core#CONT_WAVE
        OTHER:
            return ((curr_state >> core#CONT_WAVE) & %1) == 1

    enabled := ((curr_state & core#CONT_WAVE_MASK) | enabled) & core#RF_SETUP_REGMASK
    writeReg (core#RF_SETUP, 1, @enabled)

PUB TXAddr(ptr_buff, rw) | tmp[2]
' Set transmit address
'   Valid values:
'       ptr_buff:
'           Address of buffer containing nRF24L01+ address to transmit to
'       rw:
'           0: Read current address
'           1: Write new address
'           Any other value reads current address
' NOTE: Buffer at ptr_buff must be a minimum of 5 bytes
    bytefill(@tmp, $00, 8)
    readReg (core#TX_ADDR, 5, @tmp)

    case rw
        1:
        OTHER:
            bytemove(ptr_buff, @tmp, 5)
            return

    writeReg (core#TX_ADDR, 5, ptr_buff)

PUB TXFIFOEmpty{}
' Queries the FIFO_STATUS register for TX FIFO empty flag
'   Returns TRUE if empty, FALSE if there's data in TX FIFO
    readReg (core#FIFO_STATUS, 1, @result)
    result &= (1 << core#TXFIFO_EMPTY) * TRUE

PUB TXFIFOFull{}
' Returns TX FIFO full flag
'   Returns: TRUE if full, FALSE if locations available in TX FIFO
    result := (Status & %1) * TRUE

PUB TXMode
' Change chip state to TX (transmit)
    RXTX(ROLE_TX)

PUB TXPayload(nr_bytes, ptr_buff, deferred) | cmd_packet, tmp
' Queue payload to be transmitted   'XXX remove deferred param, make new method and hub var
'   Valid values:
'       nr_bytes: 1..32 (Any other value is ignored)
'       deferred:
'           FALSE(0): Transmit immediately after queuing data
'           Any other value: Queue data only, don't transmit
    case nr_bytes
        1..32:
            writeReg (core#CMD_W_TX_PAYLOAD, nr_bytes, ptr_buff)
            ifnot deferred                                          ' Transmit immediately
                outa[_CE] := 1
                time.USleep (core#THCE)
                outa[_CE] := 0
        OTHER:
            return FALSE

PUB TXPower(dBm) | tmp
' Set transmit mode RF output power, in dBm
'   Valid values: -18, -12, -6, 0
'   Any other value polls the chip and returns the current setting
    readReg (core#RF_SETUP, 1, @tmp)
    case dBm
        -18, -12, -6, 0:
            dBm := lookdownz(dBm: -18, -12, -6, 0)
            dBm := dBm << core#RF_PWR
        OTHER:
            tmp := (tmp >> core#RF_PWR) & core#RF_PWR_BITS
            result := lookupz(tmp: -18, -12, -6, 0)
            return

    tmp &= core#RF_PWR_MASK
    tmp := (tmp | dBm) & core#RF_SETUP_REGMASK
    writeReg (core#RF_SETUP, 1, @tmp)

PUB TXReuse{}
' Queries the FIFO_STATUS register for TX_REUSE flag
'   Returns TRUE if re-using last transmitted payload, FALSE if not
    readReg (core#FIFO_STATUS, 1, @result)
    result &= (1 << core#TXFIFO_REUSE) * TRUE

PRI Status
' Returns status of last SPI transaction
    readReg (core#STATUS, 1, @result)

PRI writeReg (reg, nr_bytes, ptr_buff) | tmp
' Write reg to MOSI
    case reg
        core#CMD_W_TX_PAYLOAD:
            spi.Write(TRUE, @reg, 1, 0)
            spi.Write(TRUE, ptr_buff, nr_bytes, TRUE)

        core#CMD_FLUSH_TX:
            spi.Write(TRUE, @reg, 1, TRUE)
        core#CMD_FLUSH_RX:
            spi.Write(TRUE, @reg, 1, TRUE)
        $00..$17, $1C..$1D:
            reg |= core#W_REG
            case nr_bytes
                0:
                    spi.Write(TRUE, @reg, 1, TRUE)
                1..5:
                    spi.Write(TRUE, @reg, 1, FALSE)
                    spi.Write(TRUE, ptr_buff, nr_bytes, TRUE)
                OTHER:
                    result := FALSE
                    ptr_buff := 0
        OTHER:
            return FALSE

PRI readReg (reg, nr_bytes, ptr_buff) | tmp
' Read reg from MISO
    case reg
        core#CMD_R_RX_PAYLOAD:
            spi.Write(TRUE, @reg, 1, FALSE)
            spi.Read(ptr_buff, nr_bytes, TRUE)

        core#RPD:
            spi.Write(TRUE, @reg, 1, FALSE)
            spi.Read(ptr_buff, 1, TRUE)

        $00..$08, $0A..$17, $1C..$1D:
            case nr_bytes
                1..5:
                    spi.Write(TRUE, @reg, 1, FALSE)
                    spi.Read(ptr_buff, nr_bytes, TRUE)
                OTHER:
                    result := FALSE
                    ptr_buff := 0

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
