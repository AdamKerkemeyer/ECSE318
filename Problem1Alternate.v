module csa_8bit (
    input [7:0] A,
    input [7:0] B,
    input Cin,
    output [7:0] Sum,
    output Cout
);
    wire [7:0] Sum0, Sum1;
    wire [7:0] Carry0, Carry1;
    wire [7:0] Carry;

    // First stage: generate sum and carry for Cin = 0 and Cin = 1
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : stage1
            full_adder fa0 (
                .a(A[i]),
                .b(B[i]),
                .cin(1'b0),
                .sum(Sum0[i]),
                .cout(Carry0[i])
            );
            full_adder fa1 (
                .a(A[i]),
                .b(B[i]),
                .cin(1'b1),
                .sum(Sum1[i]),
                .cout(Carry1[i])
            );
        end
    endgenerate

    // Second stage: select the correct sum and carry based on the previous carry
    assign Carry[0] = Cin;
    assign Sum[0] = (Cin) ? Sum1[0] : Sum0[0];

    generate
        for (i = 1; i < 8; i = i + 1) begin : stage2
            assign Carry[i] = (Carry[i-1]) ? Carry1[i-1] : Carry0[i-1];
            assign Sum[i] = (Carry[i-1]) ? Sum1[i] : Sum0[i];
        end
    endgenerate

    assign Cout = (Carry[7]) ? Carry1[7] : Carry0[7];

endmodule

module full_adder (
    input a,
    input b,
    input cin,
    output sum,
    output cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (cin & (a ^ b));
endmodule
