//behavioral takes #5 to update and lags structural due to the way it updates Z2 and then Z1 after.
module Problem5Structural(input wire [1:0] X, output wire [1:0] Z);
    wire [5:0] and_outputs; // Intermediate wires for AND gate outputs
    wire Z3; // Output of third OR gate
    //Z[0] = Z2, Z[1] = Z1
    //X[0] = X2, X[1] = X1

    and_gate and1(~X[1], Z[1], and_outputs[0]);
    and_gate and2(Z[1], Z3, and_outputs[1]);
    and_gate and3(X[1], Z[0], and_outputs[2]);
    and3 and4(X[1], X[0], ~Z3, and_outputs[3]);
    and_gate and5(X[0], Z[1], and_outputs[4]);
    and3 and6(X[1], ~X[0], Z3, and_outputs[5]);

    or3 or1(and_outputs[0], and_outputs[3], and_outputs[4], Z[1]);
    or3 or2(and_outputs[0], and_outputs[1], and_outputs[1], Z3);
    or_gate or3(and_outputs[3], and_outputs[5], Z[0]);
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

module Problem5Behavioral (input wire clk, input wire reset, input wire [1:0] X, output reg [1:0] Z);
    reg Z3; //Output of third OR gate
    //Treat as a FSM (See picture for states)
    //Equation for Z1:(~X1  & z1)| (X1 & X2 & ~z3) | (X2 & z1)
    //Equation for Z2:(X1 & X2 & ~z3) | (X1 & ~X2 & z3)
    //Equation for Z3:(~X1  & z1)| (z3 & z1) | (X1 & z3)
    //Z2 will be calculated every loop using the equation because its next state d

    // State encoding
    parameter A = 2'b00, B = 2'b01, C = 2'b10, D = 2'b11;

    // State register
    reg [1:0] current_state, next_state;

    // State transition logic
    always @(posedge clk or posedge reset) begin
        if (reset)
            current_state <= A;
        else
            current_state <= next_state;
    end

    // Next state logic
    always @(current_state or X) begin
        case (current_state)
            A: case (X)
                2'b00: begin next_state = A; Z[0] = 0; end
                2'b01: begin next_state = A; Z[0] = 0; end
                2'b11: begin next_state = D; Z[0] = 1; end
                2'b10: begin next_state = A; Z[0] = 0; end
                default: next_state = A;
            endcase
            B: case (X)
                2'b00: begin next_state = A; Z[0] = 0; end
                2'b01: begin next_state = A; Z[0] = 0; end
                2'b11: begin next_state = B; Z[0] = 0; end
                2'b10: begin next_state = B; Z[0] = 1; end
                default: next_state = B;
            endcase
            C: case (X)
                2'b00: begin next_state = C; Z[0] = 0; end
                2'b01: begin next_state = C; Z[0] = 0; end
                2'b11: begin next_state = C; Z[0] = 0; end
                2'b10: begin next_state = B; Z[0] = 1; end
                default: next_state = C;
            endcase
            D: case (X)
                2'b00: begin next_state = C; Z[0] = 0; end
                2'b01: begin next_state = C; Z[0] = 0; end
                2'b11: begin next_state = D; Z[0] = 1; end
                2'b10: begin next_state = A; Z[0] = 0; end
                default: next_state = D;
            endcase
            default: next_state = A;
        endcase
    end

    // Output logic
    always @(current_state) begin
        Z[1] = current_state[1];
        //Z[0] (Z2) already specified
    end
endmodule

module TB_Problem5;
    reg clk;
    reg reset;
    reg [1:0] X;
    wire [1:0] Z_structural;
    wire [1:0] Z_behavioral;

    // Instantiate the structural module
    Problem5Structural uut_structural (
        .X(X),
        .Z(Z_structural)
    );

    // Instantiate the behavioral module
    Problem5Behavioral uut_behavioral (
        .clk(clk),
        .reset(reset),
        .X(X),
        .Z(Z_behavioral)
    );

    always #5 clk = ~clk;

    initial begin
        // Initialize inputs
        clk = 0;
        reset = 1;
        X = 2'b00;
        #20 reset = 0;

        // Run tests
        #20 X = 2'b10;
        #20 X = 2'b00;
        #20 X = 2'b01;
        #20 X = 2'b11;
        #20 X = 2'b10;

        #20 X = 2'b00;
        #20 X = 2'b10;
        #20 X = 2'b11;
        #20 X = 2'b01;

        #20 $finish;
    end

    initial begin
        $monitor("Time=%0d, X=%b, Z_structural=%b, Z_behavioral=%b", $time, X, Z_structural, Z_behavioral);
    end
endmodule
