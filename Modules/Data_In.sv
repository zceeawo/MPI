`timescale 1ns / 1ps

module Data_In #(parameter w = 128)
(
    input logic clock,
    input logic reset,
    input logic [0:w-1] idata,
    output logic [0:w-1] odata,
    output logic ovalid
);

logic flip;

always_ff @(posedge clock)
begin
    if (reset == 0)
    begin
        odata <= 0;
        ovalid <= 0;
        flip <= 0;
    end
    else
    begin
        if (flip == 0)
        begin
            if (idata[0:w/4-1] == {w/16{4'hf}} || idata[w/4:w/2-1] == {w/16{4'hf}} || idata[w/2:3*w/4-1] == {w/16{4'hf}} || idata[3*w/4:w-1] == {w/16{4'hf}})
            begin
                flip <= 1;
            end
        end
        else if (flip == 1)
        begin
            if (idata[0:w/4-1] == {w/16{4'hf}} || idata[w/4:w/2-1] == {w/16{4'hf}} || idata[w/2:3*w/4-1] == {w/16{4'hf}} || idata[3*w/4:w-1] == {w/16{4'hf}})
            begin
                odata <= 0;
                ovalid <= 0;
                flip <= 0;
            end
            else
            begin
                odata <= idata;
                ovalid <= 1;
            end
        end
    end
end

endmodule