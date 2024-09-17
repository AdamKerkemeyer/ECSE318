module Problem5Behavioral(input X1, input X2, output Z1, output Z2);
    wire [5:0] and_outputs; // Intermediate wires for AND gate outputs
    wire Z3; //Output of third OR gate

    and_gate and1(~X1, Z1, and_outputs[0]);
    and_gate and2(Z1, Z3, and_outputs[1]);
    and_gate and3(X1, Z2, and_outputs[2]);
    and3 and4(X1, X2, ~Z3 and_outputs[3]);
    and_gate and5(X2, Z1, and_outputs[4]);
    and3 and6(X1, ~X2, Z3, and_outputs[5]);

    or3 or1(and_outputs[0], and_outputs[3], and_outputs[4] Z1);
    or3 or2(and_outputs[0], and_outputs[1], and_outputs[1], Z3);
    or_gate or3(and_outputs[3], and_outputs[5], Z2);
endmodule

//Using 2001 Verilog for conciseness
module and_gate(input A, input B, output Y);
    assign Y = A & B;
endmodule
module or_gate(input A, input B, output Y);
    assign Y = A | B;
endmodule
module and3(input A, input B, input C, output Y);
    assign Y = A & B & C;
endmodule
module or3(input A, input B, input C, output Y);
    assign Y = A | B | C;
endmodule

module Problem5BehavioralTB;
    reg X1;
    reg X2;

    wire Z1;
    wire Z2;

    // Instantiate the Unit Under Test (UUT)
    Problem5Behavioral uut (X1, X2, Z1, Z2);

    initial begin
        X1 = 0;
        X2 = 0;
        #10;
        $monitor("At time %t, X1 = %b, X2 = %b, Z1 = %b, Z2 = %b", $time, X1, X2, Z1, Z2);

        //Need to test more possible states as next state depends on current state.
        //Will need more detailed state diagram
        X1 = 0; X2 = 0; #10;
        X1 = 0; X2 = 1; #10;
        X1 = 1; X2 = 0; #10;
        X1 = 1; X2 = 1; #10;

        $finish;
    end
endmodule
