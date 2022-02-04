# nrf24l01-spin
---------------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for the Nordic Semiconductor nRF24L01+ IC.

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* SPI connection at 4MHz (P1), up to 10MHz (P2)
* Supports setting carrier frequency from 2,400MHz to 2,525MHz, or by equiv. channel number
* Set common RF parameters: TX power
* Supports on-air baud rates of 250kbps, 1000kbps, 2000kbps
* Address filtering: 3, 4, 5 bytes address width (for pipes 0, 1 only; pipes 2..5: only the LSByte is changeable)
* Options for increasing transmission robustness: CRC calculation/checking (1 or 2 byte length)
* Packet radio options: arbitrary payload lengths (1..32), dynamic payload length
* Carrier-detect
* FIFO: Read RX/TX states (empty, full, data ready, data sent), flush
* Optional auto acknowledgement function (aka Enhanced ShockBurst (TM) NORDIC Semiconductor), auto-retransmit count, auto-retransmit delay, max number of retries
* Selectively enable pipes (0..5), with some settings changeable on a per-pipe basis (payload length, address, address width)
* Interrupts based on any combination of: New RX data ready, data transmitted, max number of retransmits reached (driver doesn't directly support the IRQ pin - only reading/clearing the interrupt state register)
* Packet stats: Lost packet count, retransmitted packet count
* Power on/off
* RF Testing modes: Force PLL lock, CW mode

## Requirements

P1/SPIN1:
* spin-standard-library
* P1: 1 additional core/cog, for the PASM SPI engine

P2/SPIN2:
* p2-spin-standard-library

## Compiler Compatibility

* P1/SPIN1 OpenSpin (bytecode): Untested (deprecated)
* P1/SPIN1 FlexSpin (bytecode): OK, tested with 5.9.7-beta
* P1/SPIN1 FlexSpin (native): OK, tested with 5.9.7-beta
* ~~P2/SPIN2 FlexSpin (nu-code): FTBFS, tested with 5.9.7-beta~~
* P2/SPIN2 FlexSpin (native): OK, tested with 5.9.7-beta
* ~~BST~~ (incompatible - no preprocessor)
* ~~Propeller Tool~~ (incompatible - no preprocessor)
* ~~PNut~~ (incompatible - no preprocessor)

## Limitations

* P2/SPIN2: MOSI and MISO I/O pins must be within 3 pins of SCK
* API not yet stable
* RSSI method is only an alias for RPD(), which returns a receive power detect/carrier-detect flag. For wireless.transceiver API compatibility only

