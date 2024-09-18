module conditional_sum_adder(x, y, cin, cout, correctSum);
    input [7:0] x, y;
    input cin;
    output cout;
    output [7:0] correctSum;

    wire [8:0] carry1, carry0; //first round of carrys
    wire [7:0] sum0, sum1; // first round of sums
    wire [8:0] muxCarry1, muxCarry0; //first round of mux selections
    wire [7:0] muxSum0, muxSum1; //first round of mux selections
    wire [8:0] muxCarrySecond1, muxCarrySecond0; //second round of mux selections
    wire [7:0] muxSumSecond0, muxSumSecond1; //second round of mux selections
    wire [8:0] correctCarry; //where the correct carrys are stored and pulled from

    wire [1:0] x1y1; //used as wires for x1 and y1 to first mux

    //x0y0 special case
    full_adder faInitial (y[0], x[0], cin, correctSum[0], correctCarry[1]);

    // First row of full adders
    genvar i;
    generate
        //Assign to intermediate sum and carry values as correct is unkown
        for (i = 1; i < 8; i = i + 1) begin : adders
            full_adder fa0 (y[i], x[i], 0, sum0[i], carry0[i+1]);
            full_adder fa1 (y[i], x[i], 1, sum1[i], carry1[i+1]);
        end
    endgenerate

    //x1y1 special case
    mux2x2 muxInitial ({sum1[1], carry1[1]}, {sum0[1], carry0[1]}, correctCarry[1], {correctSum[1], correctCarry[2]});
    
    // First row of multiplexers
    genvar j; //unsure if I can reuse i;
    generate
        //Assign to intermediate sum and carry values as correct is unkown
        for (j = 2; j < 8; j = j + 2) begin : muxes //increase by 2
            mux2x2 mux0 ({sum1[j], carry1[j+1]}, {sum0[j], carry0[j+1]}, carry0[j+1], {muxSum0[j], muxCarry0[j+2]});
            mux2x2 mux1 ({sum1[j], carry1[j+1]}, {sum0[j], carry0[j+1]}, carry1[j+1], {muxSum1[j], muxCarry1[j+2]});
        end
    endgenerate

    //x3y3 x2y2 mux using c2
    mux2x3 secondRowMux ({muxSum1[3], muxSum1[2], muxCarry1[3]}, 
        {muxSum0[3], muxSum0[2], muxCarry0[3]}, correctCarry[2], {correctSum[3], correctSum[2], correctCarry[3]});

    //unsure how to wire up last 3 muxes
    //x7y7 x6y6 x5y5x4y4 using muxCarry0[6] and muxCarry1[6]
    //not doing generate b/c only 1 sequence
    mux2x3 mux2x30 ({muxSum1[7], muxSum1[6], muxCarry1[7]}, 
        {muxSum0[7], muxSum0[6], muxCarry0[7]}, muxCarry0[6], {muxSumSecond0[7], muxSumSecond0[6], muxCarrySecond0[7]});
    mux2x3 mux2x31 ({muxSum1[7], muxSum1[6], muxCarry1[7]}, 
        {muxSum0[7], muxSum0[6], muxCarry0[7]}, muxCarry1[6], {muxSumSecond1[7], muxSumSecond1[6], muxCarrySecond1[7]});

    //last mux

    assign {correctSum[7:4], cout} = correctCarry[4] ? {muxSumSecond1[7:6], muxSum1[5:4], muxCarrySecond1[7]} : 
        {muxSumSecond0[7:6], muxSum0[5:4], muxCarrySecond0[7]};
        
endmodule

module full_adder(a, b, cin, sum, cout);
    input a, b, cin;
    output sum, cout;

    wire sum_intermediate;
    wire carry_intermediate1, carry_intermediate2;

    //Sum
    xor (sum_intermediate, a, b);
    xor (sum, sum_intermediate, cin);

    //Carry-out
    and (carry_intermediate1, a, b);
    and (carry_intermediate2, sum_intermediate, cin);
    or (cout, carry_intermediate1, carry_intermediate2);
endmodule

//really all we need is the assign statement. Could do this without official MUX. 
module mux2x2(a, b, sel, out);
    input [1:0] a, b;
    input sel;
    output [1:0] out;
    //If sel is 0, output is b, if sel is 1, output is a
    assign out = sel ? a : b;
endmodule

module mux2x3(a, b, sel, out);
    input [2:0] a, b;
    input sel;
    output [2:0] out;
    //If sel is 0, output is b, if sel is 1, output is a
    assign out = sel ? a : b;
endmodule

module csaProblem1Testbench;

  // Inputs
  reg [7:0] A;
  reg [7:0] B;

  reg cin;

  // Outputs
  wire [7:0] Sum;
  wire CarryOut;

  // Expected outputs
  reg [7:0] ExpectedSum;
  reg ExpectedCarryOut;

  // Instantiate the Unit Under Test (UUT)
  conditional_sum_adder uut (
    .x(A), 
    .y(B), 
    .cin(cin),
    .cout(CarryOut),
    .correctSum(Sum)
  );

  initial begin
    A = 0;
    B = 0;
    cin = 0;
    #10;

    $monitor("Time = %0t: A = %b, B = %b, Sum = %b, CarryOut = %b, ExpectedSum = %b, ExpectedCarryOut = %b", 
             $time, A, B, Sum, CarryOut, ExpectedSum, ExpectedCarryOut);

    // Test all combinations of A and B without a for loop b/c modelsim wouldn't compile with it
    repeat (256) begin
      repeat (256) begin
        #10;
        {ExpectedCarryOut, ExpectedSum} = A + B;
        B = B + 1;
      end
      A = A + 1;
      B = 0;
    end

    #10 $finish;
  end
      
endmodule
