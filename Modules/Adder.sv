`timescale 1ns / 1ps

module adder #(parameter i = 4) // i number of inputs
(
    input logic clock,

    input logic [16*i-1:0] idata,
    input logic [i-1:0] ivalid,

    output logic [15:0] odata, 
    output logic ovalid
);

function int Base2Roundup (input int number);
    int power = 1;
    while(power < number)
    begin
        power = power*2;
    end
    return power;
endfunction

parameter p = Base2Roundup(i);

function int log2 (input int number);
    int k = 0;
    while(2**k < number)
    begin
        k = k + 1;
    end
    return k;
endfunction

parameter L = log2(p); // Number of layers

function int numberOfBlocks (input int number);
    int count;
    number = number % 2 == 0 ? number/2 : (number/2) + 1;
    count = number;
    while(number != 1)
    begin
        number = number % 2 == 0 ? number/2 : (number/2) + 1;
        count = count + number;
    end
    return count;
endfunction

parameter A = numberOfBlocks(i);

logic avalid [0:A-1];
logic [15:0] a_in [0:A-1];

logic bvalid [0:A-1];
logic [15:0] b_in [0:A-1];

logic rvalid [0:A-1];
logic [15:0] result_out [0:A-1];
    
int j;
logic odd;
int Acount;
int icount;
int ocount;
int layerInputs;

always_ff @(posedge clock)
begin
    Acount = 0;
    icount = 0;
    ocount = 0;
    layerInputs = i;

    while (Acount < A)
    begin
        odd = layerInputs % 2 == 0 ? 0 : 1;

        for (j = 0; j < layerInputs; j = j + 1)
        begin
            if (icount < i)
            begin
                if (icount % 2 == 0)    
                begin
                    a_in[Acount] <= idata[((16*(i-icount))-1) -: 16];
                    avalid[Acount] <= ivalid[i-icount-1];
                end
                else
                begin
                    b_in[Acount] <= idata[((16*(i-icount))-1) -: 16];
                    bvalid[Acount] <= ivalid[i-icount-1];
                    Acount = Acount + 1;
                end
                icount = icount + 1;
            end
            else
            begin
                if (ocount % 2 == 0)
                begin
                    a_in[Acount] <= result_out[ocount];
                    avalid[Acount] <= rvalid[ocount];
                end
                else
                begin
                    b_in[Acount] <= result_out[ocount];
                    bvalid[Acount] <= rvalid[ocount];
                    Acount = Acount + 1;
                end
                ocount = ocount + 1;
            end
        end

        if (odd == 1'b1)
        begin
            b_in[Acount] <=  0;
            bvalid[Acount] <= 1;
            Acount = Acount + 1;
            icount = icount + 1;
        end
        layerInputs = layerInputs % 2 == 0 ? layerInputs/2 : (layerInputs/2) + 1;
    end
    odata <= result_out[ocount];
    ovalid <= rvalid[ocount];
end

genvar g;

generate
    for (g = 0; g < A; g = g + 1)
    begin
        floating_point_0 adders
        (
            .aclk(clock),
            .s_axis_a_tvalid(avalid[g]),
            .s_axis_a_tdata(a_in[g]),
            .s_axis_b_tvalid(bvalid[g]),
            .s_axis_b_tdata(b_in[g]),
            .m_axis_result_tvalid(rvalid[g]),
            .m_axis_result_tdata(result_out[g])
        );
    end
endgenerate

endmodule
