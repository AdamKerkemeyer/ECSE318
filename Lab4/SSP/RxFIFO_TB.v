module RxFIFO_TB;
    reg PCLK;
    reg CLEAR_B;
    reg PSEL;
    reg PWRITE;
    reg [7:0] RxDATA;
    reg LOGICWRITE;

    wire [7:0] PRDATA;
    wire SSPRXINTR;

    RxFIFO uut (
        .PCLK(PCLK), 
        .CLEAR_B(CLEAR_B), 
        .PSEL(PSEL), 
        .PWRITE(PWRITE), 
        .RxDATA(RxDATA), 
        .LOGICWRITE(LOGICWRITE), 
        .PRDATA(PRDATA), 
        .SSPRXINTR(SSPRXINTR));
    initial begin
        PCLK = 0;
        forever #5 PCLK = ~PCLK;
    end

    initial begin
        CLEAR_B = 0;
        PSEL = 0;
        PWRITE = 0;
        RxDATA = 0;
        LOGICWRITE = 0;

        // Wait for global reset
        #10;
        CLEAR_B = 1;
        PSEL = 1;

        // Write data to FIFO
        LOGICWRITE = 1;
        RxDATA = 8'hA5;
        #10;
        RxDATA = 8'h5A;
        #10;
        RxDATA = 8'h3C;
        #10;
        RxDATA = 8'hC3;
        #10;
        LOGICWRITE = 0;

        // Read data from FIFO
        PWRITE = 0;
        #10;
        PWRITE = 1;
        #10;
        PWRITE = 0;
        #10;
        PWRITE = 1;
        #10;
        PWRITE = 0;
        #10;
        PWRITE = 1;
        #10;
        PWRITE = 0;
        #10;
        PWRITE = 1;
        #10;
        PWRITE = 0;

        // Check FIFO full and empty flags
        #10;
        $display("SSPRXINTR (should be 0): %b", SSPRXINTR);
        $display("PRDATA (should be 8'hC3): %h", PRDATA);
        $stop;
    end

    // Monitor FIFO contents
    always @(posedge PCLK) begin
        if (PSEL) begin
            $display("Time: %0t | W_PTR: %0d | R_PTR: %0d | FIFO[0]: %h | FIFO[1]: %h | FIFO[2]: %h | FIFO[3]: %h | PRDATA: %h", 
                     $time, uut.W_PTR, uut.R_PTR, uut.FIFO[0], uut.FIFO[1], uut.FIFO[2], uut.FIFO[3], PRDATA);
        end
    end

endmodule