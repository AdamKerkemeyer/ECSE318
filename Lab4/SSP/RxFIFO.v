/*
Recieve FIFO: (series to parallel)
FIFO 8-bit wide, 4-location deep memory buffer
Recieve data from serial interface and store in the buffer until read out by processor 
If full pull SSPRXINTR high and refuse to accept any additional data, lower when not full
Do not consider the case of a read request on an empty FIFO
Data recieved should be written to FIFO in as few cycles as possible
*/

module RxFIFO(PCLK, CLEAR_B, PSEL, PWRITE, SSPCLKIN, SSPFSSIN, SSPRXD
        PRDATA[7:0], SSPOE_B, SSPCLKOUT, SSPFSSOUT, SSPRXINTR);
    //Input is first row, output is second
    input PCLK; //Clock for SSP (all operations on FIFO and interface are done on this clock)
    input CLEAR_B; //Low active clear used to initialize SSP
    input PSEL; //Chip select signal, data can only enter or exit SSP when PSEL is high.
    //PSEL restriction only applies to reading and transmitting data (PWDATA and PRDATA)
    //Anything in FIFO should finish being sent or recieved before stopping.
    //Can we use the interrupt flags for this?
    input PWRITE; //If 1 then it is writting to SSP to transmit
    input SSPCLKIN; //Sync clock for recieving data, 1/2 speed of PCLK
    input SSPFSSIN; //Frame control signal for reception
    //Data can be recieved at next rising edge of SSPCLKIN once this is high, the reciever od SSPFSSOUT
    input SSPRXD; //Serial Data in wire

    output [7:0] PRDATA; //Where output data is written
    output SSPOE_B; //Active low output enable. It will go low on negative edge of SSPCLKOUT
    //It will go back up on the negative edge of SSPCLKOUT after data transfer (tell when transmission is done)
    output SSPCLKOUT; //Connected to SSPCLKIN, 1/2 speed of PCLK
    output SSPFSSOUT; //Frame control signal for transmission
    //Once bottom entry of Tx FIFO is written to  SSPFSSOUT is pulsed high for one SSPCLKOUT period
    //The value to be transmitted will be shifted into serial shift register during this pulse. 
    //On next SSPCLKOUT rising edge the MSB of PWDATA is shifed onto SSPTXD pin
    output SSPRXINTR; //If full pull SSPRXINTR high and refuse to accept any additional data, lower when not full


endmodule