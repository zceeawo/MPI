`timescale 1ns / 1ps

module Node #(parameter x = 4, parameter J = 1, parameter L = 1, parameter g = 0, parameter j = 0, parameter l = 0, parameter w = 128, parameter d = 5)
(
    input logic clock,
    input logic reset,

    input logic [0:x-1] ivalid,
    input logic [0:w*x-1] idata,

    output logic [0:x-1] ovalid,
    output logic [0:w*x-1] odata,

    input logic controllerivalid, 
    input logic [0:w-1] controlleridata,

    output logic controllerovalid,
    output logic [0:w-1] controllerodata
);

logic [0:31] operation;
logic [0:31] messagesize; // IN BYTES
logic [0:2] state;
int count;

logic [0:1] readstate;
int portion;

logic [0:1] writestate;
int writecount;

logic [0:w*x-1] adderidata;
logic [0:w/16*x-1] adderivalid;

logic [0:w-1] adderodata;
logic [0:w/16-1] adderovalid;

logic [0:w-1] dividata;
logic [0:w/16-1] divivalid;

logic fixedvalid;
logic [0:7] fixed_in;

logic floatvalid;
logic [0:15] float_out;

logic [0:w-1] divodata;
logic [0:w/16-1] divovalid;

logic [0:1] reducestate;
int reducecount;

int a;
int b;
int c;

int subgroup[x];
int informationportion[x];

int i;
int k;

logic [0:d*x-1] writeAddress;
logic [0:w*x-1] writeData;
logic [0:x-1] writeEnable;

logic [0:d*x-1] readAddress;
logic [0:w*x-1] readData;
logic [0:x-1] readEnable;
logic [0:x-1] readValid;

parameter BDD = 2**d;

logic [0:w-1] memory [0:x*x*BDD-1];

int r;

always_ff @(posedge clock)
begin
    if (reset == 0)
    begin
        $readmemh("Memory.mem", memory);
        writeAddress <= 0;
        writeData <= 0;
        writeEnable <= 0;
        readAddress <= 0;
        readEnable <= 0;

        operation = 0;
        messagesize <= 0; 
        count <= 0;
        portion <= 0;
        writecount <= 0;
        reducecount <= 0;

        controllerodata <= 0;
        controllerovalid <= 0;

        ovalid <= 0;
        odata <= 0;
        adderidata <= 0;
        adderivalid <= 0;
        dividata <= 0;
        divivalid <= 0;
        fixed_in <= x;
        fixedvalid <= 1;
        readstate <= 0;
        writestate <= 0;
        reducestate <= 0;
        state <= 0;
    end
    else
    begin
        if (state == 0) // RESET
        begin
            if (count == BDD)
            begin
                for (r = 0; r < x; r = r + 1)
                begin
                    writeAddress[r*d +: d] <= 0;
                    writeData[r*w +: w] <= 0;
                    writeEnable[r] <= 0;
                end
                count <= 0;
                state <= 1;
            end
            else
            begin
                for (r = 0; r < x; r = r + 1)
                begin
                    writeAddress[r*d +: d] <= count;
                    writeData[r*w +: w] <= memory[count + r*BDD + g*x*BDD];
                    writeEnable[r] <= 1;
                end
                count <= count + 1;
            end
        end
        else if (state == 1)
        begin
            if (l + L*j == c + L*b)
            begin
                subgroup[count] <= a*J*L + b*L + c;
                informationportion[count] <= ((a - c - b - (c/x)*b) % x + x) % x;
                if (count + 1 == x)
                begin
                    count <= 0;
                end
                else
                begin
                    count <= count + 1;
                end
            end
            if (c == L-1)
            begin
                c <= 0;
                if (b == J-1)
                begin
                    b <= 0;
                    if (a == x-1)
                    begin
                        a <= 0;
                        portion = ((g - l - j - (l/x)*j) % x + x) % x;
                        state <= 2;
                    end
                    else
                    begin
                        a <= a + 1;
                    end
                end
                else
                begin
                    b <= b + 1;
                end
            end
            else
            begin
                c <= c + 1;
            end
        end
        else if (state == 2)
        begin
            controllerovalid <= 1;
            controllerodata <= 0;
            state <= 3;
        end
        else if (state == 3)
        begin
            controllerovalid <= 0;
            controllerodata <= 0;
            if (controllerivalid == 1)
            begin
                operation <= controlleridata;
                state <= 4;
            end
        end
        else if (state == 4)
        begin
            if (controllerivalid == 1)
            begin
                messagesize <= controlleridata;
                readstate <= 1;
                reducestate <= 1;
                writestate <= 1;
                state <= 5;
            end
        end
        else if (state == 5)
        begin
            if (operation == 0)
            begin
                if (count == 8*messagesize/(x*w))
                begin
                    readAddress <= 0;
                    count <= 0;
                    state <= 6;
                end
                else
                begin
                    for (i = 0; i < x; i++)
                    begin
                        readAddress[i*d +: d] <= count;
                        readEnable[i] <= 1;
                    end
                    count <= count + 1;
                end
            end
            else if (operation == 1)
            begin
                if (count == 8*messagesize/(x*w))
                begin
                    readAddress <= 0;
                    count <= 0;
                    state <= 6;
                end
                else
                begin
                    for (i = 0; i < x; i++)
                    begin
                        if (i == portion)
                        begin
                            readAddress[i*d +: d] <= count;
                            readEnable[i] <= 1;
                        end
                        else
                        begin
                            readAddress[i*d +: d] <= 0;
                            readEnable[i] <= 0;
                        end
                    end
                    count <= count + 1;
                end
            end
        end
        else if (state == 6)
        begin
            readEnable <= 0;
        end

        if (readstate == 0)
        begin
        end
        else if (readstate == 1)
        begin
            if (operation == 0)
            begin
                if (readValid == {x{1'b1}})
                begin
                    for (i = 0; i < x; i++)
                    begin
                        odata[subgroup[i]*w +: w] <= readData[i*w +: w];
                        ovalid[subgroup[i]] <= readValid[i];
                    end
                end
                else
                begin
                    odata <= 0;
                    ovalid <= 0;
                end
            end
            else if (operation == 1)
            begin
                if (readValid[portion] == 1)
                begin
                    for (i = 0; i < x; i++)
                    begin
                        odata[subgroup[i]*w +: w] <= readData[portion*w +: w];
                        ovalid[subgroup[i]] <= readValid[portion];
                    end
                end
                else
                begin
                    odata <= 0;
                    ovalid <= 0;
                end
            end
        end

        if (reducestate == 0)
        begin
        end
        else if (reducestate == 1)
        begin
            if (operation == 0)
            begin
                if (ivalid == {x{1'b1}})
                begin
                    for (i = 0; i < w/16; i++)
                    begin
                        for (k = 0; k < x; k++)
                        begin
                            adderidata[16*k + x*i*16 +: 16] <= idata[16*i + k*w +: 16];
                            adderivalid[i*x + k] <= 1;
                        end
                    end
                end
                else
                begin
                    adderidata <= 0;
                    adderivalid <= 0;
                end
                if (adderovalid == {w/16{1'b1}})
                begin
                    dividata <= adderodata;
                    divivalid <= adderovalid;
                end
                else
                begin
                    dividata <= 0;
                    divivalid <= 0;
                end
            end
        end

        if (writestate == 0)
        begin
        end
        else if (writestate == 1)
        begin
            if (writecount == 8*messagesize/(x*w))
            begin
                writecount <= 0;
                writeAddress <= 0;
                writeEnable <= 0;
                writeData <= 0;
                readstate <= 0;
                writestate <= 0;
                reducestate <= 0;
                
                state <= 2;
            end
            else
            begin
                if (operation == 0)
                begin
                    if (divovalid == {w/16{1'b1}})
                    begin
                        writeAddress[portion*d +: d] <= writecount;
                        writeEnable[portion] <= 1;
                        writeData[portion*w +: w] <= divodata;
                        writecount <= writecount + 1;
                    end
                    else
                    begin
                        writeAddress <= 0;
                        writeEnable <= 0;
                    end
                end
                else if (operation == 1)
                begin
                    if (ivalid == {x{1'b1}})
                    begin
                        for (i = 0; i < x; i++)
                        begin
                            if (i != portion)
                            begin
                                writeAddress[i*d +: d] <= writecount;
                                writeEnable[i] <= 1;
                                writeData[i*w +: w] <= idata[subgroup[i]*w +: w];
                            end
                        end
                        writecount <= writecount + 1;
                    end
                    else
                    begin
                        writeAddress <= 0;
                        writeEnable <= 0;
                    end
                end
            end
        end
    end   
end

genvar v;
   
generate
    for (v = 0; v < w/16; v = v + 1)
    begin
        adder #(x) adder
        (
            .clock(clock),
            .idata(adderidata[16*x*v +: 16*x]),
            .ivalid(adderivalid[x*v +: x]),
            .odata(adderodata[16*v +: 16]),
            .ovalid(adderovalid[v])
        );
    end
endgenerate

generate
    for (v = 0; v < w/16; v = v + 1)
    begin
        floating_point_1 divider
        (
            .aclk(clock),
            .s_axis_a_tdata(dividata[16*v +: 16]),
            .s_axis_a_tvalid(divivalid[v]),
            .s_axis_b_tdata(float_out),
            .s_axis_b_tvalid(floatvalid),
            .m_axis_result_tdata(divodata[16*v +: 16]),
            .m_axis_result_tvalid(divovalid[v])
        );
    end
endgenerate


floating_point_2 fixedtofloat
(
    .aclk(clock),
    .s_axis_a_tvalid(fixedvalid),
    .s_axis_a_tdata(fixed_in),
    .m_axis_result_tvalid(floatvalid),
    .m_axis_result_tdata(float_out)
);

generate
    for (v = 0; v < x; v = v + 1)
    begin
        blk_mem_gen_0 BRAM
        (
            .addra(writeAddress[v*d +: d]),
            .clka(clock),
            .dina(writeData[v*w +: w]),
            .ena(writeEnable[v]),
            .wea(writeEnable[v]),

            .addrb(readAddress[v*d +: d]),
            .clkb(clock),
            .doutb(readData[v*w +: w]),
            .enb(readEnable[v])
        );
    end
endgenerate

generate
    for (v = 0; v < x; v = v + 1)
    begin
        Delay Delay
        (
            .clock(clock),
            .reset(reset),
            .readEnable(readEnable[v]),
            .readValid(readValid[v])
        );
    end
endgenerate

endmodule
