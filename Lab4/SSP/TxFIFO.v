/*
Transmit & Recieve Logic:
Transmit seciton will read bytes from transmit FIFO and perform parallel to series conversion
Transmit is synchronyzed to the SSPCLKOUT through SSPTXD and SSPFSSOUT pins
Recieve logic is synchronyzed by SSPCLKIN which is recieved by broadcasting from peripheral
Recieve logic performs serial to parallel conversion on incoming synchronous SSPRXD data stream
*/

module TxFIFO(PCLK, CLEAR_B, PSEL, PWRITE, PWDATA, SSPCLKIN, 
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

    output SSPOE_B; //Active low output enable. It will go low on negative edge of SSPCLKOUT
    //It will go back up on the negative edge of SSPCLKOUT after data transfer (tell when transmission is done)
    output SSPTXD; //Serial data out wire
    output SSPCLKOUT; //Connected to SSPCLKIN, 1/2 speed of PCLK
    output SSPFSSOUT; //Frame control signal for transmission
    //Once bottom entry of Tx FIFO is written to  SSPFSSOUT is pulsed high for one SSPCLKOUT period
    //The value to be transmitted will be shifted into serial shift register during this pulse. 
    //On next SSPCLKOUT rising edge the MSB of PWDATA is shifed onto SSPTXD pin
    output SSPTXINTR; //If full, pull SSPTXINTR high, do not accept additional data when SSPTXINTR is high, lower when not full
    
    //Define internal variables here:
    reg [7:0] FIFO [3:0]; //4 bytes of transmission FIFO 
    integer count = 0; //Space in FIFO that is filed, increase hwne processor gives a new byte to transmit
    //decrement when a full byte is finished transferring and clear it from FIFO. 

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
            else if (PWRITE && !SSPTXINTR) begin//use boolean operator, if it is in write mode and there is no flag
            //This is how we write to the FIFO
                FIFO[count] = PWDATA; 
                count = count + 1;
            end
        end
        //Outside of the PSEL loop we send transmissions because we must keep attempting to send
        //Transmissions until the TxFIFO memory is 0 and counter = 0.
        if(count >= 1) begin //Only run if there is something in the memory, run regardless of 
            


        end

        always @(negedge PCLK) begin
            //Set SSPTXINTR on negative edge to prevent interrupting signal
            if (count >= 4) begin
                SSPTXINTR = b'1; //initialized to zero in SSP.v
            end
            
        end
    end

endmodule