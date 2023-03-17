`timescale 1ns / 1ps

module Delay
(
    input logic clock,
    input logic reset,

    input logic readEnable,
    output logic readValid
);

logic state;

always_ff @(posedge clock)
begin
    if (reset == 0)
    begin
        readValid <= 0;
        state <= 0;
    end
    else
    begin
        if (state == 0)
        begin
            if (readEnable == 1)
            begin
                state <= 1;
            end
            readValid <= 0;
        end
        else if (state == 1)
        begin
            if (readEnable == 0)
            begin
                state <= 0;
            end
            readValid <= readEnable;
        end
    end
end

endmodule