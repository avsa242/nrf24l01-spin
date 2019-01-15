{
    --------------------------------------------
    Filename: core.con.nrf24l01.spin
    Author: Jesse Burt
    Description: nRF24L01+ Low-level constant definitions
    Copyright (c) 2019
    Started Jan 6, 2019
    Updated Jan 6, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON
' SPI Configuration
    CPOL                        = 0
    CLK_DELAY                   = 10
    MOSI_BITORDER               = 5             'MSBFIRST
    MISO_BITORDER               = 0             'MSBPRE
    CE_TX                       = 0
    CE_RX                       = 1

' NRF24L01+ Commands
    NRF24_R_REG                 = %000_00000
    NRF24_W_REG                 = %001_00000
    NRF24_R_RX_PAYLOAD          = %0110_0001
    NRF24_W_TX_PAYLOAD          = %1010_0000
    NRF24_FLUSH_TX              = %1110_0001
    NRF24_FLUSH_RX              = %1110_0010
    NRF24_REUSE_TX_PL           = %1110_0011
    NRF24_R_RX_PL_WID           = %0110_0000
    NRF24_W_ACK_PAYLOAD         = %10101_000
    NRF24_W_TX_PAYLOAD_NOACK    = %1011_0000
    NRF24_NOP                   = %1111_1111


' Register definitions (individual fields set in/read from registers are indented)
    NRF24_CONFIG                = $00
        FLD_PRIM_RX             = 0             ' Set TX/RX mode
        FLD_PWR_UP              = 1
        FLD_CRCO                = 2
        FLD_EN_CRC              = 3
        FLD_MASK_MAX_RT         = 4
        FLD_MASK_TX_DS          = 5
        FLD_MASK_RX_DR          = 6

    NRF24_EN_AA                 = $01           ' Set $00 to disable ShockBurst
        FLD_ENAA_P0             = 0
        FLD_ENAA_P1             = 1
        FLD_ENAA_P2             = 2
        FLD_ENAA_P3             = 3
        FLD_ENAA_P4             = 4
        FLD_ENAA_P5             = 5

    NRF24_EN_RXADDR             = $02
        FLD_ERX_P0              = 0
        FLD_ERX_P1              = 1
        FLD_ERX_P2              = 2
        FLD_ERX_P3              = 3
        FLD_ERX_P4              = 4
        FLD_ERX_P5              = 5

    NRF24_SETUP_AW              = $03
        FLD_AW                  = 0
        MASK_AW                 = %11

    NRF24_SETUP_RETR            = $04
        FLD_ARD                 = 4
        MASK_ARD                = %1111
        FLD_ARC                 = 0
        MASK_ARC                = %1111

    NRF24_RF_CH                 = $05           ' RF Channel frequency. F0 = 2400 + RF_CH (MHz)
        FLD_RF_CH               = 0
        MASK_RF_CH              = %1111111

    NRF24_RF_SETUP              = $06           'XXX UNEXPECTED POR VALUE ($00 - expected $0E)
        FLD_RF_PWR              = 1             ' Power Amplifier
        MASK_RF_PWR             = %11
        FLD_RF_DR_HIGH          = 3             ' RF Data rates
        FLD_PLL_LOCK            = 4
        FLD_RF_DR_LOW           = 5
                                                ' Bit 6 reserved - set to 0
        FLD_CONT_WAVE           = 7
        FLD_CONT_WAVE_MASK      = $BF ^ (1 << FLD_CONT_WAVE)

    NRF24_STATUS                = $07
        FLD_TX_FULL             = 0
        FLD_RX_P_NO             = 1
        MASK_RX_P_NO            = %111
        FLD_MAX_RT              = 4
        FLD_TX_DS               = 5
        FLD_RX_DR               = 6

    NRF24_OBSERVE_TX            = $08
        FLD_ARC_CNT             = 0            ' Retransmission count (current transaction)
        MASK_ARC_CNT            = %1111
        FLD_PLOS_CNT            = 4            ' Retransmission count (since last channel change)
        MASK_PLOS_CNT           = %1111

    NRF24_RPD                   = $09           ' Received Power Detector (RPD). Bit 0: > -64dBm = 1, < -64dBm = 0
        FLD_RPD                 = 0

    NRF24_RX_ADDR_P0            = $0A
    NRF24_RX_ADDR_P1            = $0B
    NRF24_RX_ADDR_P2            = $0C
        MASK_RX_ADDR_P2         = $FF
    NRF24_RX_ADDR_P3            = $0D
        MASK_RX_ADDR_P3         = $FF
    NRF24_RX_ADDR_P4            = $0E
        MASK_RX_ADDR_P4         = $FF
    NRF24_RX_ADDR_P5            = $0F
        MASK_RX_ADDR_P5         = $FF

    NRF24_TX_ADDR               = $10
'        MASK_TX_ADDR            = $FF_FF_FF_FF_FF

    NRF24_RX_PW_P0              = $11
        FLD_RX_PW_P0            = 0
        MASK_RX_PW_P0           = %111111
    NRF24_RX_PW_P1              = $12
        FLD_RX_PW_P1            = 0
        MASK_RX_PW_P1           = %111111
    NRF24_RX_PW_P2              = $13
        FLD_RX_PW_P2            = 0
        MASK_RX_PW_P2           = %111111
    NRF24_RX_PW_P3              = $14
        FLD_RX_PW_P3            = 0
        MASK_RX_PW_P3           = %111111
    NRF24_RX_PW_P4              = $15
        FLD_RX_PW_P4            = 0
        MASK_RX_PW_P4           = %111111
    NRF24_RX_PW_P5              = $16
        FLD_RX_PW_P5            = 0
        MASK_RX_PW_P5           = %111111

    NRF24_FIFO_STATUS           = $17
        FLD_RXFIFO_EMPTY        = 0
        FLD_RXFIFO_FULL         = 1
        FLD_TXFIFO_EMPTY        = 4
        FLD_TXFIFO_FULL         = 5
        FLD_TXFIFO_REUSE        = 6

    NRF24_DYNPD                 = $1C
        FLD_DPL_P0              = 0
        FLD_DPL_P1              = 0
        FLD_DPL_P2              = 0
        FLD_DPL_P3              = 0
        FLD_DPL_P4              = 0
        FLD_DPL_P5              = 0

    NRF24_FEATURE               = $1D
        FLD_EN_DYN_ACK          = 0
        FLD_EN_ACK_PAY          = 1
        FLD_EN_DPL              = 2

PUB Null
'' This is not a top-level object
