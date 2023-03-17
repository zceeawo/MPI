`timescale 1ns / 1ps

module logicalAND #(parameter n = 4)
    (
        input logic aclk,
        input logic [(n-1):0] inputSelect,

        input logic [(16*n)-1:0] idata,
        input logic ivalid,
        output logic iready,
        input logic istart,
        input logic ilast,

        output logic [15:0] odata, // Output
        output logic ovalid,
        input logic oready,
        output logic ostart,
        output logic olast
    );

    function int Base2Roundup (input int number);
        int power = 1;
        while(power < number)
        begin
            power = power*2;
        end
        return power;
    endfunction

    parameter p = Base2Roundup(n);

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

    parameter A = numberOfBlocks(n);

    logic avalid [0:A-1];
    logic aready [0:A-1];
    logic [15:0] a_in [0:A-1];

    logic bvalid [0:A-1];
    logic bready [0:A-1];
    logic [15:0] b_in [0:A-1];

    logic rvalid [0:A-1];
    logic rready [0:A-1];
    logic [15:0] result_out [0:A-1];

    genvar j;

    for (j = 0; j < A; j = j + 1)
    begin
        assign avalid[j] = 1'b1;
        assign bvalid[j] = 1'b1;
        assign rready[j] = 1'b1;
    end;
        
    int i;
    logic odd;
    int Acount;
    int Rcount;
    int rcount;
    int layerInputs;
      
    int a;

    always_ff @(posedge aclk)
    begin
        iready <= oready;
        Acount = 0;
        Rcount = 0;
        rcount = 0;
        layerInputs = n;

        while (Acount < A)
        begin
            odd = layerInputs % 2 == 0 ? 1'b0 : 1'b1;

            for (i = 0; i < layerInputs; i = i + 1)
            begin
                if (Rcount < n)
                begin
                    if (Rcount % 2 == 0)    
                    begin
                        a_in[Acount] <= inputSelect[n-1-Rcount] == 1 ? idata[((16*(n-Rcount))-1) -: 16] : 16'hFFFF;
                    end
                    else
                    begin
                        b_in[Acount] <= inputSelect[n-1-Rcount] == 1 ? idata[((16*(n-Rcount))-1) -: 16] : 16'hFFFF;
                        Acount = Acount + 1;
                    end
                end
                else
                begin
                    if (Rcount % 2 == 0)
                    begin
                        a_in[Acount] <= result_out[rcount];
                    end
                    else
                    begin
                        b_in[Acount] <= result_out[rcount];
                        Acount = Acount + 1;
                    end
                    rcount = rcount + 1;
                end
                Rcount = Rcount + 1;
            end

            if (odd == 1'b1)
            begin
                b_in[Acount] <=  16'hFFFF;
                Acount = Acount + 1;
                Rcount = Rcount + 1;
            end
            layerInputs = layerInputs % 2 == 0 ? layerInputs/2 : (layerInputs/2) + 1;
        end

        for (i = 0; i < A; i = i + 1)
        begin
            result_out[i] = a_in[i] & b_in[i];
        end

        odata <= result_out[rcount];
    end

    int b;
    parameter Delay2 = 1;
    parameter Delay = L*Delay2; // Delay
    logic Register [0:Delay][0:2];

    always_ff @(posedge aclk)
    begin
        ovalid <= Register[Delay][0];
        ostart <= Register[Delay][1];
        olast <= Register[Delay][2];
        for (b = Delay; b > 0; b = b - 1)
        begin
            Register[b] <= Register[b-1];
        end
        Register[0][0] <= ivalid;
        Register[0][1] <= istart;
        Register[0][2] <= ilast;
    end

endmodule
