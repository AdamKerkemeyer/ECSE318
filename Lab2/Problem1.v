module NCLA( A, B, Cin, S, Cout); //N bit CLA
    parameter N = 16;
    input[N-1:0] A, B;
    input Cin;
    output[N-1:0] S;
    output Cout;


wire[N-1:-1] g, p, S;



assign g[-1] = Cin;
assign p[-1] = 1'b1;


genvar i, k;
generate
    for (i = N-1; i>-1; i=i-1) begin
        wire [i-1:0] cins; //holds all posible bits that could be a carry in
        xor xp(p[i], A[i], B[i]);//Propogate bits
        and ag(g[i], A[i], B[i]);//Generate Bits
        xor xs(S[i], p[i], |{cins, g[i-1]}); //Generate Sums
        for (k = 0; k<i; k=k+1)begin
            assign cins[k] = &{g[k-1], p[k:i]};
        end
    end
endgenerate

//Cout is a poin in the ass to extract from those for loops, but I can do it myself. It does make the adder slightly slower though
assign Cout = (A[N-1] && B[N-1]) || ((A[N-1] || B[N-1]) ^ S[N-1]);

endmodule

module testNCLA();//there is no way this works

reg [3:0] A, B;
reg Cin;
wire [3:0] S;
wire Cout;

NCLA #(4) uut(A, B, Cin, S, Cout);

initial begin
    $monitor("%4t, %4b %4b %b -> %b %4b", $time, A, B, Cin, Cout, S);
    A = 4'b0; B = 4'b0; Cin = 1'b0;
    #50
    A = 4'b0001;
    #50
    B = 4'b0001;
end

endmodule