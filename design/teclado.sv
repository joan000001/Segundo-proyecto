module keypad_scan #(
    parameter int DEBOUNCE_CYCLES = 100_000,
    parameter int SCAN_CNT_MAX = 3
)(
    input  logic        clk,
    input  logic        rst_n,
    input  logic [3:0]  columnas,
    output logic [3:0]  filas,
    output logic [1:0]  row,
    output logic [1:0]  col,
    output logic        valid
);

    
    localparam int CNT_WIDTH = $clog2(DEBOUNCE_CYCLES);

    
    logic [CNT_WIDTH-1:0]            scan_counter;
    logic [1:0]                      current_row;
    logic [3:0]                      col_sample;
    logic [$clog2(SCAN_CNT_MAX)-1:0] debounce_cnt;
    logic                             stable;

    
    always_comb begin
        filas = 4'b1 << current_row;
    end

    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            col_sample   <= 4'd0;
            debounce_cnt <= '0;
            stable       <= 1'b0;
        end else if (columnas == col_sample && columnas != 4'd0) begin
            if (debounce_cnt == SCAN_CNT_MAX - 1) begin
                stable <= 1'b1;
            end else begin
                debounce_cnt <= debounce_cnt + 1;
                stable       <= 1'b0;
            end
        end else begin
            col_sample   <= columnas;
            debounce_cnt <= '0;
            stable       <= 1'b0;
        end
    end

    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scan_counter <= '0;
            current_row  <= 2'd0;
            valid        <= 1'b0;
            row          <= 2'd0;
            col          <= 2'd0;
        end else begin
           
            if (scan_counter == (DEBOUNCE_CYCLES >> 1) - 1) begin
                if (stable && (col_sample & (col_sample - 1)) == 4'd0) begin  
                    row   <= current_row;
                    unique case (col_sample)
                        4'b0001: col <= 2'd0;
                        4'b0010: col <= 2'd1;
                        4'b0100: col <= 2'd2;
                        4'b1000: col <= 2'd3;
                        default: col <= 2'd0;
                    endcase
                    valid <= 1'b1;
                end else begin
                    valid <= 1'b0;
                end
            end

            
            if (scan_counter == DEBOUNCE_CYCLES - 1) begin
                scan_counter <= '0;
                current_row  <= (current_row == 2'd3) ? 2'd0 : current_row + 1;
            end else begin
                scan_counter <= scan_counter + 1;
                
                if (scan_counter != (DEBOUNCE_CYCLES >> 1) - 1)
                    valid <= 1'b0;
            end
        end
    end

endmodule