module multiplex_display #(
    parameter int REFRESH_CNT = 1000
)(
    input  logic        clk,
    input  logic        rst_n,
    input  logic [3:0]  digit0,
    input  logic [3:0]  digit1,
    input  logic [3:0]  digit2,
    output logic [6:0]  segments,
    output logic [2:0]  enable_displays
);

    logic [1:0]  current_display;
    logic [16:0] refresh_counter;
    logic [3:0]  bcd_value;

    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            refresh_counter <= '0;
            current_display <= 2'd0;
        end else if (refresh_counter == REFRESH_CNT) begin
            refresh_counter <= '0;
            current_display <= (current_display == 2'd2) ? 2'd0 : current_display + 1;
        end else begin
            refresh_counter <= refresh_counter + 1;
        end
    end

    
    always_comb begin
        unique case (current_display)
            2'd0: bcd_value = digit0;
            2'd1: bcd_value = digit1;
            2'd2: bcd_value = digit2;
            default: bcd_value = 4'd0;
        endcase
    end

    
    always_comb begin
        unique case (current_display)
            2'd0: enable_displays = 3'b110;
            2'd1: enable_displays = 3'b101;
            2'd2: enable_displays = 3'b011;
            default: enable_displays = 3'b111;
        endcase
    end

    sevseg u_sevseg (
        .bcd     (bcd_value),
        .segments(segments)
    );

endmodule
