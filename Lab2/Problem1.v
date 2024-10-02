module ALU(A, B, alu_code, C, overflow);
    input [15:0] A, B;
    input [4:0] alu_code;
    output reg [15:0] C;
    output reg overflow;

    wire [15:0] AdderC;
    wire AdderOverflow;

    Adder add1(AdderC, AdderOverflow, A, B, alu_code[2:0]);

    always @(A or B or alu_code or AdderC or AdderOverflow) begin
        casez (alu_code)
            5'b00???: begin//adder
                C = AdderC;
                overflow = AdderOverflow;
            end
            5'b01000: begin   //A and B                 
                C = A & B;
                overflow = 1'b0;
            end
            5'b01001: begin// A OR B
                C = A | B;
                overflow = 1'b0;
            end
            5'b01010: begin// A XOR B
                C = A ^ B;
                overflow = 1'b0;
            end
            5'b01100: begin // NOT A
                C = ~A;
                overflow = 1'b0;
            end
            5'b10000: begin //logic left shift
                C = A << B[3:0];
                overflow = 1'b0;
            end
            5'b10001: begin //logic right shift
                C = A >> B[3:0];
                overflow = 1'b0;
            end
            5'b10010: begin //arithmatic left shift
                C = A <<< B[3:0];
                overflow = 1'b0;
            end
            5'b10011: begin // arithmetic right shift
                C = $signed(A) >>> B[3:0];
                overflow = 1'b0;
            end
            5'b11000: begin //A <= B
                C = {15'b0, ($signed(A) <= $signed(B))};
                overflow = 1'b0;
            end
            5'b11001: begin //A < B
                C = {15'b0, ($signed(A)<$signed(B))};
                overflow = 1'b0;
            end
            5'b11010: begin // A >= B
                C= {15'b0, ($signed(A)>=$signed(B))};
                overflow = 1'b0;
            end
            5'b11011: begin //A > B
                C = {15'b0, ($signed(A)>$signed(B))};
                overflow = 1'b0;
            end
            5'b11100: begin //A = B
                C = {15'b0, (A==B)};
                overflow = 1'b0;
            end
            5'b11101: begin // A!=B
                C = {15'b0, (A!=B)};
                overflow = 1'b0;
            end
            default: begin
                C = 16'b0;
                overflow = 1'b0;
            end
        endcase
    end
endmodule

module Adder(C, Overflow, A, B, Code);
    input [15:0] A, B;
    input [2:0] Code;
    output reg [15:0] C;
    output reg Overflow;

    reg [15:0] AdderA, AdderB;
    wire [15:0] AdderC;
    reg AdderCin;
    wire AdderCout;

    BKA add1(AdderC, AdderCout, AdderA, AdderB, AdderCin);


    always @(A or B or Code or AdderC or AdderCout) begin
        case (Code)
            //signed addition
            3'b000: begin
                    AdderA = A;
                    AdderB = B;
                    AdderCin = 1'b0;
                    C = AdderC;
                    Overflow = (AdderA[15] & AdderB[15] & !AdderC[15]) | (!AdderA[15] & !AdderB[15] & AdderC[15]);
            end
            //unsigned addition
            3'b001: begin
                    AdderA = A;
                    AdderB = B;
                    AdderCin = 1'b0;
                    C = AdderC;
                    Overflow = AdderCout;
            end
            //signed subtraction
            3'b010: begin
                    AdderA = A;
                    AdderB = ~B;
                    AdderCin = 1'b1;
                    C = AdderC;
                    Overflow = (AdderA[15] & AdderB[15] & AdderCout) | (!AdderA[15] & !AdderB[15] & AdderC[15]);
            end
            //unsigned subtraction
            3'b011: begin
                    AdderA = A;
                    AdderB = ~B;
                    AdderCin = 1'b1;
                    C = AdderC;
                    Overflow = !AdderA[15] & AdderC[15];
            end
            //signed increment
            3'b100: begin
                    AdderA = A;
                    AdderB = 16'b0000000000000001;
                    AdderCin = 1'b0;
                    C = AdderC;
                    Overflow = !AdderA[15] & AdderC[15];
            end
            3'b101: begin 
                    AdderA = A;
                    AdderB = 16'b1111111111111111;
                    AdderCin = 1'b0;
                    C = AdderC;
                    Overflow = AdderA[15] & !AdderC[15];
            end
            default: begin
                    AdderA = A;
                    AdderB = B;
                    AdderCin = 1'b0;
                    C = {Code, 13'b0};
                    Overflow = 1'b0;
            end
        endcase
    end
endmodule

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

module testAdder();
    reg [15:0] A, B;
    reg [2:0] Code;
    wire [15:0] C;
    wire Overflow;

    Adder uut(C, Overflow, A, B, Code);

    initial begin
        $monitor("%4t %16b %d %16b %d %3b -> %16b %d %b", $time, A, A, B, B, Code, C, C, Overflow);
        A <= 1; B <= 0; Code <= 3'b000;
        #5
        B<=5;
        #5
        A<=-1;
        #5
        B<=-45;
        #5
        A<=32767; B<=20;
        #5
        A <= -32767; B <= -50;
        #5
        A<=-1; B<=10;
        #5
        Code <= 3'b001; A<=5; B<=15;
        #5
        A<=65535;
        #5
        Code <= 3'b010; A<=40;
        #5
        A<=10;
        #5
        A<=-20;
        #5
        B<=-10;
        #5
        B<=-50;
        #5
        A<= -32767; B<= 50;
        #5
        A<= 32767;B<=-50;
        #5
        Code <= 3'b011; B<=30; A<=90;
        #5
        A<=10;
        #5
        Code <= 3'b100;
        #5
        A<=65535;
        #5 
        Code <= 3'b101;
        #5
        A<=0;
    end
endmodule

module testALU();
    reg[15:0] A, B;
    reg[4:0] alu_code;
    wire[15:0] C;
    wire overflow;

    ALU uut(A, B, alu_code, C, overflow);

    initial begin
        $monitor("%4t %d %d %16b %16b %5b -> %16b %d %b", $time, A, B, A, B, alu_code, C, C, overflow);
        A <=1; B<=1; alu_code<=5'b00000;
        #5
        B<=3; alu_code <=5'b01000;
        #5
        alu_code <= 5'b01001;
        #5
        alu_code <= 5'b01010;
        #5
        alu_code <= 5'b01100;
        #5
        alu_code <= 5'b10000;
        #5
        alu_code<=5'b10001; A<=16'b1100100000000000;
        #5
        alu_code<=5'b10010;
        #5
        alu_code<=5'b10011;
        #5
        A<=12;
        #5
        alu_code <= 5'b11000; A <=5; B<= 10;
        #5
        A<=-1;
        #5
        A<=10;
        #5
        A<=15;
        #5
        alu_code <= 5'b11001; A<= 15;
        #5
        A<=10;
        #5
        A<=5;
        #5
        alu_code <= 5'b11010; A<= 15;
        #5
        A<=10;
        #5
        A<=5;
        #5
        alu_code <= 5'b11011; A<= 15;
        #5
        A<=10;
        #5
        A<=5;
        #5
        alu_code <= 5'b11100; A<= 15;
        #5
        A<=10;
        #5
        A<=5;
        #5
        alu_code <= 5'b11101; A<= 15;
        #5
        A<=10;
        #5
        A<=5;
    end
endmodule