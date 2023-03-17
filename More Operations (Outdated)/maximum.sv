`timescale 1ns / 1ps

module maximum #(parameter n = 4)
    (
        input logic aclk,
        input logic [(n-1):0] inputSelect,

        input logic [(16*n)-1:0] idata,
        input logic ivalid,
        output logic iready,
        input logic istart,
        input logic ilast,

        output logic [15:0] odata,
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
    logic [7:0] result_out [0:A-1];

    genvar j;

    for (j = 0; j < A; j = j + 1)
    begin
        assign avalid[j] = 1'b1;
        assign bvalid[j] = 1'b1;
        assign rready[j] = 1'b1;
    end;

    int b;
    int c;
    parameter Delay = 3;
    parameter TotalDelay = L*(Delay + 1) - 1; // TotalDelay
    logic Register [0:TotalDelay][0:2];
    logic [2*A:0][Delay:0][15:0] dataReg;
       
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
        ovalid <= Register[TotalDelay][0];
        ostart <= Register[TotalDelay][1];
        olast <= Register[TotalDelay][2];
        for (b = TotalDelay; b > 0; b = b - 1)
        begin
            Register[b] <= Register[b-1];
        end
        for (b = Delay; b > 0; b = b - 1)
        begin
            Register[b] <= Register[b-1];
            for (c = 0; c < 2*A; c = c + 1)
            begin
                dataReg[c][b] <= dataReg[c][b-1];
            end
        end
        Register[0][0] <= ivalid;
        Register[0][1] <= istart;
        Register[0][2] <= ilast;

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
                        a_in[Acount] <= inputSelect[n-1-Rcount] == 1 ? idata[((16*(n-Rcount))-1) -: 16] : 16'hFC00;
                        dataReg[Rcount][0] <= inputSelect[n-1-Rcount] == 1 ? idata[((16*(n-Rcount))-1) -: 16] : 16'hFC00;
                    end
                    else
                    begin
                        b_in[Acount] <= inputSelect[n-1-Rcount] == 1 ? idata[((16*(n-Rcount))-1) -: 16] : 16'hFC00;
                        dataReg[Rcount][0] <= inputSelect[n-1-Rcount] == 1 ? idata[((16*(n-Rcount))-1) -: 16] : 16'hFC00;
                        Acount = Acount + 1;
                    end
                end
                else
                begin
                    if (Rcount % 2 == 0)
                    begin
                        a_in[Acount] <= result_out[rcount] == 1 ? dataReg[2*rcount][Delay] : dataReg[2*rcount+1][Delay];
                        dataReg[rcount+n][0] <= result_out[rcount] == 1 ? dataReg[2*rcount][Delay] : dataReg[2*rcount+1][Delay];
                    end
                    else
                    begin
                        b_in[Acount] <= result_out[rcount] == 1 ? dataReg[2*rcount][Delay] : dataReg[2*rcount+1][Delay];
                        dataReg[rcount+n][0] <= result_out[rcount] == 1 ? dataReg[2*rcount][Delay] : dataReg[2*rcount+1][Delay];
                        Acount = Acount + 1;
                    end
                    rcount = rcount + 1;
                end
                Rcount = Rcount + 1;
            end

            if (odd == 1'b1)
            begin
                b_in[Acount] <=  16'hFC00;
                dataReg[Rcount][0] <= 16'hFC00;
                Acount = Acount + 1;
                Rcount = Rcount + 1;
            end
            layerInputs = layerInputs % 2 == 0 ? layerInputs/2 : (layerInputs/2) + 1;
        end
        odata <= result_out[rcount] == 1 ? dataReg[2*rcount][Delay] : dataReg[2*rcount+1][Delay];
    end
    
    genvar g;
   
    generate
        for (g = 0; g < A; g = g + 1)
        begin
            floating_point_3 maximum
            (
                .aclk(aclk),
                .s_axis_a_tvalid(avalid[g]),
                .s_axis_a_tready(aready[g]),
                .s_axis_a_tdata(a_in[g]),
                .s_axis_b_tvalid(bvalid[g]),
                .s_axis_b_tready(bready[g]),
                .s_axis_b_tdata(b_in[g]),
                .m_axis_result_tvalid(rvalid[g]),
                .m_axis_result_tready(rready[g]),
                .m_axis_result_tdata(result_out[g])
            );
        end
    endgenerate

endmodule
