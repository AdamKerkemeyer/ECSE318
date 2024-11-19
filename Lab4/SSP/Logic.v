/*
Transmit & Recieve Logic:
Transmit seciton will read bytes from transmit FIFO and perform parallel to series conversion
Transmit is synchronyzed to the SSPCLKOUT through SSPTXD and SSPFSSOUT pins
Recieve logic is synchronyzed by SSPCLKIN which is recieved by broadcasting from peripheral
Recieve logic performs serial to parallel conversion on incoming synchronous SSPRXD data stream
*/

//CURRENTLY THIS LOGIC IS NOT WORKING AS EXPECTED.
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
        if(!Clear_B) begin
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
    wire beginReceive;
    reg pastSSPCLKIN;
    reg [3:0] RxShiftCount = 4'b0000;       //Remember how many shifts have occured
    reg [1:0] RxState = 2'b00;                    //0 for idle, 1 for load, 2 for shifting
    
    assign beginReceive = ((RxState == 2'b01) || (RxShiftCount == 8));

    assign RxDATA = recieve;                //Continual assignment for the data (passed to RxFIFO)
    assign RxLOGICWRITE = RxRead;

    wire SSPCLKIN_rising  = SSPCLKIN && ~pastSSPCLKIN;
    wire SSPCLKIN_falling = ~SSPCLKIN && pastSSPCLKIN;

    always @(posedge PCLK or negedge PCLK) begin                       //MSB is sent first
        if(SSPCLKIN_falling) begin          
            if(RxState == 2'b00) begin      //idle
                if(SSPFSSIN) begin          //If idle and recieve request to intake data
                    RxState <= 2'b10;       //State becomed reading (no load)
                    RxShiftCount <= 7;       //Set counter to start at bit 7 and count down to 0, (MSB is sent first)
                end
                else begin
                    RxState <= 2'b00;       //Do nothing
                end
            end
            else if(RxState == 2'b10) begin
                if(RxShiftCount > 0) begin  //Normal behavior for first 7 bits.
                    RxShiftCount <= RxShiftCount - 1'b1;
                end
                else if(RxShiftCount == 0) begin
                    if(SSPFSSIN) begin
                        RxShiftCount <= 7;   //Immediately go into sending another transmission
                    end
                    else begin
                        RxShiftCount <= RxShiftCount - 1'b1;
                        RxState <= 2'b00;
                    end
                end
                else begin                  //Catch all
                    RxState <= 0;           //Break and return to idle (give up on transmission)
                end
            end
            //Otherwise do nothing
        end
        //RxRead is not set how TxWrite is set because RxRead is based on external stimuli
        //RxRead <= ((slowCLK == 1'b0) && (beginReceive == 1'b1)); 
    end
    //Recieve that should only run on PCLK:
    always @(posedge PCLK) begin
        pastSSPCLKIN <= SSPCLKIN; //Remember last SSPCLK clock (clock is 1/2 speed so this works)
        
        if(SSPCLKIN_falling) begin
            //RxState may not update in time, and we don't need to check it to load in value so we will not.
            //This way the register is always writing and we just grab it when we detect that it is ready. 
            recieve <= {recieve[6: 0], SSPRXD}; 
        end
        //If SSPCLKIN is not on falling edge, do nothing. 

        if(RxShiftCount == 0 && SSPCLKIN_rising) begin
            RxRead <= 1'b1;
        end
        else begin
            RxRead <= 1'b0;
        end
    end


    //Run Regardless: Does SSP need a conditinoal reset?
    /*
    always @(posedge PCLK) begin
        slowCLK <= ~slowCLK;    //1/2 speed because this clock switches only on pos. edge of PCLK.
        if (!CLEAR_B) begin
            SSPCLKOUT <= 1'b0;
            transmit <= 8'b00000000;
            recieve <= 8'b00000000;
            RxData <= 8'b00000000;
            TxLOGICWRITE <= 0;
            RxLOGICWRITE <= 0;
        end
    end
    */
endmodule