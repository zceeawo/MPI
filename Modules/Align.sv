`timescale 1ns / 1ps

module Align #(parameter w = 128)
(
    input logic clock,
    input logic reset,
    input logic [0:w-1] idata,
    output logic aligned,
    output logic [0:w-1] odata,
    output logic oslip
);

logic [0:5] state;
logic [0:1] count;
logic mode;
logic [0:127] data_buffer;

always_ff @(posedge clock)
begin
    if (reset == 0)
    begin
        state <= 0;
        oslip <= 0;
        count <= 0;
        data_buffer <= 0;
        aligned <= 0;
        mode <= 0;
        odata <= 0;
    end
    else
    begin
        if (aligned == 0)
        begin
            if (state == 0)
            begin
                if ((idata == {w/4{4'h5}} && data_buffer == {w/4{4'ha}}) || (idata == {w/4{4'ha}} && data_buffer == {w/4{4'h5}}))
                begin
                    aligned <= 1;
                end
                else if ((idata[0:w/2-1] == {w/8{4'h5}} && idata[w/2:w-1] == {w/8{4'ha}} && data_buffer[0:w/2-1] == {w/8{4'ha}} && data_buffer[w/2:w-1] == {w/8{4'h5}}) || (idata[0:w/2-1] == {w/8{4'ha}} && idata[w/2:w-1] == {w/8{4'h5}} && data_buffer[0:w/2-1] == {w/8{4'h5}} && data_buffer[w/2:w-1] == {w/8{4'ha}}))
                begin
                    aligned <= 1;
                    mode <= 1;
                end
                else
                begin
                    if (count == 3)
                    begin
                        oslip <= 1;
                        count <= 0;
                        state <= 1;
                    end
                    else
                    begin
                        count <= count + 1;
                    end
                end
            end
            else
            begin
                if (state == 31)
                begin
                    state <= 0;
                end
                else
                begin
                    state <= state + 1;
                end 
                oslip <= 0;
            end
            data_buffer <= idata;
        end
        else if (aligned == 1)
        begin
            if (mode == 0)
            begin
                odata <= idata;
            end
            else if (mode == 1)
            begin
                odata[0:w/2-1] <= data_buffer[w/2:w-1];
                odata[w/2:w-1] <= idata[0:w/2-1];
                data_buffer <= idata;
            end
        end
    end
end

endmodule