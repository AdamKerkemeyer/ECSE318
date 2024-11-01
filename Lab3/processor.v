module PSR(clk, in, out);
    input [4:0] in;
    input clk;
    output reg [4:0] out;

    always @(posedge clk) out = in;

    /*
    PSR[0] CARRY
    PSR[1] Parity
    PSR[2] Even
    PSR[3] Negative
    PSR[4] Zero
    */
endmodule

module RAM(clk, address, modebit, indata, outdata);
    input clk, modebit; //clk is clk, mode is 0 to read, 1 to write
    input [11:0] address;
    input [31:0] indata;
    output reg [31:0] outdata;

    reg [31:0] mem [4095:0];

    always @(posedge clk) begin
        if (modebit) begin //write mode
            mem[address] = indata;
        end
        else begin
            outdata = mem[address];
        end
    end
endmodule

module RegisterFile(clk, address, modebit, indata, outdata);
    input clk, modebit; //clk is clk, mode is 0 to read, 1 to write
    input [3:0] address;
    input [31:0] indata;
    output reg [31:0] outdata;

    reg [31:0] mem [15:0];

    always @(posedge clk) begin
        if (modebit) begin //write mode
            mem[address] = indata;
        end
        else begin
            outdata = mem[address];
        end
    end
endmodule

module clkgen(clk);
    output reg clk;

    initial clk = 0;

    always begin
        #5 clk = ~clk;
    end
endmodule

module ProgramCounter(clk, enable, set, countToSet, count);
    input clk, enable, set; //counts up when enable is high. Sets the count to countToSet when set is high
    input [11:0] countToSet;
    output reg [11:0] count;

    initial count = 12'b000000000000;

    always @(posedge clk) begin
        if (enable) begin
            if (set) begin
                count = countToSet;
            end
            else begin
                count = count + 1;
            end
        end
    end
endmodule

module ALUbehave(op, in1, in2, out, flagout);
    input [3:0] op;
    input [31:0] in1, in2;
    output [31:0] out;
    output [4:0] flagout;


    wire [4:0] flags;
    reg [32:0] outp1;
    integer i, j;

    flagFinder flg(out, flags);
    assign flagout = {flags, outp1[32]};
    assign out = outp1[31:0];

    always @(op or in1 or in2) begin
        case(op)
            4'b0100: begin //xor
            outp1 <= in1 ^ in2;
            outp1[32] <= 1'b0;
            end
            4'b0101: begin //add
            outp1 = in1 + in2;
            end
            4'b0110: begin //rotate
            if (in2[3]) begin //negative, rotate left. Miracle if this works
                outp1[32:1] = in1;
                for (i = 0; i < ((~in2[3:0])+1); i=i+1) begin
                    for (j=1; j < 33; j=j+1)begin
                        outp1[j-1] = outp1[j];
                    end
                    outp1[32] = outp1[0];
                end
                outp1[31:0] = outp1[32:1];
                outp1[32] = 1'b0;
            end
            else begin//rotate right
                outp1[31:0] = in1;
                for (i = 0; i < in2[3:0]; i=i+1 ) begin
                    for (j = 31; j > -1; j = j-1) begin
                        outp1[j+1] = outp1[j];
                    end
                    outp1[0] = outp1[32];
                end
                outp1[32] = 1'b0;
            end
            end
            4'b0111: begin //shift
            if (in2[3]) begin //negative shift left
                outp1[31:0] <= in1 << ((~in2[3:0])+1);
                outp1[32] <= 1'b0;
            end
            else begin
                outp1[31:0] <= in1 >> in2[3:0];
                outp1[32] <= 1'b0;
            end
            end
            4'1001: begin //complement
                outp1[31:0] = ~in1;
                outp1[32] = 1'b0;
            end
            default: begin//other ops don't use the alu
                outp1 = outp1
            end
        endcase
    end
endmodule

module flagFinder(in, flags);
    input [31:0] in;
    output reg [4:1] flags;

    always @(in) begin
        //Zero
        if (in == 32'b0) begin
            flags[4] <= 1'b1;
        end
        else begin
            flags[4] <= 1'b0;
        end
        //Negative
        flags[3] <= in[31];
        //Even
        flags[2] <= ~in[0];
        //Parity
        flags[1] <= ~^in;
    end
endmodule

module processor(prgwrite, prgInstructions, outclk);
    input prgwrite;
    input [31:0] prgInstructions;
    output outclk;

    wire clk, countEN, ramWrite, regWrite;
    wire [3:0] regAddress;
    wire [4:0] flags, aluflags;
    wire [11:0] count, ramAddress;
    wire [31:0] instrn, inRegData, outRegData, inRamData, outRamData, aluin1, aluin2, aluout;

    clkgen generator(clk);
    ProgramCounter counter(clk, prgwrite, 1'b0, 12'b0, count);
    RAM InstReg(clk, count, prgwrite, prgInstructions, instrn);
    RegisterFile workRegs(clk, regAddress, regWrite, inRegData, outRegData);
    RAM memory(clk, ramAddress, ramWrite, inRamData, outRamData);
    PSR psr(clk, aluflags, flags);
    ALUbehave alu(instrn[31:28], aluin1, aluin2, aluout, aluflags);


    assign outclk = clk;

    always @(posedge clk) begin
        if (~prgwrite) begin
            /*
            case(instrn[31:28])
                4'b0000: begin
                    ramWrite <= 1'b0;
                    regWrite <= 1'b0;
                end
            */
        end
    end
endmodule

module processorTest();
    wire clk;
    reg prgwrite;
    reg [31:0] prgInstructions;
    reg [31:0] fullprgm [4095:0];
    integer i;

    processor uut(prgwrite, prgInstructions, clk);

    initial begin
        //reads the test code in from a file compiled with my python compliler script I wrote. Set the path appopriately
        $readmemb("C:/Users/ellen/Documents/school/ECSE318_code/Lab3/outfile.txt", fullprgm);
        prgwrite = 1'b1;
        for (i = 0; i < 4096; i = i + 1) begin
            prgInstructions <= fullprgm[i];
            wait (1'b1) @(posedge clk);
        end
        prgwrite = 1'b0;
        $display("program load done");
    end
endmodule

module testflagFinder();
    reg [31:0] in;
    wire [4:1] out;

    flagFinder uut(in, out);

    initial begin
        $monitor("%4t  %32b  %d  %4b", $time, in, in, out);
        in <= 7;
        #5
        in <= 3;
        #5
        in <= 4;
        #5
        in <= -3;
        #5
        in <= 0 ;
        #5
        $finish;
    end
endmodule

module testALU();
    reg [31:0] in1, in2;
    reg [3:0] op;
    wire [31:0] out;
    wire [4:0] flags;

    ALUbehave uut(in, out);

    initial begin
        $monitor("%4t a=%b b=%b op=%b | out=%b flag=%b", $time, in1, in2, op, out, flags);
        in1 <= 1; in2 <= 3; op <= 4;
        #5
        in1 <= 3; in2 <= 3; op <= 4;
        #5
        in1 <= 1; in2 <= 3; op <= 5;
        #5
        in1 <= 'hFFFFFFFF; in2 <= 'hFFFFFFFF; op <= 5;
        #5
        in <= 0 ;
        #5
        $finish;
    end
endmodule