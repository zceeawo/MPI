`timescale 1ns / 1ps

module FIFO #(parameter n = 128, parameter d = 8)
(
    input logic clock,
    input logic reset,
    input logic [n-1:0] idata,
    input logic ivalid,
    output logic [n-1:0] odata,
    output logic ovalid,
    output logic empty,
    input logic oready
);

logic [d-1:0] count;
logic [d-1:0] readpoint;
logic [d-1:0] writepoint;
logic [n-1:0] mem [0:(2**d)-1];

int i;

always @(posedge clock)
begin
    if (reset == 0)
    begin
        for (i = 0; i < 2**d; i = i + 1)
        begin
            mem[i] <= 0;
        end
        odata <= 0;
        ovalid <= 0;
        readpoint <= 0;
        writepoint <= 0;
        count <= 0;
        empty <= 1;
    end
    else
    begin
        if (ivalid == 1 && oready == 1 && count > 0)
        begin
            mem[writepoint] <= idata;
            writepoint <= writepoint + 1;
            odata <= mem[readpoint];
            readpoint <= readpoint + 1;
            ovalid <= 1;
        end
        else if (ivalid == 1)
        begin
            mem[writepoint] <= idata;
            writepoint <= writepoint + 1;
            count <= count + 1;
            ovalid <= 0;
        end
        else if (oready == 1 && count > 0)
        begin
            odata <= mem[readpoint];
            readpoint <= readpoint + 1;
            count <= count - 1;
            ovalid <= 1;
        end
        else
        begin
            ovalid <= 0;
        end
        
        if (count > 0)
        begin
            empty <= 0;
        end
        else
        begin
            empty <= 1;
        end
    end
end
    
endmodule

