module FIFO #(parameter n = 8)
(
    input logic clock,
    input logic reset,
    input logic [n-1:0] idata,
    input logic ivalid,
    output logic [n-1:0] odata,
    input logic oready,
    output logic [3:0] count
);

    logic [3:0] readpoint;
    logic [3:0] writepoint;
    logic [n-1:0] mem [0:15];

    int i;
  
    always @(posedge clock)
    begin
        if (reset == 0)
        begin
            for (i = 0; i < 16 ;i = i + 1)
            begin
                mem[i] <= 0;
            end
            odata <= 0;
            readpoint <= 0;
            writepoint <= 0;
            count <= 0;
        end
        else
        begin
            if (ivalid == 1 && oready == 1)
            begin
                mem[writepoint] <= idata;
                writepoint <= writepoint + 1;
                odata <= mem[readpoint];
                readpoint <= readpoint + 1;
            end
            else if (ivalid == 1)
            begin
                mem[writepoint] <= idata;
                writepoint <= writepoint + 1;
                count <= count + 1;
            end
            else if (oready == 1)
            begin
                odata <= mem[readpoint];
                readpoint <= readpoint + 1;
                count <= count - 1;
            end
        end
    end
endmodule

