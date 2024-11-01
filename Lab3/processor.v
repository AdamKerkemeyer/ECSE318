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
        //else outdata = mem[address];
    end
    assign outdata = mem[address];
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

    always @(posedge clk) if (enable) count = count + 1;

    always @(posedge set) count = countToSet;
endmodule

module ALUbehave(op, in1, in2, out, flagout);
    input [3:0] op;
    input [31:0] in1, in2;
    output reg [31:0] out;
    output [4:0] flagout;


    wire [4:1] flags;
    reg carryflag;
    integer i;


    flagFinder flg(out, flags);
    assign flagout = {flags, carryflag};


    always @(op or in1 or in2) begin
        casez(op)
        4'b0100: begin //xor
            out <= in1 ^ in2;
            carryflag <= 1'b0;
        end
        4'b0101: begin //add
            out <= in1 + in2;
            if (~in1[31] && ~in2[31] && out[31]) carryflag <= 1'b1; //positive overflow
            else if (in1[31] && in2[31] && ~out[31]) carryflag <= 1'b1; //negative overflow
            else carryflag <= 1'b0;
        end
        4'b0110: begin //rotate
            if (in2[3]) begin //negative, rotate left. Miracle if this works
                out = in1;
                carryflag = 1'b0;
                for (i = 0; i < 4'((~in2[3:0])+1); i=i+1) begin
                    out = {out[30:0], out[31]};
                end
            end
            else begin//rotate right
                out = in1;
                carryflag = 1'b0;                
                for (i = 0; i < in2[3:0]; i=i+1 ) begin
                    out = {out[0], out[31:1]};
                end
            end
        end
        4'b0111: begin //shift
            if (in2[3]) begin //negative shift left
                out <= in1 << 4'((~in2[3:0])+1);
                carryflag <= 1'b0;
            end
            else begin
                out <= in1 >> in2[3:0];
                carryflag <= 1'b0;
            end
        end
        4'b1001: begin //complement
            out = ~in1;
            carryflag = 1'b0;
        end
        default: begin//other ops don't use the alu
            out = out;
            carryflag = carryflag;
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

    wire clk;
    wire [4:0] flags, aluflags;
    wire [11:0] count;
    wire [31:0] instrn, outRamData, aluout;

    reg countSet, countEN, ramWrite, writeCycle;
    reg [3:0] regAddress;
    reg [11:0] newCount, ramAddress;
    reg [31:0] inRamData, aluin1, aluin2, lastinstrn;

    reg [31:0] regfile [15:0];

    clkgen generator(clk);
    ProgramCounter counter(clk, countEN, countSet, newCount, count);
    RAM InstReg(clk, count, prgwrite, prgInstructions, instrn);

    RAM memory(clk, ramAddress, ramWrite, inRamData, outRamData);
    PSR psr(clk, aluflags, flags);
    ALUbehave alu(instrn[31:28], aluin1, aluin2, aluout, aluflags);


    assign outclk = clk;

    initial begin //Initial values
        newCount <= {12{1'b0}};
        ramWrite <= 1'b0;
        countEN <= 1'b1;
        countSet <= 1'b0;
        ramAddress <= {12{1'b0}};
        inRamData <= {32{1'b0}};
        aluin1 <= {32{1'b0}};
        aluin2 <= {32{1'b0}};
        writeCycle <= 1'b0;
    end

    always @(negedge prgwrite) begin //When done writing set the counter back to 0.
        countSet = 1'b1;
        $display("switching to run mode");
    end

    always @(posedge clk) begin //op code decisions (the fun stuff)
        if (~prgwrite && ~writeCycle) begin //read new op code
            case(instrn[31:28])
                4'b0000: begin//nop
                    newCount <= {12{1'b0}};
                    ramWrite <= 1'b0;
                    countEN <= 1'b1;
                    countSet <= 1'b0;
                    ramAddress <= {12{1'b0}};
                    inRamData <= {32{1'b0}};
                    aluin1 <= {32{1'b0}};
                    aluin2 <= {32{1'b0}};
                    writeCycle <= 1'b0;
                end
                4'b0001: begin//load
                    countSet <= 1'b0;
                    newCount <= {12{1'b0}};
                    ramWrite <= 1'b0;
                    ramAddress <= instrn[23:12];
                    inRamData <= {32{1'b0}};
                    aluin1 <= {32{1'b0}};
                    aluin2 <= {32{1'b0}};
                    $display("outRamData: %h", outRamData);
                    if (instrn[27]) begin
                        writeCycle <= 1'b0;
                        countEN <= 1'b1;
                        regfile[instrn[3:0]] <= {{{20{1'b0}}}, instrn[23:12]};
                    end 
                    else begin
                        writeCycle <= 1'b1;
                        countEN <= 1'b0;
                        lastinstrn <= instrn;
                    end
                end
                4'b0010: begin//store
                    countSet <= 1'b0;
                    newCount <= {12{1'b0}};
                    ramWrite <= 1'b1;
                    countEN <= 1'b1;
                    ramAddress <= instrn[11:0];
                    inRamData <= instrn[27] ? {{{20{1'b0}}}, instrn[23:12]} : regfile[instrn[15:12]];
                    aluin1 <= {32{1'b0}};
                    aluin2 <= {32{1'b0}};
                    writeCycle <= 1'b0;
                end
                4'b0011: begin//branch
                    ramWrite <= 1'b0;
                    countEN <= 1'b1;
                    ramAddress <= {12{1'b0}};
                    inRamData <= {32{1'b0}};
                    aluin1 <= {32{1'b0}};
                    aluin2 <= {32{1'b0}};
                    writeCycle <= 1'b0;
                    case(instrn[26:24])
                        3'b000: begin//allways
                            countSet <= 1'b1;
                            newCount <= instrn[11:0];
                        end
                        3'b001: begin//parity
                            countSet <= flags[1];
                            newCount <= flags[1] ? instrn[11:0] : {12{1'b0}};
                        end
                        3'b010: begin//even
                            countSet <= flags[2];
                            newCount <= flags[2] ? instrn[11:0] : {12{1'b0}};
                        end
                        3'b011: begin//carry
                            countSet <= flags[0];
                            newCount <= flags[0] ? instrn[11:0] : {12{1'b0}};
                        end
                        3'b100: begin//negative
                            countSet <= flags[3];
                            newCount <= flags[3] ? instrn[11:0] : {12{1'b0}};
                        end
                        3'b101: begin//zero
                            countSet <= flags[4];
                            newCount <= flags[4] ? instrn[11:0] : {12{1'b0}};
                        end
                        3'b110: begin //no carry
                            countSet <= ~flags[0];
                            newCount <= ~flags[0] ? instrn[11:0] : {12{1'b0}};
                        end
                        3'b111: begin//positive
                            countSet <= ~flags[3];
                            newCount <= ~flags[3] ? instrn[11:0] : {12{1'b0}};
                        end
                    endcase
                end
                4'b0100: begin//xor
                    newCount <= {12{1'b0}};
                    ramWrite <= 1'b0;
                    countEN <= 1'b0;
                    countSet <= 1'b0;
                    ramAddress <= {12{1'b0}};
                    inRamData <= {32{1'b0}};
                    aluin1 <= regfile[instrn[11:0]];
                    aluin2 <= instrn[27] ? {{20{1'b0}}, instrn[23:12]} : regfile[instrn[23:12]];
                    writeCycle <= 1'b1;
                    lastinstrn <= instrn;
                end
                4'b0101: begin//add
                    newCount <= {12{1'b0}};
                    ramWrite <= 1'b0;
                    countEN <= 1'b0;
                    countSet <= 1'b0;
                    ramAddress <= {12{1'b0}};
                    inRamData <= {32{1'b0}};
                    aluin1 <= regfile[instrn[11:0]];
                    aluin2 <= instrn[27] ? {{20{1'b0}}, instrn[23:12]} : regfile[instrn[23:12]];
                    writeCycle <= 1'b1;
                    lastinstrn <= instrn;
                end
                4'b0110: begin//rotate
                    newCount <= {12{1'b0}};
                    ramWrite <= 1'b0;
                    countEN <= 1'b0;
                    countSet <= 1'b0;
                    ramAddress <= {12{1'b0}};
                    inRamData <= {32{1'b0}};
                    aluin1 <= regfile[instrn[11:0]];
                    aluin2 <= {{20{1'b0}}, instrn[23:12]};
                    writeCycle <= 1'b1;
                    lastinstrn <= instrn;
                end
                4'b0111: begin//shift
                    newCount <= {12{1'b0}};
                    ramWrite <= 1'b0;
                    countEN <= 1'b0;
                    countSet <= 1'b0;
                    ramAddress <= {12{1'b0}};
                    inRamData <= {32{1'b0}};
                    aluin1 <= regfile[instrn[11:0]];
                    aluin2 <= {{20{1'b0}}, instrn[23:12]};
                    writeCycle <= 1'b1;
                    lastinstrn <= instrn;
                end
                4'b1000: begin//halt
                    newCount <= {12{1'b0}};
                    ramWrite <= 1'b0;
                    countEN <= 1'b0;
                    countSet <= 1'b0;
                    ramAddress <= {12{1'b0}};
                    inRamData <= {32{1'b0}};
                    aluin1 <= {32{1'b0}};
                    aluin2 <= {32{1'b0}};
                    writeCycle <= 1'b0;
                    $display("halt command hit");
                    $finish;
                end
                4'b1001: begin//complement
                    newCount <= {12{1'b0}};
                    ramWrite <= 1'b0;
                    countEN <= 1'b0;
                    countSet <= 1'b0;
                    ramAddress <= {12{1'b0}};
                    inRamData <= {32{1'b0}};
                    aluin1 <= instrn[27] ? {{20{1'b0}}, instrn[23:12]} : regfile[instrn[23:12]];
                    aluin2 <= {32{1'b0}};
                    writeCycle <= 1'b1;
                    lastinstrn <= instrn;
                end
            endcase
        end
        else if (~prgwrite) begin//write to registers after a alu op
            newCount <= {12{1'b0}};
            ramWrite <= 1'b0;
            countEN <= 1'b1;
            countSet <= 1'b0;
            ramAddress <= {12{1'b0}};
            inRamData <= {32{1'b0}};
            aluin1 <= {32{1'b0}};
            aluin2 <= {32{1'b0}};
            writeCycle <= 1'b0;
            if (lastinstrn[31:28] == 4'b0001) regfile[lastinstrn[11:0]] <= outRamData;
            else regfile[lastinstrn[11:0]] <= aluout;
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

    ALUbehave uut(op, in1, in2, out, flags);

    initial begin
        $monitor("%4t a=%h b=%h op=%d | out=%h flag=%b", $time, in1, in2, op, out, flags);
        in1 <= 1; in2 <= 3; op <= 4;
        #5
        in1 <= 3; in2 <= 3; op <= 4;
        #5
        in1 <= 1; in2 <= 3; op <= 5;
        #5
        in1 <= 'hFFFFFFFF; in2 <= 'hFFFFFFFF; op <= 5;
        #5
        in1 <= 3; in2 <= 1; op <= 6;
        #5
        in1 <= 3; in2 <= 3; op <= 6;
        #5
        in1 <= 'hC0000000; in2 <= 1; op <= 6;
        #5
        in1 <= 3; in2 <= -3; op <= 6;
        #5
        in1 <= 'hC0000000; in2 <= -1; op <= 6;
        #5
        in1 <= 'hC0000001; in2 <= 0; op <= 6;
        #5
        in1 <= 3; in2 <= 1; op <= 7;
        #5
        in1 <= 3; in2 <= 3; op <= 7;
        #5
        in1 <= 'hC0000000; in2 <= 1; op <= 7;
        #5
        in1 <= 3; in2 <= -3; op <= 7;
        #5
        in1 <= 'hC0000000; in2 <= -1; op <= 7;
        #5
        in1 <= 'hC0000001; in2 <= 0; op <= 7;
        #5
        in1 <= 'hC0000001; in2 <= 0; op <= 8;
        #5
        in1 <= 'hC0000001; in2 <= 0; op <= 9;
        #5
        $finish;
    end
endmodule