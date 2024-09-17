module FA (A, B, Cin, S, Cout);//Full Adder
    input A, B, Cin;
    output S, Cout;

    assign S = A ^ B ^ Cin;
    assign Cout = (A & B) | (A & Cout) | (B & Cout);
endmodule

module CAS (M, D, Q, Qb, S, Cout)//Controlled Add Sub
    input A, D, Q, Qb;
    output S, Cout;
    wire w;

    xor x(w, Q, M);
    FA u(w, D, Qb, S, Cout);
endmodule

module DdivM (D, M, Q, R); //D divided by M
parameter N=4;
input [N-1:0] D, M;
output [N-1:0]Q, R;
wire [N:0] carryout [N:0]; //Passes the carry out variables between CAS's
wire [N:0] runtotal [N:0]; //Holds the D variable between CAS's
wire [N:0] Rcout; //Holds the outputs of the cout of the full adders in the remainder recovery
wire [N-1:0] Rand; //Holds the outputs of the and in the remainder recovery
//var[row][collumn] <- how to access vars


//inital variable setup
assign runtotal[N][N:1] = {(N){1'b0}};//Fill intial parts of run total with 0s
assign Rcout[0] = 1'b0;//Initalize LSB of Rcout
genvar k;
generate
    for (k=N-1; k>-1; k=k-1)//Single cycle var assignments
    begin
        assign runtotal[k+1][0] = D[k]; //Drip feed D into run total
        assign carryout[k][0] = carryout[k+1][N]; //Loop back end bits to inputs of next row carry in
        assign Q[k] = carryout[k][N]; //Extract Q from carryout
        //Remainder Recovery:
        and a0(Rand, runtotal[0][N], M[k]);
        FA fa0(runtotal[0][k+1], Rand[k], Rcout[k], S[k], Rcout[k+1]);
    end
endgenerate
assign carryout[N][0] = 1'b1;//Set up the intial carry bit

genvar i;
generate
    for (i=N-1; i>-1; i=i-1)//Row
    begin
        genvar j;
        for(j=N-1; j>-1; j=j-1) //Collumn
        begin
            CAS u0(M[j], runtotal[i+1][j], carryout[i+1][N], carryout[i][j], runtotal[i][j+1], carryout[i][j+1]);
        end
    end
endgenerate
endmodule

module testDdivN(D, M, Q, R);
    output reg [3:0] D, M;
    input [3:0] Q, R;

    intial begin
        $display("time D    /M    =Q    %R")
        $monitor("%4t %4b/%4b=%4b&%4b", $time, D, M, Q, R);
        #5 D = 4'd7; M = 4'd2;
        #45 D = 4'd6;
        #50 D = 4'd9; M = 4'd4;
    end
endmodule

module testbenchDdivN();
    wire [3:0] Dt, Mt, Qt, Rt;

    testDdivN tst(Dt, Mt, Qt, Rt);
    DdivM mdl(Dt, Mt, Qt, Rt);
endmodule