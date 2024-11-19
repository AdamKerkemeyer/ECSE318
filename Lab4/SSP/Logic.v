/*
Transmit & Recieve Logic:
Transmit seciton will read bytes from transmit FIFO and perform parallel to series conversion
Transmit is synchronyzed to the SSPCLKOUT through SSPTXD and SSPFSSOUT pins
Recieve logic is synchronyzed by SSPCLKIN which is recieved by broadcasting from peripheral
Recieve logic performs serial to parallel conversion on incoming synchronous SSPRXD data stream
*/

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
    reg slowCLK <= 1'b0;
    assign SSPCLKOUT = slowCLK; 

    //For the sake of readability I am going to put transmit and recieve in two seperate always blocks with seperate declarations
    //Transmission:
    reg [7:0] transmit <= 8'b00000000;
    reg TxWrite;
    reg sspoeB;
    wire beginTransmit;
    reg [3:0] TxShiftCount <= 4'b0000;       //Remember how many shifts have occured
    reg TxState <= 2'b00;                    //0 for idle, 1 for load, 2 for shifting
    initial begin
        sspoeB <= 1'b1;                     //Low active output enable
    end
    assign SSPOE_B = sspoeB;
    assign TxLOGICWRITE = TxWrite;
    assign SSPFSSOUT = beginTransmit;
    assign SSPTXD = transmit[7];    //Whatever is in last spot of transmit register will be on wire
    /*
    For the transmission to work, we need a number of things to be true:
    1. Tx FIFO is not empty (~TxEMPTY)
    2. PWRITE is 1
    3. TxLOGICWRITE is set to high (TxWrite <= 1)
    4. CLEAR_B is high (active low)
    */
    always @(*) begin                       //MSB is sent first
        if(!slowCLK) begin                  //SSPCLKOUT is low
            if(TxState == 2'b00) begin      //idle
                if(!TxEMPTY) begin          //Can transmit if currently idle and transmit is loaded
                    TxState <= 2'b01;       //State becomed loading
                end
                else begin
                    TxState <= 2'b00;       //Do nothing
                end
            end
            else if(TxState == 2'b01) begin //Tx state is load
                TxState <= 2'b10;           //Go to shifting mode
            end
            else if(TxState == 2'b10) begin
                if(TxShiftCount < 6) begin  //Normal behavior for first 7 bits.
                    TxShiftCount <= TxShiftCount + 1'b1;
                end
                else if(TxShiftCount == 6) begin
                    if(!TxEMPTY) begin
                        TxShiftCount <= 8;   //Immediately go into sending another transmission
                    end
                    else begin
                        TxShiftCount <= TxShiftCount + 1'b1;
                    end
                end
                else if(TxShiftCount == 7) begin
                    TxShiftCount <= 0;      //Reset counter
                    TxState <= 2'b00;           //Return to idle after sending
                end
                else if(TxShiftCount == 8) begin //Special case
                    TxShiftCount <= 0;      //Don't leave sending state, go into another send immediately
                end
                else begin                  //Catch all
                    TxState <= 2'b00;           //Break and return to idle (give up on transmission)
                end
            end
            //Otherwise do nothing
        end
        //Tell Tx another word is coming (TxWrite is tied to TxLOGICWRITE)
        TxWrite <= ((slowCLK == 1'b0) && (beginTransmit == 1'b1)); 
    end
    //Transmit that should only run on PCLK:
    always @(posedge PCLK) begin
        if(!slowCLK) begin
            if(TxState == 2'b01) begin      //In either if or else if, load new value in. 
                transmit <= TxDATA;
            end
            else if(TxState == 2'b10 && TxShiftCount == 8) begin
                transmit <= TxDATA;
            end
            else begin                      //If we aren't loading we are sending via shifting
                transmit <= {transmit[6:0], 1'b0};   //Remember the SSPTXD assign we made.
            end
        end

        if(beginTransmit && slowCLK) begin
            sspoeB <= 1'b0;
        end
        else if((TxState == 2'b00) && slowCLK) begin
            sspoeB <= 1'b1;                //Pulse high
        end
        else begin
            sspoeB <= sspoeB;             //Do nothing
        end
    end
    assign beginTransmit = (TxState == 2'b01) || (TxShiftCount == 8);

    //Recieve
    reg [7:0] recieve <= 8'b00000000;
    reg RxRead;                             //assign to RxLOGICWRITE
    wire beginReceive;
    reg pastSSPCLKIN;
    reg [3:0] RxShiftCount <= 4'b0000;       //Remember how many shifts have occured
    reg RxState <= 2'b00;                    //0 for idle, 1 for load, 2 for shifting
    
    assign beginReceive = ((RxState == 2'b01) || (RxShiftCount == 8));

    assign RxDATA = recieve;                //Continual assignment for the data (passed to RxFIFO)
    assign RxLOGICWRITE = RxRead;

    wire SSPCLKIN_rising  = SSPCLKIN && ~pastSSPCLKIN;
    wire SSPCLKIN_falling = ~SSPCLKIN && pastSSPCLKIN;

    always @(*) begin                       //MSB is sent first
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