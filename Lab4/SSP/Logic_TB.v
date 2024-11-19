//This TB does not work
module Logic_TB;
    reg PCLK;
    reg SSPCLKIN;
    reg CLEAR_B;
    reg SSPFSSIN;
    reg SSPRXD;
    reg [7:0] TxDATA;
    reg TxEMPTY;

    wire SSPOE_B;
    wire SSPFSSOUT;
    wire SSPCLKOUT;
    wire SSPTXD;
    wire TxLOGICWRITE;
    wire RxLOGICWRITE;
    wire [7:0] RxDATA;
    logic uut (
        .PCLK(PCLK), 
        .SSPCLKIN(SSPCLKIN), 
        .CLEAR_B(CLEAR_B), 
        .SSPFSSIN(SSPFSSIN), 
        .SSPRXD(SSPRXD), 
        .TxDATA(TxDATA), 
        .TxEMPTY(TxEMPTY), 
        .SSPCLKOUT(SSPCLKOUT), 
        .SSPOE_B(SSPOE_B), 
        .SSPFSSOUT(SSPFSSOUT), 
        .SSPTXD(SSPTXD), 
        .TxLOGICWRITE(TxLOGICWRITE), 
        .RxLOGICWRITE(RxLOGICWRITE), 
        .RxDATA(RxDATA)
    );

    initial begin
        PCLK = 0;
        forever #5 PCLK = ~PCLK;
    end

    initial begin
        SSPCLKIN = 0;
        forever #10 SSPCLKIN = ~SSPCLKIN;
    end
    initial begin
        // Initialize Inputs
        CLEAR_B = 0;
        SSPFSSIN = 0;
        SSPRXD = 0;
        TxDATA = 8'h00;
        TxEMPTY = 1;

        // Wait for global reset
        #10;
        CLEAR_B = 1;

        // Transmission Test
        TxDATA = 8'hA5;
        TxEMPTY = 0;
        #20;
        TxEMPTY = 1;
        #40;

        // Reception Test
        SSPFSSIN = 1;
        SSPRXD = 1;
        #10;
        SSPRXD = 0;
        #10;
        SSPRXD = 1;
        #10;
        SSPRXD = 0;
        #10;
        SSPRXD = 1;
        #10;
        SSPRXD = 0;
        #10;
        SSPRXD = 1;
        #10;
        SSPRXD = 0;
        #10;
        SSPFSSIN = 0;
        // Check Outputs
        #20;
        $display("SSPOE_B: %b", SSPOE_B);
        $display("SSPFSSOUT: %b", SSPFSSOUT);
        $display("SSPCLKOUT: %b", SSPCLKOUT);
        $display("SSPTXD: %b", SSPTXD);
        $display("TxLOGICWRITE: %b", TxLOGICWRITE);
        $display("RxLOGICWRITE: %b", RxLOGICWRITE);
        $display("RxDATA: %h", RxDATA);
        $stop;
    end
    // Monitor Outputs
    always @(posedge PCLK) begin
        $display("Time: %0t | SSPCLKOUT: %b | SSPOE_B: %b | SSPFSSOUT: %b | SSPTXD: %b | TxLOGICWRITE: %b | RxLOGICWRITE: %b | RxDATA: %h", 
                 $time, SSPCLKOUT, SSPOE_B, SSPFSSOUT, SSPTXD, TxLOGICWRITE, RxLOGICWRITE, RxDATA);
    end

endmodule