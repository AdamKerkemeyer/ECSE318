module TxFIFO_TB;
    reg PCLK;
    reg CLEAR_B;
    reg PSEL;
    reg PWRITE;
    reg [7:0] PWDATA;
    reg LOGICWRITE;

    wire [7:0] TxDATA;
    wire SSPTXINTR;
    wire EMPTY;

    TxFIFO uut (
        .PCLK(PCLK), 
        .CLEAR_B(CLEAR_B), 
        .PSEL(PSEL), 
        .PWRITE(PWRITE), 
        .PWDATA(PWDATA), 
        .LOGICWRITE(LOGICWRITE), 
        .TxDATA(TxDATA), 
        .SSPTXINTR(SSPTXINTR), 
        .EMPTY(EMPTY)
    );

    initial begin
        PCLK = 0;
        forever #5 PCLK = ~PCLK; // 100 MHz clock
    end

    initial begin
        CLEAR_B = 0;
        PSEL = 0;
        PWRITE = 0;
        PWDATA = 0;
        LOGICWRITE = 0;

        // Wait for global reset
        #10;
        CLEAR_B = 1;
        PSEL = 1;

        // Write data to FIFO
        PWRITE = 1;
        PWDATA = 8'hA5;
        #10;
        PWDATA = 8'h5A;
        #10;
        PWDATA = 8'h3C;
        #10;
        PWDATA = 8'hC3;
        #10;
        PWRITE = 0;

        // Read data from FIFO
        LOGICWRITE = 1;
        #10;
        LOGICWRITE = 0;
        #10;
        LOGICWRITE = 1;
        #10;
        LOGICWRITE = 0;
        #10;
        LOGICWRITE = 1;
        #10;
        LOGICWRITE = 0;
        #10;
        LOGICWRITE = 1;
        #10;
        LOGICWRITE = 0;

        #10;
        $display("SSPTXINTR (should be 0): %b", SSPTXINTR);
        $display("EMPTY (should be 1): %b", EMPTY);
        $stop;
    end

    always @(posedge PCLK) begin
        if (PSEL) begin
            $display("Time: %0t | W_PTR: %0d | R_PTR: %0d | FIFO[0]: %h | FIFO[1]: %h | FIFO[2]: %h | FIFO[3]: %h | TxDATA: %h", 
                     $time, uut.W_PTR, uut.R_PTR, uut.FIFO[0], uut.FIFO[1], uut.FIFO[2], uut.FIFO[3], TxDATA);
        end
    end

endmodule