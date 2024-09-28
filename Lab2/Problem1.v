module BKA(S, Cout, A, B, Cin); // Brent kruger adds two numbers (Gi, Pi) = (gi, pi) ○ (Gi-1, Pi-1)
    output [16:1] S;
    output Cout;
    input [16:1] A, B;
    input Cin;

    wire [16:1] p, g;
    wire [16:1] P2 [1:4];
    wire [16:1] G2 [1:4];

    assign p = A ^ B;
    assign g[16:2] = A[16:2] & B[16:2];
    assign g[1] = (A[1] & B[1]) | (A[1] & Cin) | (B[1] & Cin);

    genvar i;
    generate//2121212121212121
        for(i=16; i>0; i=i-2) begin
            BKop b2(G2[1][i], P2[1][i], g[i], p[i], g[i-1], p[i-1]);
            assign G2[1][i-1] = g[i-1];
            assign P2[1][i-1] = p[i-1];
        end
    endgenerate

    generate//4321432143214321
        for(i=16; i>0; i=i-1) begin
            if (i % 4 == 0) begin//4s
                BKop b4(G2[2][i], P2[2][i], G2[1][i], P2[1][i], G2[1][i-2], P2[1][i-2]);
            end
            else if ((i+1) % 4 == 0) begin//3s
                BKop b3(G2[2][i], P2[2][i], G2[1][i], P2[1][i], G2[1][i-1], P2[1][i-1]);
            end
            else begin
                assign G2[2][i] = G2[1][i];
                assign P2[2][i] = P2[1][i];
            end
        end
    endgenerate

    generate //8765432187654321
        for (i=16; i>0; i=i-1) begin
            if (i % 8 == 0) begin//8s
                BKop b8(G2[3][i], P2[3][i], G2[2][i], P2[2][i], G2[2][i-4], P2[2][i-4]);
            end
            else if ((i+1) % 8 == 0) begin//7s
                BKop b7(G2[3][i], P2[3][i], G2[2][i], P2[2][i], G2[2][i-3], P2[2][i-3]);
            end
            else if ((i+2) % 8 == 0) begin//6s
                BKop b7(G2[3][i], P2[3][i], G2[2][i], P2[2][i], G2[2][i-2], P2[2][i-2]);
            end
            else if ((i+3) % 8 == 0) begin//5s
                BKop b7(G2[3][i], P2[3][i], G2[2][i], P2[2][i], G2[2][i-1], P2[2][i-1]);
            end
            else begin
                assign G2[3][i] = G2[2][i];
                assign P2[3][i] = P2[2][i];
            end
        end
    endgenerate

    generate//all done
        for (i=16; i>0; i=i-1) begin
            if (i>8) begin
                BKop bd(G2[4][i], P2[4][i], G2[3][i], P2[3][i], G2[3][8], P2[3][8]);
            end
            else begin
                assign G2[4][i] = G2[3][i];
                assign P2[4][i] = P2[3][i];
            end
        end
    endgenerate

//Final Processing
    assign S[1] = p[1] ^ Cin;
    assign Cout = G2[4][16];

    generate
        for (i = 16; i>1; i=i-1) begin
            assign S[i] = p[i] ^ G2[4][i-1];
        end
    endgenerate

endmodule

module BKop(go, po, g1, p1, g2, p2); //the brenk-kruger opperation
    output go, po;
    input g1, p1, g2, p2;

    assign go = g1 | (p1 & g2);
    assign po = p1 & p2;

endmodule

module testBKA ();
reg [15:0] A, B;
reg Cin;
wire [15:0] S;
wire Cout;

BKA uut(S, Cout, A, B, Cin);

initial begin
   // $monitor("%4t, %16b %16b %b -> %b %16b", $time, A, B, Cin, Cout, S);
    A = 4'b0; B = 4'b0; Cin = 1'b0;
    #50
    A = 4'b0001;
    #50
    B = 4'b0001;
    #50
    B = 16'b1111111111111111;
    #50
    B = 16'b1110111111111111;
    #50
    A = 1'b0;
    Cin = 1'b1;
    #50
    Cin = 1'b0;
    A = 16'b0000000000000001;
    B = 16'b0000000000000111;
    #50
    A = 16'b1111010001000111;
    B = 16'b0000000000101010;
    #5
    //$display("%16b %16b -> %b %16b %16b \n p[4]:%b, G2[4][3]:%b G2[3][3]:%b G2[2][3]:%b G2[1][3]:%b \n     g:%16b \n G2[1]:%16b\n G2[2]:%16b \n G2[3]:%16b \n G2[4]:%16b"
    //, A, B, Cout, S, A+B, uut.p[4], uut.G2[4][3], uut.G2[3][3], uut.G2[2][3], uut.G2[1][3], uut.g, uut.G2[1], uut.G2[2], uut.G2[3], uut.G2[4]);
    #50
    Cin = 1'b0;
    B = 1'b0;
    A = 1'b0;

    repeat (100) begin
        A = A + A*3 + 1;
        B = B + 47;
        #5
        if (S != A + B) begin
            $display("Issue: %16b %16b -> %b %16b %16b", A, B, Cout, S, A+B);
        end
        
    end
    $display("DONE");
    
end

endmodule
