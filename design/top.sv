module top (
    input  logic        clk,
    input  logic [3:0]  columnas,
    output logic [3:0]  filas,
    output logic [6:0]  segments,
    output logic [2:0]  enable_displays
);

    
    logic [1:0] row, col;
    logic       raw_valid, dec_valid;
    logic [3:0] decoded;
    logic [1:0] target_digit;
    logic [3:0] digits [2:0];
    logic       key_hash_d;

    
    wire key_star = raw_valid && dec_valid && (decoded == 4'd10);
    wire key_hash = raw_valid && dec_valid && (decoded == 4'd11);

    
    keypad_scan #(
        .SCAN_CNT_MAX    (100_000),
        .DEBOUNCE_CYCLES (3)
    ) u_scan (
        .clk      (clk),
        .rst_n    (1'b1),
        .columnas (columnas),
        .filas    (filas),
        .row      (row),
        .col      (col),
        .valid    (raw_valid)
    );

   
    keypad_decoder u_dec (
        .row       (row),
        .col       (col),
        .bcd_value (decoded),
        .valid     (dec_valid)
    );

    
    always_ff @(posedge clk) begin
        
        key_hash_d <= key_hash;

        if (key_star) begin
            
            digits[0]      <= 4'd0;
            digits[1]      <= 4'd0;
            digits[2]      <= 4'd0;
            target_digit   <= 2'd0;
        end else begin
            
            if (key_hash && !key_hash_d) begin
                target_digit <= (target_digit == 2) ? 2'd0 : target_digit + 1;
            end
            
            if (raw_valid && dec_valid && (decoded != 4'd10) && (decoded != 4'd11)) begin
                digits[target_digit] <= decoded;
            end
        end
    end

   
    multiplex_display #(
        .REFRESH_CNT (100_000)
    ) u_display (
        .clk            (clk),
        .rst_n          (1'b1),
        .digit0         (digits[0]),
        .digit1         (digits[1]),
        .digit2         (digits[2]),
        .segments       (segments),
        .enable_displays(enable_displays)
    );

endmodule