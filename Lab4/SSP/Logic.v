/*
Transmit & Recieve Logic:
Transmit seciton will read bytes from transmit FIFO and perform parallel to series conversion
Transmit is synchronyzed to the SSPCLKOUT through SSPTXD and SSPFSSOUT pins
Recieve logic is synchronyzed by SSPCLKIN which is recieved by broadcasting from peripheral
Recieve logic performs serial to parallel conversion on incoming synchronous SSPRXD data stream
*/

module logic(PCLK, SSPCLKIN, CLEAR_B, SSPFSSIN, SSPRXD, TXDATA, TxEMPTY
        SSPOE_B, SSPFSSOUT, SSPTXD, TxLOGICWRITE, RxLOGICWRITE, RXDATA);
    //Inputs:
    input PCLK;                 //Clock for SSP
    input SSPCLKIN;             //Sync clock for recieving data, 1/2 speed of PCLK
    input CLEAR_B;              //Low active clear used to initialize SSP
    input SSPFSSIN;             //Frame control signal for reception
    input SSPRXD;               //Serial Data In Wire
    //Outputs:
    output SSPOE_B;             //Active low output enable. It will go low on negative edge of SSPCLKOUT
                                //It will go back up on the negative edge of SSPCLKOUT after data transfer (tell when transmission is done)
    output SSPFSSOUT;           //Frame control signal for transmission
    output SSPCLKOUT;           //Sync clock for sending data, 1/2 speed of PCLK
    output SSPTXD;              //Serial Data Out Wire
    //Internal in/out wires to Tx and Rx FIFO:
    output TxLOGICWRITE;        //Logic Write for Tx
    output RxLOGICWRITE;        //Logic Write for Rx
    input TxEMPTY;              //See if Tx is full
    input [7:0] TXDATA;         //From Tx, byte to transmit.
    output [7:0] RXDATA;        //To Rx, byte recieved.

    //Internal variables:
    reg slowCLK = 1'b0;
    assign SSPCLKOUT = slowCLK; 

    //Even though we output a slow clock, the system should run at PCLK, need to remember slowCLK state however:
    wire highSlowCLJ = (slowCLK == 1'b1);   

    //For the sake of readability I am going to put transmit and recieve in two seperate always blocks with seperate declarations
    //Transmission:
    reg [7:0] transmit = 8'b00000000;
    reg TxWrite;
    reg sspoeB;
    reg beginTransmit;
    reg [3:0] TxCount = 4'b0000;      //Remember how many shifts have occured
    
    assign SSPOE_B = sspoeB;
    assign TxLOGICWRITE = TxWrite;
    assign SSPFSSOUT = beginTransmit;
    assign SSPTXD = transmit[7];    //Whatever is in last spot of transmit register will be on wire
    /*
    For the transmission to work, we need a number of things to be true:
    1. Tx FIFO is not empty (~TxEMPTY)
    2. PWRITE is 1
    3. TxLOGICWRITE is set to high (TxWrite <= 1)
    4. CLEAR_B is high (active low)
    */
    always @(posedge PCLK) begin
        
    end
    always @(*) begin                   //MSB is sent first
        if(!slowCLK) begin              //SSPCLKOUT is low

        end
    end
    //Recieve
    reg [7:0] recieve = 8'b00000000;


    //Run Regardless:
    always @(posedge PCLK) begin
        slowCLK <= ~slowCLK;    //1/2 speed because this clock switches only on pos. edge of PCLK.
        if (!CLEAR_B) begin
            SSPCLKOUT <= 1'b0;
            transmit <= 8'b00000000;
            recieve <= 8'b00000000;
            RxData <= 8'b00000000;
            TxLOGICWRITE <= 0;
            RxLOGICWRITE <= 0;
            
        end
    end
endmodule

`timescale 1 ns / 10 ps

module ssp_tx_rx (
    input PCLK,
    input CLEAR_B,
    input SSPCLKIN, SSPFSSIN, SSPRXD,
    input [7:0] TxData,
    input TxValidWord, TxIsEmpty,
    output TxNextWord,
    output [7:0] RxData,
    output RxNextWord,
    output SSPCLKOUT, SSPFSSOUT, SSPTXD, SSPOE_B
);

reg ssp_out_clk_div = 1'b0;
assign SSPCLKOUT = ssp_out_clk_div;

always @(posedge PCLK) ssp_out_clk_div <= ~ssp_out_clk_div;

wire update_state = (ssp_out_clk_div == 1'b0);
wire pre_update_state = (ssp_out_clk_div == 1'b1);

reg [7:0] shift_out = 8'b0;
reg TxNextWord_lcl, SSPOE_B_lcl;
reg [3:0] tx_state, tx_next_state;
parameter [3:0]
    tx_idle = 4'd0, tx_load = 4'd1, tx_shift7 = 4'd2, tx_shift6 = 4'd3,
    tx_shift5 = 4'd4, tx_shift4 = 4'd5, tx_shift3 = 4'd6, tx_shift2 = 4'd7,
    tx_shift1 = 4'd8, tx_shift0 = 4'd9, tx_shift0_load = 4'd10;

wire tx_loading = (tx_state == tx_load) || (tx_state == tx_shift0_load);

assign SSPTXD = shift_out[7];
assign TxNextWord = TxNextWord_lcl;
assign SSPOE_B = SSPOE_B_lcl;
assign SSPFSSOUT = tx_loading;

always @(posedge PCLK) begin
    if (~CLEAR_B)
        tx_state <= tx_idle;
    else
        tx_state <= tx_next_state;
end

always @(*) begin
    if (update_state) begin
        case (tx_state)
            tx_idle: tx_next_state <= ~TxIsEmpty ? tx_load : tx_idle;
            tx_load: tx_next_state <= tx_shift7;
            tx_shift7: tx_next_state <= tx_shift6;
            tx_shift6: tx_next_state <= tx_shift5;
            tx_shift5: tx_next_state <= tx_shift4;
            tx_shift4: tx_next_state <= tx_shift3;
            tx_shift3: tx_next_state <= tx_shift2;
            tx_shift2: tx_next_state <= tx_shift1;
            tx_shift1: tx_next_state <= ~TxIsEmpty ? tx_shift0_load : tx_shift0;
            tx_shift0: tx_next_state <= tx_idle;
            tx_shift0_load: tx_next_state <= tx_shift7;
            default: tx_next_state <= tx_idle;
        endcase
    end else
        tx_next_state <= tx_state;
end

always @(posedge PCLK) begin
    if (update_state) begin
        case (tx_state)
            tx_load, tx_shift0_load: shift_out <= TxData;
            default: shift_out <= {shift_out[6:0], 1'b0};
        endcase
    end
end

always @(*) TxNextWord_lcl <= update_state && tx_loading;

always @(posedge PCLK) begin
    if (tx_loading && pre_update_state)
        SSPOE_B_lcl <= 1'b0;
    else if ((tx_state == tx_idle) && pre_update_state)
        SSPOE_B_lcl <= 1'b1;
end

reg [7:0] shift_in = 8'b0;
reg RxNextWord_lcl;
reg SSPCLKIN_prev;
reg [3:0] rx_state, rx_next_state;
parameter [3:0]
    rx_idle = 4'd0, rx_shift7 = 4'd1, rx_shift6 = 4'd2, rx_shift5 = 4'd3,
    rx_shift4 = 4'd4, rx_shift3 = 4'd5, rx_shift2 = 4'd6, rx_shift1 = 4'd7,
    rx_shift0 = 4'd8;

assign RxData = shift_in;
assign RxNextWord = RxNextWord_lcl;

always @(posedge PCLK) SSPCLKIN_prev <= SSPCLKIN;

wire SSPCLKIN_fall = SSPCLKIN_prev && ~SSPCLKIN;
wire SSPCLKIN_rise = ~SSPCLKIN_prev && SSPCLKIN;

always @(posedge PCLK) begin
    if (~CLEAR_B)
        rx_state <= rx_idle;
    else
        rx_state <= rx_next_state;
end

always @(*) begin
    if (SSPCLKIN_fall) begin
        case (rx_state)
            rx_idle: rx_next_state <= SSPFSSIN ? rx_shift7 : rx_idle;
            rx_shift7: rx_next_state <= rx_shift6;
            rx_shift6: rx_next_state <= rx_shift5;
            rx_shift5: rx_next_state <= rx_shift4;
            rx_shift4: rx_next_state <= rx_shift3;
            rx_shift3: rx_next_state <= rx_shift2;
            rx_shift2: rx_next_state <= rx_shift1;
            rx_shift1: rx_next_state <= rx_shift0;
            rx_shift0: rx_next_state <= SSPFSSIN ? rx_shift7 : rx_idle;
            default: rx_next_state <= rx_idle;
        endcase
    end else
        rx_next_state <= rx_state;
end

always @(posedge PCLK) begin
    if (SSPCLKIN_fall)
        shift_in <= {shift_in[6:0], SSPRXD};
end

always @(posedge PCLK) begin
    if ((rx_state == rx_shift0) && SSPCLKIN_rise)
        RxNextWord_lcl <= 1'b1;
    else
        RxNextWord_lcl <= 1'b0;
end

endmodule