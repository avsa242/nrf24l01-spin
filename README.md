# nrf24l01-spin
---------------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for the Nordic Semiconductor nRF24L01+ IC.

## Salient Features

* SPI connection at up to 1MHz (P1), up to _TBD_ (P2)
* Supports setting carrier frequency from 2,400MHz to 2,527MHz
* Set common RF parameters: TX power
* Supports on-air baud rates of 250kbps, 1000kbps, 2000kbps
* Address filtering: 3, 4, 5 bytes address width (pipes 2..5: only the LSByte is changeable)
* Options for increasing transmission robustness: CRC calculation/checking (1 or 2 byte length)
* Packet radio options: arbitrary payload lengths (1..32), dynamic payload length
* Supports setting frequency by channel number (0..127)
* RSSI measurement (*operates as a carrier-detect function only*)
* FIFO: Read RX/TX states (empty, full, data ready, data sent), flush
* Optional auto acknowledgement function (aka Enhanced ShockBurst (TM) NORDIC Semiconductor), auto-retransmit count, auto-retransmit delay, max number of retries
* Selectively enable pipes (0..5), with some settings changeable on a per-pipe basis (payload length, address, address width)
* Interrupts based on any combination of: New RX data ready, data transmitted, max number of retransmits reached
* Packet stats: Lost packet count, retransmitted packet count
* Power on/off
* RF Testing modes: Force PLL lock, CW mode

## Requirements

* P1: 1 additional core/cog, for the PASM SPI driver
* P2: N/A

## Compiler Compatibility

* P1/SPIN1: OpenSpin (tested with 1.00.81)
* P2/SPIN2: FastSpin (tested with 4.1.0-beta)

## Limitations

* Very early in development - may malfunction, or outright fail to build
* API not yet stable

## TODO

- [x] Create some simple demos
- [ ] Enhance the test harness to include verification

