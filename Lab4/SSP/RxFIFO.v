/*
Recieve FIFO: (series to parallel)
FIFO 8-bit wide, 4-location deep memory buffer
Recieve data from serial interface and store in the buffer until read out by processor 
If full pull SSPRXINTR high and refuse to accept any additional data, lower when not full
Do not consider the case of a read request on an empty FIFO
Data recieved should be written to FIFO in as few cycles as possible
*/

module RxFIFO(PCLK, CLEAR_B, PSEL, PWRITE, SSPCLKIN, SSPFSSIN, SSPRXD
        PRDATA[7:0], SSPOE_B, SSPCLKOUT, SSPRXINTR);
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
    //Once bottom entry of Tx FIFO is written to  SSPFSSOUT is pulsed high for one SSPCLKOUT period
    //The value to be transmitted will be shifted into serial shift register during this pulse. 
    //On next SSPCLKOUT rising edge the MSB of PWDATA is shifed onto SSPTXD pin
    output SSPRXINTR; //If full pull SSPRXINTR high and refuse to accept any additional data, lower when not full

    //Define internal variables here:
    reg [7:0] FIFO [3:0]; //4 bytes of recieving FIFO 
    integer count; //remember which spot in FIFO memory is filled (start at 0, increase each time we recieve)
    //decrement evert time the processor reads the memory?

    always @(posedge PCLK) begin
        if (PSEL) begin //Cannot do anything if enable is not high first
            if (!CLEAR_B) begin //if active low reset is low, reset everything first
                integer i; //for loop to visit every spot in FIFO and wipe
                for (i = 0; i < 8; i = i+1) begin
                    FIFO[i] = 8'b00000000;
                end
                //also reset all internal variables
                count = 0;
            end
            else if (!PWRITE && count >= 1) begin //Here is where processor reads from FIFO (parallel)
                PRDATA = FIFO[count];
                FIFO[count] = 8'b00000000; //Zero out memory in FIFO
                count = count - 1;
            end
        end
        //Outside of PSEL (We can read regardless of if FIFO is being accessed by processor)
        if(!PWRITE && !SSPRXINTR) begin //ensure no interupt (otherwise we cannot read anymore) and we are in write mode
            


        end
    end

    
    always @(negedge PCLK) begin
         //Set SSPRXINTR on negative edge to prevent interrupting signal
         if (count >= 4) begin
             SSPRXINTR = b'1; //initialized to zero in SSP.v
         end
        
    end

endmodule