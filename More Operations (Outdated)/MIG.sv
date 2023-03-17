`timescale 1ns / 1ps

module MIG #(parameter p = 1)
    (
    input logic clk_p,
    input logic clk_n,
    input logic sys_rst,
    output logic resetLED,

    input logic start,
    input logic valid,
    input logic last,
    input logic [((16*p)-1):0] data,
    input logic writevalid,
    output logic writeready,
    input logic [31:0] writeaddress,
    input logic [15:0] writemessagesize,

    input logic readvalid,
    output logic readready,
    input logic [31:0] readaddress,
    input logic [15:0] readmessagesize,

    output logic aresetn,
    
    output logic wvalid,
    output logic [511:0] wdata,

    output logic rvalid,
    output logic [511:0] rdata,

    input logic [3:0] datacount,

    output logic ui_clk,

    output logic act_n,
    output logic [16:0] adr,
    output logic [1:0] ba,
    output logic bg,
    output logic ck_c,
    output logic ck_t,
    output logic cke,
    output logic cs_n,
    output wire [7:0] dm_dbi_n,
    output wire [63:0] dq,
    output wire [7:0] dqs_c,
    output wire [7:0] dqs_t,
    output logic odt,
    output logic reset_n
    );

    logic [2:0] datastate;
    logic [3:0] writestate;
    logic [3:0] readstate;

    logic [5:0] resetcount;
    logic [2:0] writecount;

    logic [511:0] tempdata;
    logic [511:0] dataarray [0:7];
    logic [63:0] tempstrobe;
    logic [63:0] strobearray [0:7];

    logic [4:0] bitcount;
    logic [2:0] burstcount;

    logic [15:0] numbercount;
    logic [15:0] tempwritemessagesize;
    logic [15:0] readcount;
    logic [15:0] tempreadmessagesize;

    logic fifosvalid;
    logic fifomready;
    logic [511:0] datafifoout;
    logic [63:0] strobefifoout;
    logic [3:0] fifocount;

    logic awvalid;
    logic awready;
    logic [3:0] awid;
    logic [31:0] awaddr;
    logic [2:0] awsize;
    logic [7:0] awlen;
    logic [1:0] awburst;
    
    logic wready;
    logic [63:0] wstrb;
    logic wlast;

    logic bvalid;
    logic bready;
    logic [3:0] bid;
    logic [1:0] bresp;

    logic arvalid;
    logic arready;
    logic [3:0] arid;
    logic [31:0] araddr;
    logic [2:0] arsize;
    logic [7:0] arlen;
    logic [1:0] arburst;
    
    logic rready;
    logic [3:0] rid;
    logic rlast;
    logic [1:0] rresp;

    assign resetLED = sys_rst;

    logic ui_clk_sync_rst;
    logic calib_complete;

    logic dbg_clk;
    logic [511:0] dbg_bus;

    logic [3:0] awcache;
    logic [0:0] awlock;
    logic [2:0] awprot;
    logic [3:0] awqos;

    logic [3:0] arcache;
    logic [0:0] arlock;
    logic [2:0] arprot;
    logic [3:0] arqos;

    assign awcache = 0;
    assign awlock = 0;
    assign awprot = 0;
    assign awqos = 0;

    assign arcache = 0;
    assign arlock = 0;
    assign arprot = 0;
    assign arqos = 0;
    
    assign awsize = 3'b110; // 64 bytes in transfer
    assign awlen = 8'd7; // Burst length = 8
    assign awburst = 1; // Incrementing burst

    assign arsize = 3'b110;
    assign arlen = 8'd7;
    assign arburst = 1;

    always_ff @(posedge ui_clk)
    begin

        if (sys_rst == 1)
        begin
            resetcount <= 6'b0;
        end
        else
        begin
            if (resetcount == 63)
            begin
                aresetn <= 1; 
            end
            else
            begin
                aresetn <= 0;
                resetcount <= resetcount + 1;
            end
        end

        if (aresetn == 0)
        begin
            datastate <= 0;
            writestate <= 0;
            readstate <= 0;
            writecount <= 0;
            tempdata <= 0;
            tempstrobe <= 0;
            bitcount <= 0;
            burstcount <= 0;
            numbercount <= 0;
            tempwritemessagesize <= 0;
            readcount <= 0;
            tempreadmessagesize <= 0;
            fifosvalid <= 0;

            writeready <= 0;
            readready <= 0;
            bready <= 1;
            rready <= 1;

            awvalid <= 0;
            awid <= 0;
            awaddr <= 0;

            wstrb <= 0;
            wvalid <= 0;
            wdata <= 0;
            wlast <= 0;

            arvalid <= 0;
            arid <= 0;
            araddr <= 0;
        end

        else
        begin
            if (datastate == 0)
            begin
                bitcount <= 0;
                burstcount <= 0;
                fifosvalid <= 0;
                if (wready == 1 && awready == 1)
                begin
                    writeready <= 1;
                    datastate <= 1;
                end
            end
            else if (datastate == 1)
            begin
                if (valid == 1 && start == 1)
                begin
                    tempdata[511-(16*p)*bitcount -: (16*p)] <= data;
                    tempstrobe[63-(2*p)*bitcount -: (2*p)] <= {(2*p){1'b1}};
                    bitcount <= bitcount + 1;
                    datastate <= 2;
                end
            end
            else if (datastate == 2)
            begin
                if (valid == 1)
                begin
                    tempdata[511-(16*p)*bitcount -: (16*p)] <= data;
                    tempstrobe[63-(2*p)*bitcount -: (2*p)] <= {(2*p){1'b1}};
                    if (bitcount == 32/p - 1)
                    begin
                        fifosvalid <= 1;
                        bitcount <= 0;
                    end
                    else
                    begin
                        fifosvalid <= 0;
                        bitcount <= bitcount + 1;
                    end
                    if (bitcount == 0)
                    begin
                        burstcount <= burstcount + 1;
                    end
                    if (last == 1)
                    begin
                        if (bitcount == 32/p - 1 && burstcount == 3'b111)
                        begin
                            datastate <= 0;
                        end
                        else
                        begin
                            datastate <= 3;
                        end
                    end
                end
                else
                begin
                    fifosvalid <= 0;
                end
            end
            if (datastate == 3)
            begin
                tempdata[511-(16*p)*bitcount -: (16*p)] <= 0;
                tempstrobe[63-(2*p)*bitcount -: (2*p)] <= 0;
                if (bitcount == 32/p - 1)
                begin
                    fifosvalid <= 1;
                    if (burstcount == 3'b111)
                    begin
                        datastate <= 0;
                    end
                    bitcount <= 0;
                end
                else
                begin
                    fifosvalid <= 0;
                    bitcount <= bitcount + 1;
                end
                if (bitcount == 0)
                begin
                    burstcount <= burstcount + 1;
                end
            end

            if (writestate == 0)
            begin
                if (writevalid == 1)
                begin
                    tempwritemessagesize <= writemessagesize;
                    awaddr <= writeaddress;
                    writestate <= 1;
                end
            end
            if (writestate == 1)
            begin
                if (fifocount >= 8)
                begin
                    fifomready <= 1;
                    writestate <= 2;
                end
            end
            if (writestate == 2)
            begin
                writestate <= 3;
            end
            if (writestate == 3)
            begin
                dataarray[writecount] <= datafifoout;
                strobearray[writecount] <= strobefifoout;
                writecount <= writecount + 1;
                if (writecount == 6)
                begin
                    fifomready <= 0;
                end
                else if (writecount == 7)
                begin
                    writestate <= 4;
                end
            end
            if (writestate == 4)
            begin
                if (wready == 1)
                begin
                    if (writecount == 0 && awready == 1)
                    begin
                        awvalid <= 1;
                        wvalid <= 1;
                        wdata <= dataarray[writecount];
                        wstrb <= strobearray[writecount];
                    end
                    else if (writecount == 1)
                    begin
                        awvalid <= 0;
                        wdata <= dataarray[writecount];
                        wstrb <= strobearray[writecount];
                    end
                    else if (writecount == 7)
                    begin
                        wlast <= 1;
                        wdata <= dataarray[writecount];
                        wstrb <= strobearray[writecount];
                        numbercount <= numbercount + 256;
                        writestate <= 5;
                    end
                    else
                    begin
                        wdata <= dataarray[writecount];
                        wstrb <= strobearray[writecount];
                    end
                    writecount <= writecount + 1;
                end 
            end
            if (writestate == 5)
            begin
                wvalid <= 0;
                wlast <= 0;
                if (numbercount >= tempwritemessagesize - 1)
                begin
                    writestate <= 0;
                    numbercount <= 0;
                end
                else
                begin
                    awid <= awid + 1;
                    awaddr <= awaddr + 32'd512;
                    writestate <= 1;
                end;
            end

            if (readstate == 0)
            begin
                if (arready == 1)
                begin
                    readready <= 1;
                    readstate <= 1;
                end
            end
            else if (readstate == 1)
            begin
                if (readvalid == 1)
                begin
                    araddr <= readaddress;
                    tempreadmessagesize <= readmessagesize;
                    readready <= 0;
                    readstate <= 2;
                end
            end
            else if (readstate == 2)
            begin
                if (arready == 1 && datacount < 8)
                begin
                    arvalid <= 1;
                    readstate <= 3;
                end
            end
            else if (readstate == 3)
            begin
                if (arready == 1)
                begin
                    arvalid <= 0;
                    arid <= arid + 1;
                    readcount <= readcount + 256;
                    readstate <= 4;
                end
            end
            else if (readstate == 4)
            begin
                if (rlast == 1 && rvalid == 1)
                begin
                    if (readcount >= tempreadmessagesize - 1)
                    begin
                        readcount <= 0;
                        arid <= 0;
                        araddr <= 0;
                        readstate <= 0;
                    end
                    else
                    begin
                        araddr <= araddr + 512;
                        readstate <= 2;
                    end
                end
            end
        end
    end

    ila_2 ila2
    (
        .clk(ui_clk),
        .probe0(start),
        .probe1(last),
        .probe2(data), //128
        .probe3(writevalid),
        .probe4(writeready),
        .probe5(writeaddress), //32
        .probe6(writemessagesize), //16
        .probe7(readvalid),
        .probe8(readready),
        .probe9(readaddress), //32
        .probe10(readmessagesize), //16
        .probe11(wvalid),
        .probe12(wdata), //512
        .probe13(rvalid),
        .probe14(rdata), //512
        .probe15(datastate), //3
        .probe16(writestate), //4
        .probe17(readstate), //4
        .probe18(resetcount), //6
        .probe19(writecount), //3
        .probe20(tempdata), //512
        .probe21(tempstrobe), //64
        .probe22(bitcount), //5
        .probe23(burstcount), //3
        .probe24(numbercount), //16
        .probe25(tempwritemessagesize), //16
        .probe26(readcount), //16
        .probe27(tempreadmessagesize), //16
        .probe28(fifosvalid),
        .probe29(datafifoout), //512
        .probe30(fifomready),
        .probe31(strobefifoout), //64
        .probe32(valid),
        .probe33(awvalid),
        .probe34(awready),
        .probe35(awid), //4
        .probe36(awaddr), //32
        .probe37(wready),
        .probe38(wstrb), //64
        .probe39(wlast),
        .probe40(bvalid),
        .probe41(fifocount), //4
        .probe42(bid), //4
        .probe43(arvalid),
        .probe44(arready),
        .probe45(arid), //4
        .probe46(araddr), //32
        .probe47(rready),
        .probe48(rid), //4
        .probe49(rlast)
    );

    ddr4_0 ddr4
    (
        .c0_ddr4_act_n(act_n),
        .c0_ddr4_adr(adr),
        .c0_ddr4_aresetn(aresetn),
        .c0_ddr4_ba(ba),
        .c0_ddr4_bg(bg),
        .c0_ddr4_ck_c(ck_c),
        .c0_ddr4_ck_t(ck_t),
        .c0_ddr4_cke(cke),
        .c0_ddr4_cs_n(cs_n),
        .c0_ddr4_dm_dbi_n(dm_dbi_n),
        .c0_ddr4_dq(dq),
        .c0_ddr4_dqs_c(dqs_c),
        .c0_ddr4_dqs_t(dqs_t),
        .c0_ddr4_odt(odt),
        .c0_ddr4_reset_n(reset_n),
        .c0_ddr4_s_axi_araddr(araddr),
        .c0_ddr4_s_axi_arburst(arburst),
        .c0_ddr4_s_axi_arid(arid),
        .c0_ddr4_s_axi_arlen(arlen),
        .c0_ddr4_s_axi_arready(arready),
        .c0_ddr4_s_axi_arsize(arsize),
        .c0_ddr4_s_axi_arvalid(arvalid),
        .c0_ddr4_s_axi_arcache(arcache),
        .c0_ddr4_s_axi_arlock(arlock),
        .c0_ddr4_s_axi_arprot(arprot),
        .c0_ddr4_s_axi_arqos(arqos),
        .c0_ddr4_s_axi_awcache(awcache),
        .c0_ddr4_s_axi_awlock(awlock),
        .c0_ddr4_s_axi_awprot(awprot),
        .c0_ddr4_s_axi_awqos(awqos),
        .c0_ddr4_s_axi_awaddr(awaddr),
        .c0_ddr4_s_axi_awburst(awburst),
        .c0_ddr4_s_axi_awid(awid),
        .c0_ddr4_s_axi_awlen(awlen),
        .c0_ddr4_s_axi_awready(awready),
        .c0_ddr4_s_axi_awsize(awsize),
        .c0_ddr4_s_axi_awvalid(awvalid),
        .c0_ddr4_s_axi_bid(bid),
        .c0_ddr4_s_axi_bready(bready),
        .c0_ddr4_s_axi_bresp(bresp),
        .c0_ddr4_s_axi_bvalid(bvalid),
        .c0_ddr4_s_axi_rdata(rdata),
        .c0_ddr4_s_axi_rid(rid),
        .c0_ddr4_s_axi_rlast(rlast),
        .c0_ddr4_s_axi_rready(rready),
        .c0_ddr4_s_axi_rresp(rresp),
        .c0_ddr4_s_axi_rvalid(rvalid),
        .c0_ddr4_s_axi_wdata(wdata),
        .c0_ddr4_s_axi_wlast(wlast),
        .c0_ddr4_s_axi_wready(wready),
        .c0_ddr4_s_axi_wstrb(wstrb),
        .c0_ddr4_s_axi_wvalid(wvalid),
        .c0_ddr4_ui_clk(ui_clk),
        .c0_ddr4_ui_clk_sync_rst(ui_clk_sync_rst),
        .c0_init_calib_complete(calib_complete),
        .c0_sys_clk_p(clk_p),
        .c0_sys_clk_n(clk_n),
        .sys_rst(sys_rst),
        .dbg_clk(dbg_clk),
        .dbg_bus(dbg_bus)
    );

    FIFO #(512) datafifo
    (
        .clock(ui_clk),
        .reset(aresetn),
        .idata(tempdata),
        .ivalid(fifosvalid),
        .odata(datafifoout),
        .oready(fifomready),
        .count(fifocount)
    );

    FIFO #(64) strobefifo
    (
        .clock(ui_clk),
        .reset(aresetn),
        .idata(tempstrobe),
        .ivalid(fifosvalid),
        .odata(strobefifoout),
        .oready(fifomready)
    );
   

endmodule