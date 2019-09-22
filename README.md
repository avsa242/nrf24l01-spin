# nrf24l01-spin
---------------

This is a P8X32A/Propeller driver object for the Nordic Semiconductor nRF24L01+ IC.

## Salient Features

* SPI connection at up to 1MHz
* TX/RX roles
* Optional auto acknowledgement function (Enhanced ShockBurst (TM) NORDIC Semiconductor)
* Set address width (3, 4, 5 bytes)
* Set auto-retransmit delay
* Set Auto-retransmit count/number of retries
* Set channels 0..127 (check local regulations for allowable channels)
* Set length (1, 2 bytes) of optional CRC
* Payload w/ACK
* Dynamic payload length
* Enable specific pipes
* Enable interrupts based on any combination of: New RX data ready, data transmitted, max number of retransmits
* Packet stats: Lost packet count, retransmitted packet count
* Set max number of retransmits
* Power on/off
* Set data rate to 250kbps, 1Mbps, 2Mbps
* Force PLL lock, CW tests
* Received Power Detector/Carrier Detect flag
* Set individual pipe addresses
* TX/RX FIFO flags: Empty, Full, Data ready, Data Sent

## Requirements

* 1 additional core/cog, for the PASM SPI driver

## Limitations

* API not yet stable
* No demo code, therefore no real-world functionality testing yet

## TODO

- [ ] Create some simple demos
- [ ] Enhance the test harness to include verification

