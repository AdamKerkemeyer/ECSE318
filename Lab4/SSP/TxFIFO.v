/*
Transmit & Recieve Logic:
Transmit seciton will read bytes from transmit FIFO and perform parallel to series conversion
Transmit is synchronyzed to the SSPCLKOUT through SSPTXD and SSPFSSOUT pins
Recieve logic is synchronyzed by SSPCLKIN which is recieved by broadcasting from peripheral
Recieve logic performs serial to parallel conversion on incoming synchronous SSPRXD data stream
*/

module TxFIFO(PCLK, CLEAR_B, PSEL, PWRITE, PWDATA, SSPCLKIN, SSPFSSIN, 
        SSPOE_B, SSPTXD, SSPCLKOUT, SSPFSSOUT, SSPTXINTR);
    //Input is first row, output is second
    input PCLK; //Clock for SSP (all operations on FIFO and interface are done on this clock)
    input CLEAR_B; //Low active clear used to initialize SSP
    input PSEL; //Chip select signal, data can only enter or exit SSP when PSEL is high.
    //PSEL restriction only applies to reading and transmitting data (PWDATA and PRDATA)
    //Anything in FIFO should finish being sent or recieved before stopping.
    //Can we use the interrupt flags for this?
    input PWRITE; //If 1 then it is writting to SSP to transmit
    input [7:0] PWDATA; //8-bit data to be transmitted
    input SSPCLKIN; //Sync clock for recieving data, 1/2 speed of PCLK
    input SSPFSSIN; //Frame control signal for reception
    //Data can be recieved at next rising edge of SSPCLKIN once this is high, the reciever od SSPFSSOUT

    output SSPOE_B; //Active low output enable. It will go low on negative edge of SSPCLKOUT
    //It will go back up on the negative edge of SSPCLKOUT after data transfer (tell when transmission is done)
    output SSPTXD; //Serial data out wire
    output SSPCLKOUT; //Connected to SSPCLKIN, 1/2 speed of PCLK
    output SSPFSSOUT; //Frame control signal for transmission
    //Once bottom entry of Tx FIFO is written to  SSPFSSOUT is pulsed high for one SSPCLKOUT period
    //The value to be transmitted will be shifted into serial shift register during this pulse. 
    //On next SSPCLKOUT rising edge the MSB of PWDATA is shifed onto SSPTXD pin
    output SSPTXINTR; //If full, pull SSPTXINTR high, do not accept additional data when SSPTXINTR is high, lower when not full


endmodule