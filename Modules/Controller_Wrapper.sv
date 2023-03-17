`timescale 1ns / 1ps

module Controller_Wrapper #(parameter x = 3, parameter w = 128, parameter d = 5)
(
    input logic clock,
    input logic reset,
    input logic [0:x-1] aligned,
    input logic [0:w*x-1] idata,
    input logic [0:x-1] ivalid,
    output logic [0:w*x-1] odata,
    output logic [0:x-1] ovalid
);

logic [0:x-1] fifooready;
logic [0:x-1] fifoovalid;
logic [0:x-1] fifoempty;
logic [0:w*x-1] fifoodata;

int i;

logic controllerreset;

always_ff @(posedge clock)
begin
    if (reset == 0)
    begin
        controllerreset <= 0;
        odata <= 0;
        ovalid <= 0;
    end
    else
    begin
        if (aligned == {x{1'b1}})
        begin
            controllerreset <= 1;

            if (fifoempty == 0)
            begin
                fifooready <= {x{1'b1}};
            end
            else
            begin
                fifooready <= 0;
            end
        end
    end
end

Controller #(x,w,d) Controller
(
    .clock(clock),
    .reset(controllerreset),
    .ivalid(fifoovalid),
    .idata(fifoodata),
    .ovalid(ovalid),
    .odata(odata)
);

genvar v;

generate
    for (v = 0; v < x; v = v + 1)
    begin
        FIFO #(w,2) FIFO
        (
            .clock(clock),
            .reset(reset),
            .idata(idata[w*v +: w]),
            .ivalid(ivalid[v]),
            .odata(fifoodata[w*v +: w]),
            .ovalid(fifoovalid[v]),
            .empty(fifoempty[v]),
            .oready(fifooready[v])
        );
    end
endgenerate

endmodule