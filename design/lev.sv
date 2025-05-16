`timescale 1ns / 1ps

module sevseg(
    input  logic [3:0] bcd,       
    output logic [6:0] segments   
);

    logic [6:0] segments_reg;

    always_comb begin
        case (bcd)
            4'b0000: segments_reg = 7'b0111111; // 0
            4'b0001: segments_reg = 7'b0000110; // 1
            4'b0010: segments_reg = 7'b1011011; // 2
            4'b0011: segments_reg = 7'b1001111; // 3
            4'b0100: segments_reg = 7'b1100110; // 4
            4'b0101: segments_reg = 7'b1101101; // 5
            4'b0110: segments_reg = 7'b1111101; // 6
            4'b0111: segments_reg = 7'b0000111; // 7
            4'b1000: segments_reg = 7'b1111111; // 8
            4'b1001: segments_reg = 7'b1101111; // 9
            4'b1010: segments_reg = 7'b0001000; // A
            4'b1011: segments_reg = 7'b0000011; // b
            4'b1100: segments_reg = 7'b1000110; // C
            4'b1101: segments_reg = 7'b0100001; // d
            4'b1110: segments_reg = 7'b0000110; // E
            4'b1111: segments_reg = 7'b0001110; // F
            default: segments_reg = 7'b0000000; // Apagado tot
        endcase
    end

  assign segments = ~segments_reg; 

endmodule



