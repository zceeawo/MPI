`timescale 1ns / 1ps

module divider #(parameter n = 4)
    (
        input logic aclk,
        input logic [(n-1):0] inputSelect,

        input logic [15:0] idata,
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

    logic avalid;
    logic aready;

    logic bvalid;
    logic bready;

    logic rvalid;
    logic rready;
    logic [15:0] result_out;

    logic fixedvalid;
    logic fixedready;
    logic [7:0] fixed_in;

    logic floatvalid;
    logic floatready;
    logic [15:0] float_out;

    assign avalid = 1'b1;
    assign bvalid= 1'b1;
    assign rready = 1'b1;
    assign fixedvalid= 1'b1;
    assign floatready = 1'b1;

    int i;

    always_ff @(inputSelect)
    begin
        fixed_in = 8'b0;
        for (i = 0; i < n; i = i + 1)
        begin
            if (inputSelect[n-1-i] == 1)
            begin
                fixed_in = fixed_in + 8'b1;
            end
        end
    end
    
    int b;
    parameter Delay = 15;
    logic Register [0:Delay][0:2];

    always_ff @(posedge aclk)
    begin
        iready <= oready;
        odata <= result_out;
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
    
    genvar g;
   
    floating_point_4 divider
    (
        .aclk(aclk),
        .s_axis_a_tvalid(avalid),
        .s_axis_a_tready(aready),
        .s_axis_a_tdata(idata),
        .s_axis_b_tvalid(bvalid),
        .s_axis_b_tready(bready),
        .s_axis_b_tdata(float_out),
        .m_axis_result_tvalid(rvalid),
        .m_axis_result_tready(rready),
        .m_axis_result_tdata(result_out)
    );

    floating_point_5 fixedtofloat
    (
        .aclk(aclk),
        .s_axis_a_tvalid(fixedvalid),
        .s_axis_a_tready(fixedready),
        .s_axis_a_tdata(fixed_in),
        .m_axis_result_tvalid(floatvalid),
        .m_axis_result_tready(floatready),
        .m_axis_result_tdata(float_out)
    );

endmodule
