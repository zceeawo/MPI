`timescale 1ns / 1ps

module Node_Transceiver #(parameter x = 3, parameter J = 1, parameter L = 1, parameter g = 0, parameter j = 0, parameter l = 0, parameter w = 128, parameter d = 5)
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
logic [0:x-1] oready;

logic [0:w*x-1] out_fifo_data;
logic [0:x-1] out_fifo_valid;

logic [0:w*x-1] in_fifo_data;
logic [0:x-1] in_fifo_valid;
logic [0:x-1] in_fifo_ready;

logic [0:w*x-1] rx_data_aligned;
logic [0:x-1] aligned;

logic m_axis_tready;
assign m_axis_tready = 1;

logic reset;

always_ff @(posedge clock)
begin
    if (activate == 0)
    begin
        reset <= 0;
    end
    else
    begin
        if (oready == {x{1'b1}} && in_fifo_ready == {x{1'b1}})
        begin
            reset <= 1;
        end
    end
end

Node_Wrapper #(x,J,L,g,j,l,w,d) Node_Wrapper
(
    .clock(clock),
    .reset(reset),
    .aligned(aligned),
    .idata(idata),
    .ivalid(ivalid),
    .odata(odata),
    .ovalid(ovalid)
);

genvar v;
   
generate
    for (v = 0; v < x; v = v + 1)
    begin
        Keep_Alive_Out #(w) Keep_Alive_Out
        (
            .clock(tx_clock[v]),
            .reset(tx_reset[v]),
            .idata(out_fifo_data[w*v +: w]),
            .ivalid(out_fifo_valid[v]),
            .odata(tx_data[w*v +: w]),
            .oheader(tx_header[6*v +: 6])
        );
    end
endgenerate

generate
    for (v = 0; v < x; v = v + 1)
    begin
        Align #(w) Align
        (
            .clock(rx_clock[v]),
            .reset(activate),
            .idata(rx_data[w*v +: w]),
            .aligned(aligned[v]),
            .odata(rx_data_aligned[w*v +: w]),
            .oslip(rx_slip[v])
        );
    end
endgenerate

generate
    for (v = 0; v < x; v = v + 1)
    begin
        Data_In #(w) Data_In
        (
            .clock(rx_clock[v]),
            .reset(activate),
            .idata(rx_data_aligned[w*v +: w]),
            .odata(in_fifo_data[w*v +: w]),
            .ovalid(in_fifo_valid[v])
        );
    end
endgenerate

generate
    for (v = 0; v < x; v = v + 1)
    begin
        axis_data_fifo_0 out_FIFO
        (
            .s_axis_aclk(clock),
            .s_axis_aresetn(activate),
            .s_axis_tdata(odata[w*v +: w]),
            .s_axis_tvalid(ovalid[v]),
            .s_axis_tready(oready[v]),
            .m_axis_aclk(tx_clock[v]),
            .m_axis_tdata(out_fifo_data[w*v +: w]),
            .m_axis_tready(m_axis_tready),
            .m_axis_tvalid(out_fifo_valid[v])
        );
    end
endgenerate

generate
    for (v = 0; v < x; v = v + 1)
    begin
        axis_data_fifo_0 in_FIFO
        (
            .s_axis_aclk(rx_clock[v]),
            .s_axis_aresetn(activate),
            .s_axis_tdata(in_fifo_data[w*v +: w]),
            .s_axis_tvalid(in_fifo_valid[v]),
            .s_axis_tready(in_fifo_ready[v]),
            .m_axis_aclk(clock),
            .m_axis_tdata(idata[w*v +: w]),
            .m_axis_tready(m_axis_tready),
            .m_axis_tvalid(ivalid[v])
        );
    end
endgenerate


endmodule