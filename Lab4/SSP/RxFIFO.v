/*
Recieve FIFO: (series to parallel)
FIFO 8-bit wide, 4-location deep memory buffer
Recieve data from serial interface and store in the buffer until read out by processor 
If full pull SSPRXINTR high and refuse to accept any additional data, lower when not full
Do not consider the case of a read request on an empty FIFO
Data recieved should be written to FIFO in as few cycles as possible
*/

module RxFIFO(PCLK, CLEAR_B, PSEL, PWRITE, RxDATA, LOGICWRITE, //PCLK, CLEAR_B, PSEL, and PWRITE are from processor ,RxDATA is from t/r logic
        PRDATA, SSPRXINTR);
    input PCLK;                 //Clock for SSP (all operations on FIFO and interface are done on this clock)
    input CLEAR_B;              //Low active clear used to initialize SSP
    input PSEL;                 //Chip select signal, data can only enter or exit SSP when PSEL is high.
    input PWRITE;               //If 1 then it is writting to SSP to transmit
    input [7:0] RxDATA;         //Transmit/Recieve logic is putting this into a byte for us, Rx just must keep track of the FIFO.
    input LOGICWRITE;           //INTERNAL, tell if Rx/Tx logic has something to write to Rx.

    output [7:0] PRDATA;        //Where output data is written and then read by processor
    output SSPRXINTR;           //If full pull SSPRXINTR high and refuse to accept any additional data, lower when not full, interrupt 

    //Define internal variables here:
    reg [7:0] FIFO [3:0];       //4 bytes of recieving FIFO 
    reg [1:0] W_PTR, R_PTR;     //read (for sending processor data) and write pointer (coming from logic)
    reg full;               //Set to 1 if we have 4 elements, (could also use a counter, but we can figure that out with pointers)
    integer count;
    initial begin
        full <= 0;
        count <= 0;
    end

    assign SSPRXINTR = full;    //Using "=" lets us tie SSPRXINTR to if the FIFO is full

    assign PRDATA = FIFO[R_PTR];//If PWRITE is 1 processor will still be able to access whatever the read pointer is at
    //It was not clear if PRDATA needed to return only 0 if PSEL and PWRITE aren't 1 and 0 respectively, or if just not updating is fine
    integer i;

    always @(posedge PCLK) begin
        if (PSEL) begin //Cannot do anything if enable is not high first, assuming that includes sending reset
            if (!CLEAR_B) begin 
                for (i = 0; i < 4; i = i+1) begin
                    FIFO[i] <= 8'b00000000;
                end
                W_PTR <= 2'b00;
                R_PTR <= 2'b00;
                full <= 1'b0;
                count <= 0;
            end
            /*There are 3 cases we must handle:
            1. The processor requests to read and the Tx/Rx logic has something to write
            2. The processor requests to read and the Tx/Rx logic has nothing to write 
            3. The processor does not request to read and the Tx/Rx logic has nothing to write
            4. The processor does not request to read and the Tx/Rx logic has nothing to write (do nothing)
            In no loop do we directly update PRDATA because we already assigned it to always be linked to the Read pointer
            */
            else if (!PWRITE && LOGICWRITE) begin
                R_PTR <= R_PTR + 2'b01;
                W_PTR <= W_PTR + 2'b01;
                FIFO[W_PTR] <= RxDATA;
                //full-ness status does not change
            end
            else if (!PWRITE) begin
                R_PTR <= R_PTR + 2'b01;
                full <= 1'b0;
                count <= count - 1;
            end
            else if (LOGICWRITE) begin
               //Since there is no request to also read, we must see if the register is full first
               if(!full) begin
                    W_PTR <= W_PTR + 2'b01;
                    FIFO[W_PTR] <= RxDATA;
                    count <= count + 1;
                end
            end
            //Otherwise we do no FIFO operations. 
            if (count >= 3) begin
                full <= 1'b1;
            end
        end
    end
endmodule