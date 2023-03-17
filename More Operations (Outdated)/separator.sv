`timescale 1ns / 1ps

module separator #(parameter p = 1)
    (
        input logic ui_clk,
        input logic aresetn,

        input logic [15:0] messagesize,
        input logic msvalid,

        input logic [511:0] rdata,
        input logic rvalid,

        output logic [((16*p)-1):0] odata,
        output logic ovalid,
        output logic ostart,
        output logic olast
    );

    logic [511:0] data;
    logic [15:0] messagesize2;

    logic sready;
    logic [511:0] mdata;
    logic mready;
    logic mvalid;

    logic sready2;
    logic [15:0] mdata2;
    logic mready2;
    logic mvalid2;

    logic [4:0] bitcount;
    logic [15:0] numbercount;
    logic [1:0] state;  

    always_ff @(posedge ui_clk)
    begin
        if (aresetn == 0)
        begin
            data <= 0;
            messagesize2 <= 0;
            mready <= 0;
            mready2 <= 0;
            bitcount <= 0;
            numbercount <= 0;
            state <= 0;
        end
        else
        begin
            if (state == 0)
            begin
                odata <= 0;
                olast <= 0;
                ovalid <= 0;
                bitcount <= 0;
                numbercount <= 0;
                if (mvalid2 == 1)
                begin
                    mready2 <= 1;
                    state <= 1;
                end
            end
            if (state == 1)
            begin
                mready2 <= 0;
                messagesize2 <= mdata2;
                mready <= 1;
                state <= 2;
            end
            else if (state == 2)
            begin
                if (mvalid == 1)
                begin
                    mready <= 0;
                    data <= mdata;
                    odata <= mdata[511-(16*p)*bitcount -: (16*p)];
                    if (numbercount == 0)
                    begin
                        ostart <= 1;
                    end
                    ovalid <= 1;
                    bitcount <= bitcount + 1;
                    numbercount <= numbercount + p;
                    if (numbercount == messagesize2 - p)
                    begin
                        olast <= 1;
                        state <= 0;
                    end
                    else
                    begin
                        state <= 3;
                    end
                end
                else
                begin
                    ovalid <= 0;
                end
            end
            else if (state == 3)
            begin
                ostart <= 0;
                odata <= data[511-(16*p)*bitcount -: (16*p)];
                numbercount <= numbercount + p;
                if (numbercount == messagesize2 - p)
                begin
                    olast <= 1;
                    state <= 0;
                end
                else if (bitcount == 32/p - 1)
                begin
                    mready <= 1;
                    bitcount <= 0;
                    state <= 2;
                end
                else
                begin
                    bitcount <= bitcount + 1;
                end
            end
        end
    end

    axis_data_fifo_0 datafifo
    (
        .s_axis_aclk(ui_clk),
        .s_axis_aresetn(aresetn),
        .s_axis_tdata(rdata),
        .s_axis_tready(sready),
        .s_axis_tvalid(rvalid),
        .m_axis_tdata(mdata),
        .m_axis_tready(mready),
        .m_axis_tvalid(mvalid)
    );

    axis_data_fifo_1 msfifo
    (
        .s_axis_aclk(ui_clk),
        .s_axis_aresetn(aresetn),
        .s_axis_tdata(messagesize),
        .s_axis_tready(sready2),
        .s_axis_tvalid(msvalid),
        .m_axis_tdata(mdata2),
        .m_axis_tready(mready2),
        .m_axis_tvalid(mvalid2)
    );

    ila_1 ila1
    (
        .clk(ui_clk),
        .probe0(messagesize),
        .probe1(msvalid),
        .probe2(rdata),
        .probe3(rvalid),
        .probe4(odata),
        .probe5(ovalid),
        .probe6(ostart),
        .probe7(olast),
        .probe8(data),
        .probe9(messagesize2),
        .probe10(sready),
        .probe11(mdata),
        .probe12(mready),
        .probe13(mvalid),
        .probe14(sready2),
        .probe15(mdata2),
        .probe16(mready2),
        .probe17(mvalid2),
        .probe18(bitcount),
        .probe19(numbercount),
        .probe20(state)
    );


endmodule