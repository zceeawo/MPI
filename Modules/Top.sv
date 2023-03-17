`timescale 1ns / 1ps

module Top #(c = 12)
(
    input logic clock,
    input logic [0:c-1] tx_clock,
    input logic [0:c-1] rx_clock,
    input logic [0:c-1] tx_reset,
    output logic [0:128*c-1] tx_data,
    input logic [0:128*c-1] rx_data,
    output logic [0:6*c-1] tx_header,
    output logic [0:c-1] rx_slip,
    input logic activate
);

parameter x = 3;
parameter J = 1;
parameter L = 1;

parameter j = 0;
parameter l = 0;

parameter w = 128; // BRAM DATA WIDTH IN BITS
parameter BDD = 32; // BRAM DATA DEPTH IN BITS

function int log2 (input int number);
    int k = 0;
    while(2**k < number)
    begin
        k = k + 1;
    end
    return k;
endfunction

parameter d = log2(BDD);

Controller_Transceiver #(x,w,d) Controller_Transceiver
(
.clock(clock),
.tx_clock({tx_clock[0],tx_clock[1],tx_clock[2]}),
.rx_clock({rx_clock[3],rx_clock[4],rx_clock[5]}),
.tx_reset({tx_reset[0],tx_reset[1],tx_reset[2]}),
.tx_data({tx_data[0*w+:w],tx_data[1*w+:w],tx_data[2*w+:w]}),
.rx_data({rx_data[3*w+:w],rx_data[4*w+:w],rx_data[5*w+:w]}),
.tx_header({tx_header[0*6+:6],tx_header[1*6+:6],tx_header[2*6+:6]}),
.rx_slip({rx_slip[3],rx_slip[4],rx_slip[5]}),
.activate(activate)
);

Node_Transceiver #(x,J,L,0,j,l,w,d) Node_Transceiver_0
(
.clock(clock),
.tx_clock({tx_clock[3],tx_clock[6],tx_clock[7]}),
.rx_clock({rx_clock[0],rx_clock[8],rx_clock[10]}),
.tx_reset({tx_reset[3],tx_reset[6],tx_reset[7]}),
.tx_data({tx_data[3*w+:w],tx_data[6*w+:w],tx_data[7*w+:w]}),
.rx_data({rx_data[0*w+:w],rx_data[8*w+:w],rx_data[10*w+:w]}),
.tx_header({tx_header[3*6+:6],tx_header[6*6+:6],tx_header[7*6+:6]}),
.rx_slip({rx_slip[0],rx_slip[8],rx_slip[10]}),
.activate(activate)
);

Node_Transceiver #(x,J,L,1,j,l,w,d) Node_Transceiver_1
(
.clock(clock),
.tx_clock({tx_clock[4],tx_clock[8],tx_clock[9]}),
.rx_clock({rx_clock[1],rx_clock[6],rx_clock[11]}),
.tx_reset({tx_reset[4],tx_reset[8],tx_reset[9]}),
.tx_data({tx_data[4*w+:w],tx_data[8*w+:w],tx_data[9*w+:w]}),
.rx_data({rx_data[1*w+:w],rx_data[6*w+:w],rx_data[11*w+:w]}),
.tx_header({tx_header[4*6+:6],tx_header[8*6+:6],tx_header[9*6+:6]}),
.rx_slip({rx_slip[1],rx_slip[6],rx_slip[11]}),
.activate(activate)
);

Node_Transceiver #(x,J,L,2,j,l,w,d) Node_Transceiver_2
(
.clock(clock),
.tx_clock({tx_clock[5],tx_clock[10],tx_clock[11]}),
.rx_clock({rx_clock[2],rx_clock[7],rx_clock[9]}),
.tx_reset({tx_reset[5],tx_reset[10],tx_reset[11]}),
.tx_data({tx_data[5*w+:w],tx_data[10*w+:w],tx_data[11*w+:w]}),
.rx_data({rx_data[2*w+:w],rx_data[7*w+:w],rx_data[9*w+:w]}),
.tx_header({tx_header[5*6+:6],tx_header[10*6+:6],tx_header[11*6+:6]}),
.rx_slip({rx_slip[2],rx_slip[7],rx_slip[9]}),
.activate(activate)
);

endmodule