`timescale 1ns / 1ps

module MIGwrapper
    (
    input logic clk_p,
    input logic clk_n,
    input logic sys_rst,
    output logic resetLED,

    output logic act_n,
    output logic [16:0] adr,
    output logic [1:0] ba,
    output logic bg,
    output logic ck_c,
    output logic ck_t,
    output logic cke,
    output logic cs_n,
    inout wire [7:0] dm_dbi_n,
    inout wire [63:0] dq,
    inout wire [7:0] dqs_c,
    inout wire [7:0] dqs_t,
    output logic odt,
    output logic reset_n
    );

    parameter n = 4; // Number of inputs
    parameter p = 8; // Number of parallel calculations

    logic writevalid;
    logic writeready;
    logic [31:0] writeaddress;
    logic [15:0] writemessagesize;

    logic readvalid;
    logic readready;
    logic [15:0] readmessagesize;
    logic [31:0] readaddress;

    logic aresetn;

    logic wvalid;
    logic [511:0] wdata;

    logic rvalid;
    logic [511:0] rdata;
    
    logic ui_clk;

    logic [(n-1):0] inputSelect;
    logic [2:0] opSelect;

    logic [((16*p*n)-1):0] idata;
    logic ivalid;
    logic iready;
    logic istart;
    logic ilast;

    logic [(16*p-1):0] odata;
    logic ovalid;
    logic oready;
    logic ostart;
    logic olast;

    logic [(16*p-1):0] sepdata;
    logic sepvalid;
    logic sepstart;
    logic seplast;
    logic sepreset;

    parameter K = 1024;

    logic [(16*p-1):0] Cdata [0:((K/p)-1)];
    logic [(16*p-1):0] Ddata [0:((K/p)-1)];
    logic [(16*p-1):0] Edata [0:((K/p)-1)];
    logic [(16*p-1):0] Fdata [0:((K/p)-1)];
    logic [511:0] Rdata [0:(((K/32)*6)-1)];

    logic [3:0] state;
    logic [9:0] count;
    logic [9:0] count2;
    logic [9:0] count3;
    logic [511:0] compare;
    logic [1:0] flag;
    

    always_ff @(posedge ui_clk)
    begin
    
        if (aresetn == 0)
        begin
            state <= 0;
            count <= 0;
            flag <= 0;
        
            writevalid <= 0;
            writeaddress <= 0;
            writemessagesize <= 0;
            readvalid <= 0;
            readaddress <= 0;
            readmessagesize <= 0;

            idata <= 0;
            ivalid <= 0;
            istart <= 0;
            ilast <= 0;

            count2 <= 0;
            count3 <= 0;
            compare <= 0;
            $readmemb("R.mem", Rdata);

            inputSelect <= 4'b1111;
            opSelect <= 3'b111;

            sepreset <= 0;

            $readmemb("C.mem", Cdata);
            $readmemb("D.mem", Ddata);
            $readmemb("E.mem", Edata);
            $readmemb("F.mem", Fdata);
        end

        else
        begin
            if (state == 0)
            begin
                sepreset <= 1;
                if (writeready == 1)
                begin
                    idata[(16*p-1):0] <= Cdata[count];
                    ivalid <= 1;
                    istart <= 1;
                    count <= count + 1;
                    writevalid <= 1;
                    writemessagesize <= K;
                    writeaddress <= 0;
                    state <= 1;
                end
            end
            else if (state == 1)
            begin
                istart <= 0;
                writevalid <= 0;
                idata <= Cdata[count];
                count <= count + 1;
                if (count == ((K/p)-1))
                begin
                    ilast <= 1;
                    state <= 2;
                end
            end
            else if (state == 2)
            begin
                sepreset <= 1;
                idata <= 0;
                ivalid <= 0;
                ilast <= 0;
                count <= 0;
                state <= 3;
            end
            else if (state == 3)
            begin
                count <= count + 1;
                if (readready == 1 && count > 20)
                begin
                    readvalid <= 1;
                    readmessagesize <= K;
                    readaddress <= 0;
                    state <= 4;
                end
            end
            else if (state == 4)
            begin
                count <= 0;
                readvalid <= 0;
                compare <= Rdata[count2];
                opSelect <= opSelect + 1'b1;
                state <= 5;
            end
            if (state == 5)
            begin
                ivalid <= sepvalid;
                if (sepvalid == 1)
                begin
                    istart <= sepstart;
                    idata[(4*16*p-1):(3*16*p)] <= sepdata;
                    idata[(3*16*p-1):(2*16*p)] <= Ddata[count];
                    idata[(2*16*p-1):(16*p)] <= Edata[count];
                    idata[(16*p-1):0] <= Fdata[count];
                    ilast <= seplast;
                    writeaddress <= ((K/256)*(32'h00000200)+32'h00000200);
                    writemessagesize <= K;
                    count <= count + 1;
                    if (sepstart == 1)
                    begin
                        writevalid <= 1;
                    end
                    else
                    begin
                        writevalid <= 0;
                        if (seplast == 1)
                        begin
                            state <= 6;
                        end
                    end
                end
            end
            else if (state == 6)
            begin
                istart <= 0;
                ivalid <= 0;
                idata <= 0;
                ilast <= 0;
                count <= 0;
                state <= 7;
            end
            else if (state == 7)
            begin
                count <= count + 1;
                if (readready == 1 && count > 50)
                begin
                    readvalid <= 1;
                    readmessagesize <= K;
                    readaddress <= ((K/256)*(32'h00000200)+32'h00000200);
                    state <= 8;
                end
            end
            else if (state == 8)
            begin
                count <= 0;
                readvalid <= 0;
                state <= 9;
            end
            else if (state == 9)
            begin
                if (rvalid == 1)
                begin
                    count2 <= count2 + 1;
                    compare <= Rdata[count2+1];
                    if (rdata == compare)
                    begin
                        count3 <= count3 + 1;
                    end
                end
                if (count2 == ((1*(K/32))-1) || count2 == ((2*(K/32))-1) || count2 == ((3*(K/32))-1) || count2 == ((4*(K/32))-1) || count2 == ((5*(K/32))-1))
                begin
                    flag <= 2'b01;
                end 
                else if (count2 == ((6*(K/32))-1))
                begin
                    flag <= 2'b11;
                end
                if (flag == 2'b01 & rvalid == 0)
                begin
                    state <= 10;
                end
                else if (flag == 2'b11 & rvalid == 0)
                begin
                    state <= 11;
                end
            end
            else if (state == 10)
            begin
                count <= 10'b0;
                flag <= 2'b0;
                sepreset <= 0;
                state <= 2;
            end
            else if (state == 11)
            begin
                count <= 10'b0;
                flag <= 2'b0;
                sepreset <= 0;
            end
        end
    end

    ila_0 ila
    (
        .clk(ui_clk),
        .probe0(rdata),
        .probe1(wdata),
        .probe2(rvalid),
        .probe3(wvalid),
        .probe4(idata),
        .probe5(ivalid),
        .probe6(istart),
        .probe7(ilast),
        .probe8(state),
        .probe9(opSelect),
        .probe10(count2),
        .probe11(count3),
        .probe12(odata),
        .probe13(ovalid),
        .probe14(ostart),
        .probe15(olast),
        .probe16(compare),
        .probe17(readvalid),
        .probe18(count)
    );

    MIG #(p) MIG
    (
        .clk_n(clk_n),
        .clk_p(clk_p),
        .aresetn(aresetn),
        .sys_rst(sys_rst),
        .resetLED(resetLED),
        .start(ostart),
        .last(olast),
        .valid(ovalid),
        .data(odata),
        .writevalid(writevalid),
        .writeready(writeready),
        .readvalid(readvalid),
        .readready(readready),
        .writeaddress(writeaddress),
        .writemessagesize(writemessagesize),
        .readaddress(readaddress),
        .readmessagesize(readmessagesize),
        .rdata(rdata),
        .rvalid(rvalid),
        .wdata(wdata),
        .wvalid(wvalid),
        .ui_clk(ui_clk),
        .act_n(act_n),
        .adr(adr),
        .ba(ba),
        .bg(bg),
        .ck_c(ck_c),
        .ck_t(ck_t),
        .cke(cke),
        .cs_n(cs_n),
        .dm_dbi_n(dm_dbi_n),
        .dq(dq),
        .dqs_c(dqs_c),
        .dqs_t(dqs_t),
        .odt(odt),
        .reset_n(reset_n)
    );

    operations #(n,p) operations
    (
        .aclk(ui_clk),
        .inputSelect(inputSelect),
        .opSelect(opSelect),
        .idata(idata),
        .ivalid(ivalid),
        .iready(iready),
        .istart(istart),
        .ilast(ilast),
        .odata(odata),
        .ovalid(ovalid),
        .oready(writeready),
        .ostart(ostart),
        .olast(olast)
    );

    separator #(p) separator
    (
        .ui_clk(ui_clk),
        .aresetn(sepreset),
        .messagesize(readmessagesize),
        .msvalid(readvalid),
        .rdata(rdata),
        .rvalid(rvalid),
        .odata(sepdata),
        .ovalid(sepvalid),
        .ostart(sepstart),
        .olast(seplast)
    );

endmodule