
module conditional_sum_adder(x, y, cin, cout, s);
    input [7:0] x, y;
    input cin;
    output cout;
    output [7:0] s;

    wire [8:0] carry1, carry0; //2 potential carrys, mux will pick the correct one
    wire [1:0] x1y1; //used as wires for x1 and y1 to first mux
    full_adder(y[0], x[0], cin, s[0], carry0[1]);

    
    full_adder(y[1], x[1], 0, s[0], carry0[1]); //carry for 1 and 0
    full_adder(y[1], x[1], 1, s[0], carry0[1]);

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
module Mux2x2(a, b, sel, out);
    input [1:0] a, b;
    input sel;
    output [1:0] out;
    //If sel is 1, output is b, if sel is 0, output is a
    assign out = sel ? b : a;
endmodule