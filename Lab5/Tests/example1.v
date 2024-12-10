module example1(a, b, o);

input a, b;
output o;

wire n5;

not not5(n5, a);
and and7(o, n5, b);

endmodule;