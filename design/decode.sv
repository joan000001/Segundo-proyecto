module keypad_decoder (
    input  logic [1:0] row,
    input  logic [1:0] col,
    output logic [3:0] bcd_value,
    output logic       valid
);
    always_comb begin
        valid = 1'b1;
        unique case ({row, col})
            4'b00_00: bcd_value = 4'd1;
            4'b00_01: bcd_value = 4'd2;
            4'b00_10: bcd_value = 4'd3;

            4'b01_00: bcd_value = 4'd4;
            4'b01_01: bcd_value = 4'd5;
            4'b01_10: bcd_value = 4'd6;

            4'b10_00: bcd_value = 4'd7;
            4'b10_01: bcd_value = 4'd8;
            4'b10_10: bcd_value = 4'd9;

            // '*' reset, '0', '#' keys
            4'b11_00: bcd_value = 4'd10;
            4'b11_01: bcd_value = 4'd0;
            4'b11_10: bcd_value = 4'd11;

            default: begin
                bcd_value = 4'd0;
                valid     = 1'b0;
            end
        endcase
    end
endmodule
