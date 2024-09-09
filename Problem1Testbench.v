module csaProblem1Testbench ();

  // Inputs
  reg [7:0] A;
  reg [7:0] B;

  // Outputs
  wire [7:0] Sum;
  wire CarryOut;

  // Instantiate the Unit Under Test (UUT)
  conditional_sum_adder uut (A, B, Sum, CarryOut);
  csaProblem1Test t(A, B, Sum, CarryOut);
endmodule

module testCLA
  // Expected outputs
  reg [7:0] ExpectedSum;
  reg ExpectedCarryOut;

  initial begin
    A = 0;
    B = 0;
    #10;

    $monitor("Time = %0t: A = %b, B = %b, Sum = %b, CarryOut = %b, ExpectedSum = %b, ExpectedCarryOut = %b", 
             $time, A, B, Sum, CarryOut, ExpectedSum, ExpectedCarryOut);

    for (integer i = 0; i < 256; i = i + 1) begin
      for (integer j = 0; j < 256; j = j + 1) begin
        #10 A = i; B = j;
        {ExpectedCarryOut, ExpectedSum} = A + B;
      end
    end

    #10 $finish;
  end
      
endmodule
