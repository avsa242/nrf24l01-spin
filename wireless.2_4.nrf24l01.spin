{
    --------------------------------------------
    Filename:
    Author:
    Description:
    Copyright (c) 20__
    Started Month Day, Year
    Updated Month Day, Year
    See end of file for terms of use.
    --------------------------------------------
}

CON


VAR


OBJ

    spi:    "SPI_Asm"
    core:   "core.con.nrf24l01"                           'File containing your device's register set
    time:   "time"                                                'Basic timing functions

PUB Null
''This is not a top-level object

PUB Startx(CE_PIN, CSN_PIN, SCK_PIN, MOSI_PIN, MISO_PIN): okay

    if lookdown(CE_PIN: 0..31) and lookdown(CSN_PIN: 0..31) and lookdown(SCK_PIN: 0..31) and lookdown(MOSI_PIN: 0..31) and lookdown(MISO_PIN: 0..31)
        if okay := spi.start (core#CLK_DELAY, core#CPOL)
            time.MSleep (1)

                return okay

    return FALSE                                                'If we got here, something went wrong

PRI readOne: readbyte

    readX (@readbyte, 1)

PRI readX(ptr_buff, num_bytes)
'' Read num_bytes from the slave device into the address stored in ptr_buff
    i2c.start
    i2c.write (SLAVE_RD)
    i2c.pread (ptr_buff, num_bytes, TRUE)
    i2c.stop

PRI writeOne(data)

    WriteX (data, 1)

PRI WriteX(ptr_buff, num_bytes)
'' Write num_bytes to the slave device from the address stored in ptr_buff
    i2c.start
    i2c.write (SLAVE_WR)
    i2c.pwrite (ptr_buff, num_bytes)
    i2c.stop

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
