/*
Transmit & Recieve Logic:
Transmit seciton will read bytes from transmit FIFO and perform parallel to series conversion
Transmit is synchronyzed to the SSPCLKOUT through SSPTXD and SSPFSSOUT pins
Recieve logic is synchronyzed by SSPCLKIN which is recieved by broadcasting from peripheral
Recieve logic performs serial to parallel conversion on incoming synchronous SSPRXD data stream
*/

//CURRENTLY THIS LOGIC IS NOT WORKING AS EXPECTED.
//I think SSPOE_B goes low at the correct time but then does not go back up correctly
//I think the TxInterrupt flag is working correctly
//I cannot figure out why no data at all is being written to DataOut when Rx seems to be working. 
module logic(PCLK, SSPCLKIN, CLEAR_B, SSPFSSIN, SSPRXD, TxDATA, TxEMPTY, SSPCLKOUT,
        SSPOE_B, SSPFSSOUT, SSPTXD, TxLOGICWRITE, RxLOGICWRITE, RxDATA);
    //Inputs:
    input PCLK;                 //Clock for SSP
    input SSPCLKIN;             //Sync clock for recieving data, 1/2 speed of PCLK
    input CLEAR_B;              //Low active clear used to initialize SSP
    input SSPFSSIN;             //Frame control signal for reception
    input SSPRXD;               //Serial Data In Wire
    //Outputs:
    output SSPOE_B;             //Active low output enable. It will go low on negative edge of SSPCLKOUT
                                //It will go back up on the negative edge of SSPCLKOUT after data transfer (tell when transmission is done)
    output SSPFSSOUT;           //Frame control signal for transmission
    output SSPCLKOUT;           //Sync clock for sending data, 1/2 speed of PCLK
    output SSPTXD;              //Serial Data Out Wire
    //Internal in/out wires to Tx and Rx FIFO:
    output TxLOGICWRITE;        //Logic Write for Tx
    output RxLOGICWRITE;        //Logic Write for Rx
    input TxEMPTY;              //See if Tx is full
    input [7:0] TxDATA;         //From Tx, byte to transmit.
    output [7:0] RxDATA;        //To Rx, byte recieved.

    //SSPCLKOUT:
    reg slowCLK = 1'b0;
    assign SSPCLKOUT = slowCLK; 
    always @(posedge PCLK) begin
        slowCLK <= ~slowCLK;
    end
    //For the sake of readability I am going to put transmit and recieve in two seperate always blocks with seperate declarations
    //Transmission:
    reg [7:0] transmit = 8'b00000000;
    reg TxWrite;
    reg sspoeB = 1'b1;
    wire beginTransmit;
    reg [3:0] TxShiftCount = 4'b0000;       //Remember how many shifts have occured
    //reg [1:0] TxState = 2'b00;             //0 for idle, 1 for load, 2 for shifting
    reg [3:0] TxMode = 4'b0000;             //This is like TxShiftCount and TxState mashed together
    reg [3:0] nextTxMode = 4'b0000;         //Next TxMode
    //TxMode: 0=idle, 1=load, 2=shift7, 3=shift6, 4=shift5, 5=shift4, 6=shift3, 7=shift2, 8=shift1, 9=shift0, 10=shift0&load

    assign SSPOE_B = sspoeB;
    assign TxLOGICWRITE = TxWrite;
    assign SSPFSSOUT = beginTransmit;
    assign SSPTXD = transmit[7];    //Whatever is in last spot of transmit register will be on wire
    assign beginTransmit = (TxMode == 4'd0) || (TxMode == 4'd10);

    /*
    For the transmission to work, we need a number of things to be true:
    1. Tx FIFO is not empty (~TxEMPTY)
    2. PWRITE is 1
    3. TxLOGICWRITE is set to high (TxWrite <= 1)
    4. CLEAR_B is high (active low)
    */
    always @(*) begin//Swapped with *                      //MSB is sent first
        if(!slowCLK) begin                  //SSPCLKOUT is low
            if(TxMode == 4'd0) begin        //idle
                if(!TxEMPTY) begin          //Can transmit if currently idle and transmit is loaded
                    nextTxMode <= 4'd1;     //State becomed loading
                end
                else begin
                    nextTxMode <= 4'd0;       //Do nothing
                end
            end
            else if(TxMode == 4'd1) begin //Tx state is load
                nextTxMode <= 4'd2;           //Go to shifting mode
            end
            else if(TxMode >= 2 && TxMode <= 7) begin
                nextTxMode <= TxMode + 4'd1;
            end
            else if(TxMode == 8) begin
                if(!TxEMPTY) begin
                    nextTxMode <= 4'd10; //There is nothing after last shift so return to 0.
                end
                else begin
                    nextTxMode <= 4'd9; //Return to idle
                end
            end
            else if(TxMode == 9) begin
                nextTxMode <= 4'd0;
            end
            else if(TxMode == 10) begin
                nextTxMode <= 4'd2;
            end
            else begin
                nextTxMode <= 4'd0;
            end
            //Otherwise do nothing
        end
        //Tell Tx another word is coming (TxWrite is tied to TxLOGICWRITE)
        TxWrite <= ((!slowCLK) && (beginTransmit)); 
    end
    //Transmit that should only run on PCLK:
    always @(posedge PCLK) begin
        if(!CLEAR_B) begin
            TxMode <= 4'b0000;
        end
        else begin
            TxMode <= nextTxMode;       //Tx Mode only updates once on the PCLK
        end
        if(!slowCLK) begin
            if(TxMode == 4'd1 || TxMode == 4'd10) begin      //In either if or else if, load new value in. 
                transmit <= TxDATA;
            end
            else begin                      //If we aren't loading we are sending via shifting
                transmit <= {transmit[6:0], 1'b0};   //Remember the SSPTXD assign we made.
            end
        end

        if(beginTransmit && slowCLK) begin
            sspoeB <= 1'b0;
        end
        else if((TxMode == 4'd0) && slowCLK) begin
            sspoeB <= 1'b1;                //Pulse high
        end
        else begin
            sspoeB <= sspoeB;             //Do nothing
        end
    end

    //Recieve
    reg [7:0] recieve = 8'b00000000;
    reg RxRead;                             //assign to RxLOGICWRITE
    reg pastSSPCLKIN;
    reg [3:0] RxShiftCount = 4'b0000;       //Remember how many shifts have occured
    //reg [1:0] RxState = 2'b00;                    //0 for idle, 1 for load, 2 for shifting
    reg [3:0] RxMode = 4'd0;
    reg [3:0] nextRxMode = 4'd0;
    //RxMode: 0=idle, 1=shift7, 2=shift6, 3=shift5, 4=shift4, 5=shift3, 6=shift2, 7=shift1, 8=shift0

    assign RxDATA = recieve;                //Continual assignment for the data (passed to RxFIFO)
    assign RxLOGICWRITE = RxRead;

    wire SSPCLKIN_rising  = SSPCLKIN && ~pastSSPCLKIN;
    wire SSPCLKIN_falling = ~SSPCLKIN && pastSSPCLKIN;

    always @(*) begin                       //MSB is sent first
        if(SSPCLKIN_falling) begin          
            if(RxMode == 4'd0) begin      //idle
                if(SSPFSSIN) begin          //If idle and recieve request to intake data
                    nextRxMode <= 4'd1;       //State becomed reading (no load)
                    //RxShiftCount <= 7;       //Set counter to start at bit 7 and count down to 0, (MSB is sent first)
                end
                else begin
                    nextRxMode <= 4'd0;       //Do nothing
                end
            end
            else if(RxMode > 4'd0 && RxMode < 4'd8) begin
                nextRxMode <= RxMode + 4'd1;
            end
            else if(RxMode == 4'd8) begin
                if(SSPFSSIN) begin
                    nextRxMode <= 4'd1;       //Go back to shift7 and recieve another immediately
                end
                else begin
                    nextRxMode <= 4'd0;       //Otherwise become idle
                end
            end
            else begin
                nextRxMode <= 4'd0;
            end
        end
        else begin
            nextRxMode <= RxMode;
        end
    end
    //Recieve that should only run on PCLK:
    always @(posedge PCLK) begin
        pastSSPCLKIN <= SSPCLKIN; //Remember last SSPCLK clock (clock is 1/2 speed so this works)
        
        if(!CLEAR_B) begin
            RxMode <= 4'd0;         //Reset mode
        end
        else begin
            RxMode <= nextRxMode;
        end

        if(SSPCLKIN_falling) begin
            //RxState may not update in time, and we don't need to check it to load in value so we will not.
            //This way the register is always writing and we just grab it when we detect that it is ready. 
            recieve <= {recieve[6:0], SSPRXD}; 
        end
        else begin
            recieve <= recieve;
        end
        //If SSPCLKIN is not on falling edge, do nothing. 

        if((RxMode == 4'd8) && SSPCLKIN_rising) begin
            RxRead <= 1'b1; //RxLOGICWRITE to 1 if going idle
        end
        else begin
            RxRead <= 1'b0;
        end
    end
endmodule