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

    LSBFIRST            = 4
    MSBFIRST            = 5

    CPOL                = 0
    CLK_DELAY           = 10
    BITORDER            = MSBFIRST

'' Register definitions
    NRF24_CONFIG        = $00
    NRF24_EN_AA         = $01
    NRF24_EN_RXADDR     = $02
    NRF24_SETUP_AW      = $03
    NRF24_SETUP_RETR    = $04
    NRF24_RF_CH         = $05
    NRF24_RF_SETUP      = $06
    NRF24_STATUS        = $07
    NRF24_OBSERVE_TX    = $08
    NRF24_RPD           = $09
    NRF24_RX_ADDR_P0    = $0A
    NRF24_RX_ADDR_P1    = $0B
    NRF24_RX_ADDR_P2    = $0C
    NRF24_RX_ADDR_P3    = $0D
    NRF24_RX_ADDR_P4    = $0E
    NRF24_RX_ADDR_P5    = $0F
    NRF24_TX_ADDR       = $10
    NRF24_RX_PW_P0      = $11
    NRF24_RX_PW_P1      = $12
    NRF24_RX_PW_P2      = $13
    NRF24_RX_PW_P3      = $14
    NRF24_RX_PW_P4      = $15
    NRF24_RX_PW_P5      = $16
    NRF24_FIFO_STATUS   = $17
    NRF24_DYNPD         = $1C
    NRF24_FEATURE       = $1D

PUB Null
'' This is not a top-level object
