module UART_tb();
    parameter CLK_FREQ = 1_000_000; // System clock frequency in Hz (I made it 1 MHz for simplicity)
    parameter SAMPLE = 16;     // Most common oversampling in UART 
    logic SysClk; // system clock
    logic rst;  // reset signal is universal 
    logic [1:0] baud_selector;
    logic [7:0] data_in;  // external system logic data
    logic parity_sel;
    logic start_Tx; // to start the transaction between the two FIFOs 
    logic receive; // order to receive data from external system
    logic [8:0] data_out; // parallel logic data; the logic data increaced one bit
    logic OE, BE, FE;// Error logic signals

    // Instantiation
    UART_TOP #(CLK_FREQ, SAMPLE) dut (.*);

    initial begin
        SysClk = 0;
        forever #10 SysClk = ~SysClk;
    end
    // we will perform more than a scenario 
    // first scenario we will write in the Tx_FIFO four different values, transmit two values to Rx_FIFO and then receive just one value from Rx_FIFO
    // second scenario we will write again 3 values, transfer 3 and read 4
    // third scenario we will write until the Tx_FIFO is full then transfer to the Rx_FIFO untill full to test the Overrun error and then we will read all values until empty
    // these scenarios show the flexibility of our design and the ability of handling multiple scenarios
    //stimulus generation
    initial begin
        //reset first
        rst = 1;
        // initial values
        baud_selector = 1; // BAUD96
        parity_sel = 0; //even parity
        start_Tx = 1;
        receive = 0; // we don't want to receive from Rx_FIFO yet
        #20;
        //****************** First scenario *******************\\
        rst = 0;
        #230;
        // putting some data in the Tx_FIFO
        data_in = 8'b01010101; 
        #240; // wait for one clock cycle in baudclk 
        data_in = 8'b11100101;
        #240;
        data_in = 8'b11111111;
        #480;  // to test Tx_FIFO will handle any delay in data
        data_in = 8'b11100000;
        #240;
        start_Tx = 0; // start transmission from TX_FIFO to Rx_FIFO
        #4800; // sending two serialized data values to Rx_FIFO
        start_Tx = 1; 
        #2500; // just some time to ensure all the data are transfered and the TxFIFO is ready for more data
        receive = 1; // we will read just one value
        #300
        receive = 0;
        #240;
        //****************** Second scenario *******************\\
        data_in = 8'hbf;
        #240;
        data_in = 8'h1c;
        #240;
        data_in = 8'h25;
        #240;
        start_Tx = 0; // start transmission from TX_FIFO to Rx_FIFO
        #7000; // sending three serialized data values to Rx_FIFO
        start_Tx = 1;
        #3500; // just some time to ensure all the data are transfered and the TxFIFO is ready for more data
        receive = 1;
        #1300;   // receiving four values
        receive = 0;
        #40; // align with negedge
        //****************** Third scenario *******************\\
        #480;
        // reset to fill the Tx_FIFO from the beginning
        rst = 1;
        #240;
        rst=0;
        repeat(20) begin // writing until Tx_FIFO full, only first 16 random values will be stored in the FIFO the rest will be ignored as TxFF flag will rise
            data_in = $random;
            #240;
        end
        start_Tx = 0; // serialize all values to Rx_FIFO
        #60000; // transmitting all the values to Rx_FIFO
        start_Tx = 1;
        receive = 1; // receiving all Rx_FIFO values
        #4500;
        receive = 0;
        
        #500;
        $stop;
    end
endmodule
