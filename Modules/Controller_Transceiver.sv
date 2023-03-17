`timescale 1ns / 1ps

module Controller_Transceiver #(parameter x = 3, parameter w = 128, parameter d = 5)
(
    input logic clock,
    input logic [0:x-1] tx_clock,
    input logic [0:x-1] rx_clock,
    input logic [0:x-1] tx_reset,
    output logic [0:w*x-1] tx_data,
    input logic [0:w*x-1] rx_data,
    output logic [0:6*x-1] tx_header,
    output logic [0:x-1] rx_slip,
    input logic activate
);

logic [0:w*x-1] idata;
logic [0:x-1] ivalid;
logic [0:w*x-1] odata;
logic [0:x-1] ovalid;

logic [0:w*x-1] out_fifo_data;
logic [0:x-1] out_fifo_valid;

logic [0:w*x-1] in_fifo_data;
logic [0:x-1] in_fifo_valid;

logic [0:w*x-1] rx_data_aligned;
logic [0:x-1] aligned;

logic m_axis_tready;
assign m_axis_tready = 1;

Controller_Wrapper #(x,w,d) Controller_Wrapper
(
    .clock(clock),
    .reset(activate),
    .aligned(aligned),
    .idata(idata),
    .ivalid(ivalid),
    .odata(odata),
    .ovalid(ovalid)
);

genvar g;
   
generate
    for (g = 0; g < x; g = g + 1)
    begin
        Keep_Alive_Out #(w) Keep_Alive_Out
        (
            .clock(tx_clock[g]),
            .reset(tx_reset[g]),
            .idata(out_fifo_data[w*g +: w]),
            .ivalid(out_fifo_valid[g]),
            .odata(tx_data[w*g +: w]),
            .oheader(tx_header[6*g +: 6])
        );
    end
endgenerate

generate
    for (g = 0; g < x; g = g + 1)
    begin
        Align #(w) Align
        (
            .clock(rx_clock[g]),
            .reset(activate),
            .idata(rx_data[w*g +: w]),
            .aligned(aligned[g]),
            .odata(rx_data_aligned[w*g +: w]),
            .oslip(rx_slip[g])
        );
    end
endgenerate

generate
    for (g = 0; g < x; g = g + 1)
    begin
        Data_In #(w) Data_In
        (
            .clock(rx_clock[g]),
            .reset(activate),
            .idata(rx_data_aligned[w*g +: w]),
            .odata(in_fifo_data[w*g +: w]),
            .ovalid(in_fifo_valid[g])
        );
    end
endgenerate

generate
    for (g = 0; g < x; g = g + 1)
    begin
        axis_data_fifo_0 out_FIFO
        (
            .s_axis_aclk(clock),
            .s_axis_aresetn(activate),
            .s_axis_tdata(odata[w*g +: w]),
            .s_axis_tvalid(ovalid[g]),
            .m_axis_aclk(tx_clock[g]),
            .m_axis_tdata(out_fifo_data[w*g +: w]),
            .m_axis_tready(m_axis_tready),
            .m_axis_tvalid(out_fifo_valid[g])
        );
    end
endgenerate

generate
    for (g = 0; g < x; g = g + 1)
    begin
        axis_data_fifo_0 in_FIFO
        (
            .s_axis_aclk(rx_clock[g]),
            .s_axis_aresetn(activate),
            .s_axis_tdata(in_fifo_data[w*g +: w]),
            .s_axis_tvalid(in_fifo_valid[g]),
            .m_axis_aclk(clock),
            .m_axis_tdata(idata[w*g +: w]),
            .m_axis_tready(m_axis_tready),
            .m_axis_tvalid(ivalid[g])
        );
    end
endgenerate


endmodule