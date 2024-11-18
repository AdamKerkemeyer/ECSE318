/*
Transmit FIFO: (parallel to series)
FIFO 8-bit wide, 4-location deep memory buffer
Data written to SSP module will be stored in the buffer until it is read out by the transmit logic
If full pull SSPTXINTR high, do not accept additional data when SSPTXINTR is high, lower when not full
Do not consider the case of a read request on an empty FIFO
Data written to FIFO should be transferred to transfer logic in as few cycles as possible
*/

module TxFIFO(PCLK, CLEAR_B, PSEL, PWRITE, PWDATA, LOGICWRITE, //all inputs from processor
        TXDATA, SSPTXINTR, EMPTY);
    input PCLK;                             //Clock for SSP (all operations on FIFO and interface are done on this clock)
    input CLEAR_B;                          //Low active clear used to initialize SSP
    input PSEL;                             //Chip select signal, data can only enter or exit SSP when PSEL is high.
    input PWRITE;                           //If 1 then it is writting to SSP to transmit
    input [7:0] PWDATA;                     //Data to transmitt from processor
    input LOGICWRITE;

    output [7:0] TXDATA;                    //Tell Rx/Tx logic what byte to transmit.
    output SSPTXINTR;                       //If full pull SSPTXINTR high and refuse to accept any additional data, lower when not full, interrupt 
    output EMPTY;

    //Define internal variables here:
    reg [7:0] FIFO [3:0];                   //4 bytes of recieving FIFO 
    reg [1:0] W_PTR, R_PTR;                 //read (for sending processor data) and write pointer (coming from logic)
    reg full, empty;                        //Unlike Rx must keep track of both full & empty
    integer count = 0;

    assign SSPRXINTR = full;                //Using "=" lets us tie SSPRXINTR to if the FIFO is full
    assign EMPTY = empty;                   //
    assign TXDATA = FIFO[R_PTR];            //If PWRITE is 0 processor will still be able to access whatever the read pointer is at
    integer i;

    always @(posedge PCLK) begin
        if (PSEL) begin //Cannot do anything if enable is not high first, assuming that includes sending reset
        //There is an issue with where I have embedded PSEL like this because it prohibits internal SSP communication
        //I will add it only to cases where we check PWRITE if there is an issue with the TB
            if (!CLEAR_B) begin 
                for (i = 0; i < 4; i = i+1) begin
                    FIFO[i] <= 8'b00000000;
                end
                W_PTR <= 2'b00;
                R_PTR <= 2'b00;
                full <= 1'b0;
                empty <= 1'b0;
                count <= 0;
            end
            /*There are 3 cases we must handle:
            1. The processor requests to write and the Tx/Rx logic wants to send
            2. The processor requests to write and the Tx/Rx logic does not want to send
            3. The processor does not request to write and the Tx/Rx logic wants to send
            4. The processor does not request to write and the Tx/Rx logic does not want to send (do nothing)
            In no loop do we directly update TXDATA because we already assigned it to always be linked to the Read pointer
            */
            else if (PWRITE && LOGICWRITE) begin
                R_PTR <= R_PTR + 2'b01;
                W_PTR <= W_PTR + 2'b01;
                FIFO[W_PTR] <= PWDATA;
                //full-ness status does not change
            end
            else if (LOGICWRITE) begin //Swap LOGICWRITE and PWRITE from Rx Logic
                R_PTR <= R_PTR + 2'b01;
                full <= 1'b0;
                count <= count + 1;
            end
            else if (PWRITE) begin
               //Since there is no request to also read, we must see if the register is full first
               if(!full) begin
                    W_PTR <= W_PTR + 2'b01;
                    FIFO[W_PTR] <= PWDATA;
                    empty <= 1'b0;
                    count <= count - 1;
                end
            end
            //Otherwise we do no FIFO operations. 
            if (count >= 3) begin
                full <= 1'b1;
                empty <= ~full;
            end
            else if (count < 0) begin
                empty <= 1'b1;
                full <= ~empty;
            end
        end
    end
endmodule