module example2(a, b, o);

input a, b;
output o;

wire n5, d12;

not not5(n5, a);
and and7(o, n5, b, d12);
dff dff12(d12, o);

endmodule;