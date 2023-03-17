`timescale 1ns / 1ps

module Controller #(parameter x = 3, parameter w = 128, parameter d = 5)
(
    input logic clock,
    input logic reset,
    input logic [0:w*x-1] idata,
    input logic [0:x-1] ivalid,
    output logic [0:w*x-1] odata,
    output logic [0:x-1] ovalid
);

logic [0:2] state;

int i;

parameter m = x*w*(2**d)/8; // MESSAGE SIZE IN BYTES

always_ff @(posedge clock)
begin
    if (reset == 0)
    begin
        odata <= 0;
        ovalid <= 0;
        state <= 0;
    end
    else
    begin
        if (state == 0)
        begin
            if (ivalid == {x{1'b1}})
            begin
                for (i = 0; i < x; i = i + 1)
                begin
                    odata[w*i +: w] <= 0;
                    ovalid[i] <= 1;
                end
                state <= 1;
            end
        end
        else if (state == 1)
        begin
            for (i = 0; i < x; i = i + 1)
            begin
                odata[w*i +: w] <= m;
                ovalid[i] <= 1;
            end
            state <= 2;
        end
        else if (state == 2)
        begin
            odata <= 0;
            ovalid <= 0;
            state <= 3;
        end
        else if (state == 3)
        begin
            if (ivalid == {x{1'b1}})
            begin
                state <= 4;
            end
        end
        else if (state == 4)
        begin
            for (i = 0; i < x; i = i + 1)
            begin
                odata[w*i +: w] <= 1;
                ovalid[i] <= 1;
            end
            state <= 5;
        end
        else if (state == 5)
        begin
            for (i = 0; i < x; i = i + 1)
            begin
                odata[w*i +: w] <= m;
                ovalid[i] <= 1;
            end
            state <= 6;
        end
        else if (state == 6)
        begin
            odata <= 0;
            ovalid <= 0;
        end
    end
end

endmodule