module freecellPlayer(clock, source, dest, win);
    input clock;
    input [3:0] source, dest;
    output win;
    //add other global variables here:

    //each column adds progressively so spot 0 is the highers (all cards above must be removed first)
    reg [5:0] col0 [15:0];
    reg [5:0] col1 [15:0];
    reg [5:0] col2 [15:0];
    reg [5:0] col3 [15:0];
    reg [5:0] col4 [15:0];
    reg [5:0] col5 [15:0];
    reg [5:0] col6 [15:0];
    reg [5:0] col7 [15:0];
    //Home cells (only hold 1 card at a time, will be overwritten in an event of another valid placement)
    //space for 4 cards, one of each suite
    reg [5:0] home [3:0];
    //free cells
    reg [5:0] free [3:0];

    /*Suite valuation First two bits:
    Heart = 00
    Diamond = 01
    Spade = 10
    Club = 11
    
    Ace = 1
    2-10 are normal
    Jack = 11
    Queen = 12
    King = 13
    */
    //Create variables for cards to improve readability: 
    localparam [5:0] HA = 6'b000001;
    localparam [5:0] H2 = 6'b000010;
    localparam [5:0] H3 = 6'b000011;
    localparam [5:0] H4 = 6'b000100;
    localparam [5:0] H5 = 6'b000101;
    localparam [5:0] H6 = 6'b000110;
    localparam [5:0] H7 = 6'b000111;
    localparam [5:0] H8 = 6'b001000;
    localparam [5:0] H9 = 6'b001001;
    localparam [5:0] H10 = 6'b001010;
    localparam [5:0] HJ = 6'b001011;
    localparam [5:0] HQ = 6'b001100;
    localparam [5:0] HK = 6'b001101;

    localparam [5:0] DA = 6'b010001;
    localparam [5:0] D2 = 6'b010010;
    localparam [5:0] D3 = 6'b010011;
    localparam [5:0] D4 = 6'b010100;
    localparam [5:0] D5 = 6'b010101;
    localparam [5:0] D6 = 6'b010110;
    localparam [5:0] D7 = 6'b010111;
    localparam [5:0] D8 = 6'b011000;
    localparam [5:0] D9 = 6'b011001;
    localparam [5:0] D10 = 6'b011010;
    localparam [5:0] DJ = 6'b011011;
    localparam [5:0] DQ = 6'b011100;
    localparam [5:0] DK = 6'b011101;

    localparam [5:0] SA = 6'b100001;
    localparam [5:0] S2 = 6'b100010;
    localparam [5:0] S3 = 6'b100011;
    localparam [5:0] S4 = 6'b100100;
    localparam [5:0] S5 = 6'b100101;
    localparam [5:0] S6 = 6'b100110;
    localparam [5:0] S7 = 6'b100111;
    localparam [5:0] S8 = 6'b101000;
    localparam [5:0] S9 = 6'b101001;
    localparam [5:0] S10 = 6'b101010;
    localparam [5:0] SJ = 6'b101011;
    localparam [5:0] SQ = 6'b101100;
    localparam [5:0] SK = 6'b101101;

    localparam [5:0] CA = 6'b110001;
    localparam [5:0] C2 = 6'b110010;
    localparam [5:0] C3 = 6'b110011;
    localparam [5:0] C4 = 6'b110100;
    localparam [5:0] C5 = 6'b110101;
    localparam [5:0] C6 = 6'b110110;
    localparam [5:0] C7 = 6'b110111;
    localparam [5:0] C8 = 6'b111000;
    localparam [5:0] C9 = 6'b111001;
    localparam [5:0] C10 = 6'b111010;
    localparam [5:0] CJ = 6'b111011;
    localparam [5:0] CQ = 6'b111100;
    localparam [5:0] CK = 6'b111101;

    localparam [5:0] EMPTY = 6'b000000;


    /*Initialize game 8321
    0    1     2     3   4    5   6    7
    S4   S5    SJ    H4  DQ   D5  H5   CJ 
    DJ   S10   C7    SA  HJ   DK  D3   D4 
    D10  H8    C9    CQ  SQ   C3  HQ   H10 
    D6   C4    C6    C5  S6   D9  D7   C8 
    S3   H6    C2    S7  D2   H3  CK   H7 
    DA   HK    SK    H9  S9   S2  C10  D8 
    HA   H2    CA    S8 
    */
    initial begin
        col0[0] = S4;
        col0[1] = DJ;
        col0[2] = D10;
        col0[3] = D6;
        col0[4] = S3;
        col0[5] = DA;
        col0[6] = HA;
        col0[7:15] = EMPTY;

        col1[0] = S5;
        col1[1] = S10;
        col1[2] = H8;
        col1[3] = C4;
        col1[4] = H6;
        col1[5] = HK;
        col1[6] = H2;
        col1[7:15] = EMPTY;

        col2[0] = SJ;
        col2[1] = C7;
        col2[2] = C9;
        col2[3] = C6;
        col2[4] = C2;
        col2[5] = SK;
        col2[6] = CA;
        col2[7:15] = EMPTY;

        col3[0] = H4;
        col3[1] = SA;
        col3[2] = CQ;
        col3[3] = C5;
        col3[4] = S7;
        col3[5] = H9;
        col3[6] = S8;
        col3[7:15] = EMPTY;

        col4[0] = DQ;
        col4[1] = HJ;
        col4[2] = SQ;
        col4[3] = S6;
        col4[4] = D2;
        col4[5] = S9;
        col4[6:15] = EMPTY;

        col5[0] = D5;
        col5[1] = DK;
        col5[2] = C3;
        col5[3] = D9;
        col5[4] = H3;
        col5[5] = S2;
        col5[6:15] = EMPTY;

        col6[0] = H5;
        col6[1] = D3;
        col6[2] = HQ;
        col6[3] = D7;
        col6[4] = CK;
        col6[5] = C10;
        col6[6:15] = EMPTY;

        col7[0] = CJ;
        col7[1] = D4;
        col7[2] = H10;
        col7[3] = C8;
        col7[4] = H7;
        col7[5] = D8;
        col7[6:15] = EMPTY;

        home[0] = 6'b000000;
        home[1] = 6'b000000;
        home[2] = 6'b000000;
        home[3] = 6'b000000;

        free[0] = 6'b000000;
        free[1] = 6'b000000;
        free[2] = 6'b000000;
        free[3] = 6'b000000;
    end

endmodule
