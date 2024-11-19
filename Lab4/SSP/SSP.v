/* Problem 1
Bits are transmitted sequentially from an address in memory
Once an entire word (byte) has been read store in memory
We will create a synchronous communication protol (clocked)
SSP must perform parallel to serial conversion on data recieved from processor
SSP must perform serial to parallel conversion on data recieved from peripherals
Support 4 bytes to be stored independently in both Tx and Rx modes. 

input ports: PCLK, CLEAR\_B, PSEL, PWRITE, PWDATA[7:0], SSPCLKIN, SSPFSSIN, SSPRXD
output ports: PRDATA[7:0], SSPOE\_B, SSPTXD, SSPCLKOUT, SSPFSSOUT, \\SSPTXINTR, SSPRXINTR

My plan:
(if time) write a TB for each module since there will likely be issues in both
Rx will be like opposite of Tx, these will both only manage the FIFO.
Create seperate logic for sending and recieving the signals by bit
The SSP Tb will only directly interface with the SSP but some wires will pass through
*/
module SSP(PCLK, CLEAR_B, PSEL, PWRITE, PWDATA[7:0], SSPCLKIN, SSPFSSIN, SSPRXD,
        PRDATA[7:0], SSPOE_B, SSPTXD, SSPCLKOUT, SSPFSSOUT, SSPTXINTR, SSPRXINTR);
                        //Input is first row, output is second
    input PCLK;         //Clock for SSP (all operations on FIFO and interface are done on this clock)
    input CLEAR_B;      //Low active clear used to initialize SSP
    input PSEL;         //Chip select signal, data can only enter or exit SSP when PSEL is high.
                        //PSEL restriction only applies to reading and transmitting data (PWDATA and PRDATA)
                        //Anything in FIFO should finish being sent or recieved before stopping.
                        //Can we use the interrupt flags for this?
    input PWRITE;       //If 1 then it is writting to SSP to transmit
    input PWDATA[7:0];  //8-bit data to be transmitted
    input SSPCLKIN;     //Sync clock for recieving data, 1/2 speed of PCLK
    input SSPFSSIN;     //Frame control signal for reception
                        //Data can be recieved at next rising edge of SSPCLKIN once this is high, the reciever od SSPFSSOUT
    input SSPRXD;       //Serial Data in wire

    output PRDATA[7:0]; //Where output data is written
    output SSPOE_B;     //Active low output enable. It will go low on negative edge of SSPCLKOUT
                        //It will go back up on the negative edge of SSPCLKOUT after data transfer (tell when transmission is done)
    output SSPTXD;      //Serial data out wire
    output SSPCLKOUT;   //Connected to SSPCLKIN, 1/2 speed of PCLK
    output SSPFSSOUT;   //Frame control signal for transmission
                        //Once bottom entry of Tx FIFO is written to  SSPFSSOUT is pulsed high for one SSPCLKOUT period
                        //The value to be transmitted will be shifted into serial shift register during this pulse. 
                        //On next SSPCLKOUT rising edge the MSB of PWDATA is shifed onto SSPTXD pin
    output SSPTXINTR;   //If full, pull SSPTXINTR high, do not accept additional data when SSPTXINTR is high, lower when not full
    output SSPRXINTR;   //If full pull SSPRXINTR high and refuse to accept any additional data, lower when not full
    
    //instantiate Rx and Tx modules
    //Connect Rx inputs to Tx outputs, this will happen in TB however, don't directly implement them
    
    wire TxLOGICWRITE, RxLOGICWRITE, TxEMPTY;
    wire [7:0] rxDATA, txDATA;

    Rx_FIFO rx(
        .PCLK(PCLK),
        .CLEAR_B(CLEAR_B),
        .PSEL(PSEL),
        .PWRITE(PWRITE),
        .RxDATA(RxDATA),
        .LOGICWRITE(RxLOGICWRITE),
        .PRDATA(PRDATA),
        .SSPRXINTR(SSPRXINTR)
   );

    Tx_FIFO Tx(
        .PCLK(PCLK),
        .CLEAR_B(CLEAR_B),
        .PSEL(PSEL),
        .PWRITE(PWRITE),
        .PWDATA(PWDATA),
        .LOGICWRITE(TxLOGICWRITE),
        .EMPTY(TxEMPTY),
        .TxDATA(TxDATA),
        .SSPTXINTR(SSPTXINTR)
    );

    Logic logic(
        .PCLK(PCLK),
        .SSPCLKIN(SSPCLKIN),
        .CLEAR_B(CLEAR_B),
        .SSPFSSIN(SSPFSSIN),
        .SSPRXD(SSPRXD),
        .TxDATA(TxDATA),
        .TxLOGICWRITE(TxLOGICWRITE),
        .TxEMPTY(TxEMPTY),
        .RxDATA(RxDATA),
        .RxLOGICWRITE(RxLOGICWRITE),
        .SSPCLKOUT(SSPCLKOUT),
        .SSPFSSOUT(SSPFSSOUT),
        .SSPTXD(SSPTXD),
        .SSPOE_B(SSPOE_B)
       );    
endmodule