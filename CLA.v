module CLA (A, B, CI, S, CO);
    input [3:0] A, B; //opperands
    input CI; //Carry in
    output [3:0] S; //sum
    output CO; //carryout

    wire [3:0] p, g; //Propogate and generate signals
    wire ci1; //carry in to s1
    wire pc1i; //propgated carry to sum 1 from cin
    wire ci2, pc2i, pc20;
    wire ci3, pc3i, pc30, pc31;
    wire pc4i, pc40, pc41, pc42;
    
    //Propogate and generate signals
    xor #10 p0(p[0], A[0], B[0]);
    and #10 g0(g[0], A[0], B[0]);
    xor #10 p1(p[1], A[1], B[1]);
    and #10 g1(g[1], A[1], B[1]);
    xor #10 p2(p[2], A[2], B[2]);
    and #10 g2(g[2], A[2], B[2]);
    xor #10 p3(p[3], A[3], B[3]);
    and #10 g3(g[3], A[3], B[3]);
    
    //Sums
    xor #10 s0(s[0], CI, p[0]);//S0

    and #10 c1i(pc1i, CI, p[0]);
    or #10 c1(ci1, pc1i, g[0]);
    xor #10 s1(s[1], ci1, p[1]); //S1

    and #10 c2i(pc2i, CI, p[0], p[1]);
    and #10 c20(pc20, g[0], p[1]);
    or #10 c2(ci2, g[1], pc20, pc2i);
    xor #10 s2(S[2], ci2, p[2]); //S2

    and #10 c3i(pc3i, CI, p[0], p[1], p[2]);
    and #10 c30(pc30, g[0], p[1], p[2]);
    and #10 c31(pc31, g[1], p[2]);
    or #10 c3(ci3, g[2], pc31, pc30, pc3i);
    xor #10 s3(S[3], ci3, p[3]); //S3

    and #10 c4i(pc4i, CI, p[0], p[1], p[2], p[3]);
    and #10 c40(pc40, g[0], p[1], p[2], p[3]);
    and #10 c41(pc41, g[1], p[2], p[3]);
    and #10 c42(pc42, g[2], p[3]);
    or #10 co(CO, g[3], pc42, pc41, pc40, pc4i); //CO

endmodule


module testCLA (A, B, CI, S, CO);
    output [3:0] A, B;
    output CI;
    input [3:0] S;
    input CO;

    initial begin
        $display("time A      B      CI  S      CO");
        $monitor("%0t   %b   %b   %b   %b   %b   %b", $time, A, B, CI, S, CO);
        #5 A<=4'b0000, B<=4'b0000, CI<=0;
        #50 A<=4'b0001;
        #50 CI<=1'b1;
        #50 CI<=1'b0, B<=4'b0001;
        #50 A<=4'b0011;
        #50 A<=4'b0111;
        #50 A<=4'1111;
    end

endmodule

module testbenchCLA ();
    reg [3:0] A, B, S;
    reg CI, CO;

    CLA u(A, B, CI, S, CO);
    testCLA t(A, B, CI, S, CO);
endmodule