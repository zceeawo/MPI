`timescale 1ns / 1ps

module Node_Wrapper #(parameter x = 3, parameter J = 1, parameter L = 1, parameter g = 0, parameter j = 0, parameter l = 0, parameter w = 128, parameter d = 5)
(
    input logic clock,
    input logic reset,
    input logic [0:x-1] aligned,
    input logic [0:w*x-1] idata,
    input logic [0:x-1] ivalid,
    output logic [0:w*x-1] odata,
    output logic [0:x-1] ovalid
);
 
logic [0:x-1] nodeovalid;
logic [0:w*x-1] nodeodata;

logic controllerivalid;
logic [0:w-1] controlleridata;

logic controllerovalid;
logic [0:w-1] controllerodata;

logic [0:w*x-1] fifoidata;
logic [0:x-1] fifoivalid;
logic [0:x-1] fifooready;
logic [0:x-1] fifoovalid;
logic [0:x-1] fifoempty;
logic [0:w*x-1] fifoodata;

logic nodereset;

int i;

always_ff @(posedge clock)
begin
    if (reset == 0)
    begin
        nodereset <= 0;
        odata <= 0;
        ovalid <= 0;
        fifoidata <= 0;
        fifoivalid <= 0;
        controllerivalid <= 0;
        controlleridata <= 0;
    end
    else
    begin
        if (aligned == {x{1'b1}})
        begin
            nodereset <= 1;

            controlleridata <= idata[0 +: w];
            controllerivalid <= ivalid[0];

            odata[0 +: w] <= controllerodata;
            ovalid[0] <= controllerovalid;

            for (i = 0; i < x; i = i + 1)
            begin
                if (i == g)
                begin
                    if (nodeodata[w*i +: w] != {w{1'b1}})
                    begin
                        fifoidata[w*i +: w] <= nodeodata[w*i +: w];
                        fifoivalid[i] <= nodeovalid[i];
                    end
                    else
                    begin
                        fifoidata[w*i +: w] <= 0;
                        fifoivalid[i] <= 0;
                    end
                end
                else if (i > g)
                begin
                    odata[w*i +: w] <= nodeodata[w*i +: w];
                    ovalid[i] <= nodeovalid[i];

                    fifoidata[w*i +: w] <= idata[w*i +: w];
                    fifoivalid[i] <= ivalid[i];
                end
                else if (i < g)
                begin
                    odata[w*(i+1) +: w] <= nodeodata[w*i +: w];
                    ovalid[(i+1)] <= nodeovalid[i];

                    fifoidata[w*i +: w] <= idata[w*(i+1) +: w];
                    fifoivalid[i] <= ivalid[(i+1)];
                end
            end

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

Node #(x,J,L,g,j,l,w,d) Node
(
    .clock(clock),
    .reset(nodereset),
    .ivalid(fifoovalid),
    .idata(fifoodata),
    .ovalid(nodeovalid),
    .odata(nodeodata),
    .controllerivalid(controllerivalid),
    .controlleridata(controlleridata),
    .controllerovalid(controllerovalid),
    .controllerodata(controllerodata)
);

genvar v;
   
generate
    for (v = 0; v < x; v = v + 1)
    begin
        FIFO #(w,8) FIFO
        (
            .clock(clock),
            .reset(reset),
            .idata(fifoidata[w*v +: w]),
            .ivalid(fifoivalid[v]),
            .odata(fifoodata[w*v +: w]),
            .ovalid(fifoovalid[v]),
            .empty(fifoempty[v]),
            .oready(fifooready[v])
        );
    end
endgenerate


endmodule