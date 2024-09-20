module conditional_sum_adder(x, y, cin, cout, correctSum);
    input [7:0] x, y;
    input cin;
    output cout;
    output [7:0] correctSum;

    wire [8:0] carry1, carry0; //first round of carrys
    wire [7:0] sum0, sum1; // first round of sums

    wire [8:0] muxCarry1, muxCarry0; //first round of mux selections
    wire [7:0] muxSum0, muxSum1; //first round of mux selections

    wire muxCarrySecond1, muxCarrySecond0; //second round of mux selections
    wire [7:0] muxSumSecond0, muxSumSecond1; //second round of mux selections

    wire [8:0] correctCarry; //where the correct carrys are stored and pulled from

    //x0y0 special case
    full_adder faInitial (y[0], x[0], cin, correctSum[0], correctCarry[1]);

    // First row of full adders
    genvar i;   
    generate
        //Assign to intermediate sum and carry values as correct is unkown
        for (i = 1; i < 8; i = i + 1) begin : adders
            full_adder fa0 (y[i], x[i], 1'b0, sum0[i], carry0[i+1]);
            full_adder fa1 (y[i], x[i], 1'b1, sum1[i], carry1[i+1]);
        end
    endgenerate

    //x1y1 special case
    n_bit_mux #(2) muxX1Y1 (
        .in0_data(sum0[1]),
        .in0_carry(carry0[2]),
        .in1_data(sum1[1]),
        .in1_carry(carry1[2]),
        .sel(correctCarry[1]),
        .out_data(correctSum[1]),
        .out_carry(correctCarry[2])
    );
    genvar j; //unsure if I can reuse i;
    generate
        //Assign to intermediate sum and carry values as correct is unkown
        for (j = 3; j < 8; j = j + 2) begin : muxes //increase by 2
            n_bit_mux #(2) muxM1 (
                .in0_data(sum0[j]),
                .in0_carry(carry0[j+1]),
                .in1_data(sum1[j]),
                .in1_carry(carry1[j+1]),
                .sel(carry0[j]), //pick
                .out_data(muxSum0[j]),
                .out_carry(muxCarry0[j+1])
            );
            n_bit_mux #(2) muxM2 (
                .in0_data(sum0[j]),
                .in0_carry(carry0[j+1]),
                .in1_data(sum1[j]),
                .in1_carry(carry1[j+1]),
                .sel(carry1[j]), //pick
                .out_data(muxSum1[j]),
                .out_carry(muxCarry1[j+1])
            );
        end
    endgenerate

    //sum[3:2] multiplexer
    n_bit_mux #(3) muxS32 (
        .in0_data({muxSum0[3], sum0[2]}),
        .in0_carry(carry0[4]),
        .in1_data({muxSum1[3], sum1[2]}),
        .in1_carry(carry1[4]),
        .sel(correctCarry[2]), //pick
        .out_data(correctSum[3:2]),
        .out_carry(correctCarry[4])
    );
    //Last 3 muxes here:
    n_bit_mux #(3) mux2nd1 (
        .in0_data({muxSum0[7], sum0[6]}),
        .in0_carry(muxCarry1[8]),
        .in1_data({muxSum1[7], sum1[6]}),
        .in1_carry(muxCarry0[8]),
        .sel(muxCarry0[6]), //pick
        .out_data(muxSumSecond0[7:6]),
        .out_carry(muxCarrySecond0)
    );
    n_bit_mux #(3) mux2nd2 (
        .in0_data({muxSum0[7], sum0[6]}),
        .in0_carry(muxCarry1[8]),
        .in1_data({muxSum1[7], sum1[6]}),
        .in1_carry(muxCarry0[8]),
        .sel(muxCarry1[6]), //pick
        .out_data(muxSumSecond1[7:6]),
        .out_carry(muxCarrySecond1)
    );
    //final mux:
    n_bit_mux #(5) muxFinal (
        .in0_data({muxSumSecond0[7:6], muxSum0[5], sum0[4]}),
        .in0_carry(muxCarrySecond1),
        .in1_data({muxSumSecond1[7:6], muxSum1[5], sum1[4]}),
        .in1_carry(muxCarrySecond0),
        .sel(correctCarry[4]), //pick
        .out_data(correctSum[7:4]),
        .out_carry(cout) //assign carry out
    );

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

module n_bit_mux (in0_data, in0_carry, in1_data, in1_carry, sel, out_data, out_carry);
    parameter N = 2;
    input [N-2:0] in0_data;
    input in0_carry;       
    input [N-2:0] in1_data; 
    input in1_carry;       
    input sel;        
    output [N-2:0] out_data; 
    output out_carry;       
    //when sel = 1, it will pick input 1 data
    assign out_data = sel ? in1_data : in0_data;
    assign out_carry = sel ? in1_carry : in0_carry;
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

    $monitor("Time = %0t: A = %b, B = %b, cin = %b, Sum = %b, CarryOut = %b, ExpectedSum = %b, ExpectedCarryOut = %b", 
             $time, A, B, cin, Sum, CarryOut, ExpectedSum, ExpectedCarryOut);

    // Test all combinations of A and B without a for loop b/c modelsim wouldn't compile with it
    repeat (256) begin
      repeat (256) begin
	ExpectedSum = A + B;
        ExpectedCarryOut = (A + B) >> 8;
        #10;
        B = B + 1;
      end
      A = A + 1;
      B = 0;
    end

    #10 $finish;
  end
      
endmodule
