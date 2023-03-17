module operations #(parameter n = 4, parameter p = 1)
    (
        input logic aclk,
        input logic [(n-1):0] inputSelect,
        input logic [2:0] opSelect,

        input logic [((16*p*n)-1):0] idata,
        input logic ivalid,
        output logic iready,
        input logic istart,
        input logic ilast,

        output logic [((16*p)-1):0] odata, // Output
        output logic ovalid,
        input logic oready,
        output logic ostart,
        output logic olast
    );

    logic [(16*n)-1:0] adderidata [0:(p-1)];
    logic adderivalid [0:(p-1)];
    logic adderiready [0:(p-1)];
    logic adderistart [0:(p-1)];
    logic adderilast [0:(p-1)];

    logic [15:0] adderodata [0:(p-1)];
    logic adderovalid [0:(p-1)];
    logic adderoready [0:(p-1)];
    logic adderostart [0:(p-1)];
    logic adderolast [0:(p-1)];

    logic [(16*n)-1:0] multiplieridata [0:(p-1)];
    logic multiplierivalid [0:(p-1)];
    logic multiplieriready [0:(p-1)];
    logic multiplieristart [0:(p-1)];
    logic multiplierilast [0:(p-1)];

    logic [15:0] multiplierodata [0:(p-1)];
    logic multiplierovalid [0:(p-1)];
    logic multiplieroready [0:(p-1)];
    logic multiplierostart [0:(p-1)];
    logic multiplierolast [0:(p-1)];

    logic [(16*n)-1:0] minimumidata [0:(p-1)];
    logic minimumivalid [0:(p-1)];
    logic minimumiready [0:(p-1)];
    logic minimumistart [0:(p-1)];
    logic minimumilast [0:(p-1)];

    logic [15:0] minimumodata [0:(p-1)];
    logic minimumovalid [0:(p-1)];
    logic minimumoready [0:(p-1)];
    logic minimumostart [0:(p-1)];
    logic minimumolast [0:(p-1)];

    logic [(16*n)-1:0] maximumidata [0:(p-1)];
    logic maximumivalid [0:(p-1)];
    logic maximumiready [0:(p-1)];
    logic maximumistart [0:(p-1)];
    logic maximumilast [0:(p-1)];

    logic [15:0] maximumodata [0:(p-1)];
    logic maximumovalid [0:(p-1)];
    logic maximumoready [0:(p-1)];
    logic maximumostart [0:(p-1)];
    logic maximumolast [0:(p-1)];

    logic [15:0] divideridata [0:(p-1)];
    logic dividerivalid [0:(p-1)];
    logic divideriready [0:(p-1)];
    logic divideristart [0:(p-1)];
    logic dividerilast [0:(p-1)];

    logic [15:0] dividerodata [0:(p-1)];
    logic dividerovalid [0:(p-1)];
    logic divideroready [0:(p-1)];
    logic dividerostart [0:(p-1)];
    logic dividerolast [0:(p-1)];

    logic [(16*n)-1:0] andidata [0:(p-1)];
    logic andivalid [0:(p-1)];
    logic andiready [0:(p-1)];
    logic andistart [0:(p-1)];
    logic andilast [0:(p-1)];

    logic [15:0] andodata [0:(p-1)];
    logic andovalid [0:(p-1)];
    logic andoready [0:(p-1)];
    logic andostart [0:(p-1)];
    logic andolast [0:(p-1)];

    int i;
    int j;

    always_ff @(posedge aclk)
    begin
        if (opSelect == 3'b000)
        begin
            for (i = 0; i < p; i = i + 1)
            begin
                for (j = 0; j < n; j = j + 1)
                begin
                    adderidata[i][((16*n)-1)-16*j -: 16] <= idata[((16*p*n)-1)-16*i-(16*p)*j -: 16];
                end
                odata[((16*p)-1)-16*i -: 16] <= adderodata[i];
            end
            adderivalid[0] <= ivalid;
            iready <= adderiready[0];
            adderistart[0] <= istart;
            adderilast[0] <= ilast;

            ovalid <= adderovalid[0];
            adderoready[0] <= oready;
            ostart <= adderostart[0];
            olast <= adderolast[0];
        end
        if (opSelect == 3'b001)
        begin
            for (i = 0; i < p; i = i + 1)
            begin
                for (j = 0; j < n; j = j + 1)
                begin
                    multiplieridata[i][((16*n)-1)-16*j -: 16] <= idata[((16*p*n)-1)-16*i-(16*p)*j -: 16];
                end
                odata[((16*p)-1)-16*i -: 16] <= multiplierodata[i];
            end
            multiplierivalid[0] <= ivalid;
            iready <= multiplieriready[0];
            multiplieristart[0] <= istart;
            multiplierilast[0] <= ilast;

            ovalid <= multiplierovalid[0];
            multiplieroready[0] <= oready;
            ostart <= multiplierostart[0];
            olast <= multiplierolast[0];
        end
        if (opSelect == 3'b010)
        begin
            for (i = 0; i < p; i = i + 1)
            begin
                for (j = 0; j < n; j = j + 1)
                begin
                    minimumidata[i][((16*n)-1)-16*j -: 16] <= idata[((16*p*n)-1)-16*i-(16*p)*j -: 16];
                end
                odata[((16*p)-1)-16*i -: 16] <= minimumodata[i];
            end
            minimumivalid[0] <= ivalid;
            iready <= minimumiready[0];
            minimumistart[0] <= istart;
            minimumilast[0] <= ilast;

            ovalid <= minimumovalid[0];
            minimumoready[0] <= oready;
            ostart <= minimumostart[0];
            olast <= minimumolast[0];
        end
        if (opSelect == 3'b011)
        begin
            for (i = 0; i < p; i = i + 1)
            begin
                for (j = 0; j < n; j = j + 1)
                begin
                    maximumidata[i][((16*n)-1)-16*j -: 16] <= idata[((16*p*n)-1)-16*i-(16*p)*j -: 16];
                end
                odata[((16*p)-1)-16*i -: 16] <= maximumodata[i];
            end
            maximumivalid[0] <= ivalid;
            iready <= maximumiready[0];
            maximumistart[0] <= istart;
            maximumilast[0] <= ilast;

            ovalid <= maximumovalid[0];
            maximumoready[0] <= oready;
            ostart <= maximumostart[0];
            olast <= maximumolast[0];
        end
        if (opSelect == 3'b100)
        begin
            for (i = 0; i < p; i = i + 1)
            begin
                for (j = 0; j < n; j = j + 1)
                begin
                    adderidata[i][((16*n)-1)-16*j -: 16] <= idata[((16*p*n)-1)-16*i-(16*p)*j -: 16];
                end
                divideridata[i] <= adderodata[i];
                odata[((16*p)-1)-16*i -: 16] <= dividerodata[i];
            end
            adderivalid[0] <= ivalid;
            iready <= adderiready[0];
            adderistart[0] <= istart;
            adderilast[0] <= ilast;

            dividerivalid[0] <= adderovalid[0];
            adderoready[0] <= divideriready[0];
            divideristart[0] <= adderostart[0];
            dividerilast[0] <= adderolast[0];

            ovalid <= dividerovalid[0];
            divideroready[0] <= oready;
            ostart <= dividerostart[0];
            olast <= dividerolast[0];
        end
        if (opSelect == 3'b101)
        begin
            for (i = 0; i < p; i = i + 1)
            begin
                for (j = 0; j < n; j = j + 1)
                begin
                    andidata[i][((16*n)-1)-16*j -: 16] <= idata[((16*p*n)-1)-16*i-(16*p)*j -: 16];
                end
                odata[((16*p)-1)-16*i -: 16] <= andodata[i];
            end
            andivalid[0] <= ivalid;
            iready <= andiready[0];
            andistart[0] <= istart;
            andilast[0] <= ilast;

            ovalid <= andovalid[0];
            andoready[0] <= oready;
            ostart <= andostart[0];
            olast <= andolast[0];
        end
        if (opSelect == 3'b111)
        begin
            odata <= idata[(16*p):0] ;
            ovalid <= ivalid;
            iready <= oready;
            ostart <= istart;
            olast <= ilast;
        end
    end

    genvar g;

    generate
        for (g = 0; g < p; g = g + 1)
        begin
            adder #(n) adder
            (
                .aclk(aclk),
                .inputSelect(inputSelect),
                .idata(adderidata[g]),
                .ivalid(adderivalid[g]),
                .iready(adderiready[g]),
                .istart(adderistart[g]),
                .ilast(adderilast[g]),
                .odata(adderodata[g]),
                .ovalid(adderovalid[g]),
                .oready(adderoready[g]),
                .ostart(adderostart[g]),
                .olast(adderolast[g])
            );
        end
    endgenerate

    generate
        for (g = 0; g < p; g = g + 1)
        begin
            multiplier #(n) multiplier
            (
                .aclk(aclk),
                .inputSelect(inputSelect),
                .idata(multiplieridata[g]),
                .ivalid(multiplierivalid[g]),
                .iready(multiplieriready[g]),
                .istart(multiplieristart[g]),
                .ilast(multiplierilast[g]),
                .odata(multiplierodata[g]),
                .ovalid(multiplierovalid[g]),
                .oready(multiplieroready[g]),
                .ostart(multiplierostart[g]),
                .olast(multiplierolast[g])
            );
        end
    endgenerate

    generate
        for (g = 0; g < p; g = g + 1)
        begin
            minimum #(n) minimum
            (
                .aclk(aclk),
                .inputSelect(inputSelect),
                .idata(minimumidata[g]),
                .ivalid(minimumivalid[g]),
                .iready(minimumiready[g]),
                .istart(minimumistart[g]),
                .ilast(minimumilast[g]),
                .odata(minimumodata[g]),
                .ovalid(minimumovalid[g]),
                .oready(minimumoready[g]),
                .ostart(minimumostart[g]),
                .olast(minimumolast[g])
            );
        end
    endgenerate

    generate
        for (g = 0; g < p; g = g + 1)
        begin
            maximum #(n) maximum
            (
                .aclk(aclk),
                .inputSelect(inputSelect),
                .idata(maximumidata[g]),
                .ivalid(maximumivalid[g]),
                .iready(maximumiready[g]),
                .istart(maximumistart[g]),
                .ilast(maximumilast[g]),
                .odata(maximumodata[g]),
                .ovalid(maximumovalid[g]),
                .oready(maximumoready[g]),
                .ostart(maximumostart[g]),
                .olast(maximumolast[g])
            );
        end
    endgenerate

    generate
        for (g = 0; g < p; g = g + 1)
        begin
            divider #(n) divider
            (
                .aclk(aclk),
                .inputSelect(inputSelect),
                .idata(divideridata[g]),
                .ivalid(dividerivalid[g]),
                .iready(divideriready[g]),
                .istart(divideristart[g]),
                .ilast(dividerilast[g]),
                .odata(dividerodata[g]),
                .ovalid(dividerovalid[g]),
                .oready(divideroready[g]),
                .ostart(dividerostart[g]),
                .olast(dividerolast[g])
            );
        end
    endgenerate

    generate
        for (g = 0; g < p; g = g + 1)
        begin
            logicalAND #(n) logicalAND
            (
                .aclk(aclk),
                .inputSelect(inputSelect),
                .idata(andidata[g]),
                .ivalid(andivalid[g]),
                .iready(andiready[g]),
                .istart(andistart[g]),
                .ilast(andilast[g]),
                .odata(andodata[g]),
                .ovalid(andovalid[g]),
                .oready(andoready[g]),
                .ostart(andostart[g]),
                .olast(andolast[g])
            );
        end
    endgenerate

endmodule