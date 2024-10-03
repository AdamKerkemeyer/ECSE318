module freecellPlayer(clock, source, dest, win);
    input clock;
    input [3:0] source, dest;
    output reg win;
    //add other global variables here:

    //each column adds progressively so spot 0 is the highers (all cards above must be removed first)
    /*reg [5:0] col0 [15:0];
    reg [5:0] col1 [15:0];
    reg [5:0] col2 [15:0];
    reg [5:0] col3 [15:0];
    reg [5:0] col4 [15:0];
    reg [5:0] col5 [15:0];
    reg [5:0] col6 [15:0];
    reg [5:0] col7 [15:0]; */
    reg [5:0] col [7:0][15:0];
    //Home cells (only hold 1 card at a time, will be overwritten in an event of another valid placement)
    //space for 4 cards, one of each suite
    reg [5:0] home [3:0];
    //free cells
    reg [5:0] free [3:0];
    //record the largest occupied spot in each row sp we don't have to check
    integer largest [7:0];
    //set T/F if the source and destination are valid, 0 = false, 1 = true
    reg sourceValid, destValid;
    //best practice to treat source and destination inputs as read only
    //This is the card we are picking up from the source and moving to the destination
    reg [5:0] card;
    //Need to remember which home placement was valid
    integer homeSpot;
    reg [1:0] i; //used for loop of free cells
    reg[2:0] j; //used for loop of columns
    integer k; //Used to find which home cell a card's destination may be
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
    integer loop;

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
        col[0][0] = S4;
        col[0][1] = DJ;
        col[0][2] = D10;
        col[0][3] = D6;
        col[0][4] = S3;
        col[0][5] = DA;
        col[0][6] = HA;
        for (loop = 7; loop <= 15; loop = loop + 1) begin
            col[0][i] = EMPTY;
        end
        largest[0] = 6;

        col[1][0] = S5;
        col[1][1] = S10;
        col[1][2] = H8;
        col[1][3] = C4;
        col[1][4] = H6;
        col[1][5] = HK;
        col[1][6] = H2;
        for (loop = 7; loop <= 15; loop = loop + 1) begin
            col[1][i] = EMPTY;
        end
        largest[1] = 6;

        col[2][0] = SJ;
        col[2][1] = C7;
        col[2][2] = C9;
        col[2][3] = C6;
        col[2][4] = C2;
        col[2][5] = SK;
        col[2][6] = CA;
        for (loop = 7; loop <= 15; loop = loop + 1) begin
            col[2][i] = EMPTY;
        end
        largest[2] = 6;

        col[3][0] = H4;
        col[3][1] = SA;
        col[3][2] = CQ;
        col[3][3] = C5;
        col[3][4] = S7;
        col[3][5] = H9;
        col[3][6] = S8;
        for (loop = 7; loop <= 15; loop = loop + 1) begin
            col[3][i] = EMPTY;
        end
        largest[3] = 6;

        col[4][0] = DQ;
        col[4][1] = HJ;
        col[4][2] = SQ;
        col[4][3] = S6;
        col[4][4] = D2;
        col[4][5] = S9;
        for (loop = 6; loop <= 15; loop = loop + 1) begin
            col[4][i] = EMPTY;
        end
        largest[4] = 5;

        col[5][0] = D5;
        col[5][1] = DK;
        col[5][2] = C3;
        col[5][3] = D9;
        col[5][4] = H3;
        col[5][5] = S2;
        for (loop = 6; loop <= 15; loop = loop + 1) begin
            col[5][i] = EMPTY;
        end
        largest[5] = 5;

        col[6][0] = H5;
        col[6][1] = D3;
        col[6][2] = HQ;
        col[6][3] = D7;
        col[6][4] = CK;
        col[6][5] = C10;
        for (loop = 6; loop <= 15; loop = loop + 1) begin
            col[6][i] = EMPTY;
        end
        largest[6] = 5;

        col[7][0] = CJ;
        col[7][1] = D4;
        col[7][2] = H10;
        col[7][3] = C8;
        col[7][4] = H7;
        col[7][5] = D8;
        for (loop = 6; loop <= 15; loop = loop + 1) begin
            col[7][i] = EMPTY;
        end
        largest[7] = 5;

        home[0] = 6'b000000;
        home[1] = 6'b000000;
        home[2] = 6'b000000;
        home[3] = 6'b000000;

        free[0] = 6'b000000;
        free[1] = 6'b000000;
        free[2] = 6'b000000;
        free[3] = 6'b000000;
    end

    always @(posedge clock) begin 
        sourceValid = 0;
        destValid = 0; //assume source and destination are not valid on startup
        card = EMPTY; //not currently holding a card
        homeSpot = 0;
	k = 0; //reset
        i = 2'b00;
        j = 3'b000;
        //Pass in the source as input for a case
        case(source)
            //When I played freeCell online we could pull from the home cell stack, so this could represent that move
            4'b11xx: $display("Illegal input"); //don't need to set sourceValid = 0 as that is default.
            4'b10xx: begin //grabbing from free cell
                i = source[1:0]; //grab the free cell of interest
                if(free[i] != EMPTY) begin //if it is empty there will be nothing to pickup, thus not valid
                    card = free[i]; //pickup the card from free[i]
                    sourceValid = 1; //don't wipe free[0] till we see if dest is valid
                end
            end
            //Go through the tableau with a similar for loop:
            4'b1xxx: begin //grabbing from column
                j = source[2:0];
                if(col[j][0] != EMPTY) begin//check if there is at least 1 element in the column
                    card = col[j][largest[j]];
                    sourceValid = 1;
                end
            end
            default: $display("Debugging: SRC input not recognized.");
        endcase
        //Must check the source first so we know what card we are holding
        case(dest)
            4'b11xx: begin //home cell
                //This is an attempt to send the card we are holding home
                //need to figure out which home, if any it belongs to
                for(k = 0; k < 4; k = k+1) begin
                    if(home[k][5:4] == card[5:4] && home[k][3:0] == (card[3:0]-1'b1)) begin
                        destValid = 1;
                        homeSpot = k;
                    end
                end
            end
            4'b10xx: begin //free cell
                i = dest[1:0];
                if(free[i] == EMPTY)
                    destValid = 1;
            end
            4'b0xxx: begin //column of tableau
                j = dest[2:0];
                if(col[j][0] == EMPTY)//check if empty column
                    destValid = 1; 
                //Need to check the suite (MSB indicates red or black) and then check if the card being moved is 1 less
                else if((col[j][largest[j]][5] != card[5]) && (col[j][largest[j]][3:0] == (card[3:0] + 1'b1))) begin
                    destValid = 1;
                end //otherwise destValid remains at 0
            end
        endcase
    end

    //Check the move on the positive edge of the clock and commit the move on the negedge of the clock
    //This will ensure we check the move is valid before making the move. Ensuring proper timing without delay
    always @(negedge clock) begin
        if((sourceValid == 1) && (destValid == 1)) begin
            case(source) //delete the card from the source
                4'b10xx: begin
                    free[i] = EMPTY;
                end
                4'b1xxx: begin
                    j = source[2:0];
                    col[j][largest[j]] = EMPTY;
                    largest[j] = largest[j] - 1; //shorten length of column by 1
                end
            endcase
            case(dest) //place at the destination
                //Place at home will just overwrite previous
                4'b11xx: home[homeSpot] = card;
		//Place at free cell
                4'b10xx: begin 
                    i = dest[1:0];
                    free[i] = card; //nothing to overwrite
                end
		//place in column of tableau
                4'b0xxx: begin
                    j = dest[2:0];
                    largest[j] = largest[j] + 1; //increase length of column by 1
                    col[j][largest[j]] = card; 
                end
            endcase
            $display("Card: %b Source: %b Destination: %b Successful!", card, source, dest);
        end
        else $display("Attempted move was not valid");
        //assign win equal to true if there is a king in each home spot, order of suite doesn't matter
        assign win = (home[0] == 6'bxx1101 && home[1] == 6'bxx1101 && home[2] == 6'bxx1101 && home[3] == 6'bxx1101);
    end
endmodule