module CSA (A, B, C, S, CO);
parameter N = 8;
input [N-1:0] A, B, C;
output [N-1:0] S, CO;

assign S = A ^ B ^ C;
assign CO = (A&B)|(B&C)|(A&C);

endmodule

module Tx8A (A, B, C, D, E, F, G, H, I, J, S);
input [7:0] A, B, C, D, E, F, G, H, I, J;
output [15:0] S;

wire [7:0] s1a, s1b;
wire [8:0] s2a, s2b;
wire [9:0] s3a, s3b;
wire [10:0] s4a, s4b;
wire [11:0] s5a, s5b;
wire [12:0] s6a, s6b;
wire [13:0] s7a, s7b;
wire [14:0] s8a, s8b;


CSA #(.N(8)) S1(A, B, C, s1a, s1b);
CSA #(.N(9)) S2({1'b0,s1a}, {s1b,1'b0}, {1'b0,D}, s2a, s2b);
CSA #(.N(10)) S3({1'b0,s2a}, {s2b,1'b0}, {2'b00,E}, s3a, s3b);
CSA #(.N(11)) S4({1'b0,s3a}, {s3b,1'b0}, {3'b000,F}, s4a, s4b);
CSA #(.N(12)) S5({1'b0,s4a}, {s4b,1'b0}, {4'b0000,G}, s5a, s5b);
CSA #(.N(13)) S6({1'b0,s5a}, {s5b,1'b0}, {5'b00000,H}, s6a, s6b);
CSA #(.N(14)) S7({1'b0,s6a}, {s6b,1'b0}, {6'b000000,I}, s7a, s7b);
CSA #(.N(15)) S8({1'b0,s7a}, {s7b,1'b0}, {7'b0000000,J}, s8a, s8b);

assign S = {1'b0,s8a} + {s8b,1'b0};

endmodule

module testCSA();
reg [7:0] A, B, C, D, E, F, G, H, I, J;
reg cs1, cs2, cs3;
wire [15:0] S;
wire css, csco;

CSA #(.N(1)) csa1(cs1, cs2, cs3, css, csco);
Tx8A adder(A, B, C, D, E, F, G, H, I, J, S);

initial begin
    $monitor("%0t   %d+%d+%d+%d+%d+%d+%d+%d+%d+%d= %d,  A=%b B=%b C=%b | S=%b CO=%b",$time, A, B, C, D, E, F, G, H, I, J, S, cs1, cs2, cs3, css, csco);
    #10 A <= 8'd11; B<=8'd2; C<=8'd13; D<=8'd4; E<=8'd5; F<=8'd6; G<=8'd7; H<=8'd8; I<=8'd9; J<=8'd10;
    #50 A <= 8'd3; B<=8'd14; C<=8'd5; D<=8'd6; E<=8'd7; F<=8'd8; G<=8'd19; H<=8'd10; I<=8'd0; J<=8'd0;
    #50 cs1<=1'b0; cs2<=1'b0; cs3<=1'b0;
    #50 cs1<=1'b1;
    #50 cs2<=1'b1;
    #50 cs3<=1'b1;
end

endmodule
