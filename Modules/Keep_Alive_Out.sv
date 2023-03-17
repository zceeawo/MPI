`timescale 1ns / 1ps

module Keep_Alive_Out #(parameter w = 128)
(
    input logic clock,
    input logic reset,
    input logic [0:w-1] idata,
    input logic ivalid,
    output logic [0:w-1] odata,
    output logic [0:5] oheader
);

logic [0:1] state;
logic [0:w-1] databuffer;

logic flip;
assign oheader = 6'b001001;

always_ff @(posedge clock)
begin
    if (reset == 0)
    begin
        odata <= 0;
        flip <= 0;
        databuffer <= 0;
        state <= 0;
    end
    else
    begin
        if (ivalid == 1)
        begin
            if (state == 0)
            begin
                odata <= {w{1'b1}};
                databuffer <= idata;
                state <= 2;
            end
            else if (state == 2)
            begin
                odata <= databuffer;
                databuffer <= idata;
            end
            flip <= 0;
        end
        else
        begin
            if (state == 2)
            begin
                odata <= databuffer;
                databuffer <= {w{1'b1}};
                state <= 1;
            end
            else if (state == 1)
            begin
                odata <= databuffer;
                state <= 0;
            end
            else
            begin
                if (flip == 0)
                begin
                    flip <= 1;
                    for (int i = 0; i < w; i++)
                    begin
                        if (i % 2 == 0)
                        begin
                            odata[i] <= 0;
                        end
                        else
                        begin
                            odata[i] <= 1;
                        end
                    end
                end
                else
                begin
                    odata <= ~odata;
                    flip <= 0;
                end
            end
        end
    end
end

endmodule