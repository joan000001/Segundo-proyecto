`timescale 1ns/1ps




module tb_sevseg;

  
  logic [3:0] bcd;

 
  logic [6:0] segments;

 
  sevseg uut (
    .bcd      (bcd),
    .segments (segments)
  );

  
  initial begin
    $dumpfile("tb_sevseg.vcd");
    $dumpvars(0, tb_sevseg);
  end

  
  initial begin
    integer i;
   
    $display("Time(ns) \  BCD  \ segments");
    $display("-----------------------------");
    for (i = 0; i < 16; i = i + 1) begin
      bcd = i;
      #10;
      $display("%8t \ %b \ %b", $time, bcd, segments);
    end
    #10;
    $finish;
  end

endmodule


module tb_multiplex_display;
    
    localparam int TEST_REFRESH = 10;

    
    logic clk;
    logic rst_n;
    logic [3:0] digit0;
    logic [3:0] digit1;
    logic [3:0] digit2;

    // Outputs
    wire [6:0] segments;
    wire [2:0] enable_displays;

    
    multiplex_display #(
        .REFRESH_CNT(TEST_REFRESH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .digit0(digit0),
        .digit1(digit1),
        .digit2(digit2),
        .segments(segments),
        .enable_displays(enable_displays)
    );

    // Clock generation: 100MHz -> period 10ns
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

   
    initial begin
        
        $dumpfile("multiplex_display_tb.vcd");
        $dumpvars(0, tb_multiplex_display);

        
        rst_n  = 0;
        digit0 = 4'd1;
        digit1 = 4'd2;
        digit2 = 4'd3;
        #20;

        
        rst_n = 1;
        #200;

        
        digit0 = 4'd4; digit1 = 4'd5; digit2 = 4'd6;
        #200;
        digit0 = 4'd7; digit1 = 4'd8; digit2 = 4'd9;
        #200;
        digit0 = 4'd0; digit1 = 4'd1; digit2 = 4'd2;
        #200;

        
        $finish;
    end

    
    initial begin
        $display("Time    Display  Segments  Enable");
        $monitor("%0t   %0d       %b    %b", $time, dut.current_display, segments, enable_displays);
    end
endmodule


`timescale 1ns/1ps

module tb_keypad_decoder;

  
  logic [1:0] row;
  logic [1:0] col;

  
  logic [3:0] bcd_value;
  logic       valid;

  
  keypad_decoder uut (
    .row       (row),
    .col       (col),
    .bcd_value (bcd_value),
    .valid     (valid)
  );

  
  initial begin
    $dumpfile("tb_keypad_decoder.vcd");
    $dumpvars(0, tb_keypad_decoder);
  end

  
  initial begin
    
    $display("Time   row col | bcd_value valid");
    $display("--------------------------------");

   
    for (int i = 0; i < 4; i++) begin
      for (int j = 0; j < 4; j++) begin
        row = i;
        col = j;
        #10;
        $display("%0t   %b   %b  |     %0d      %b",
                 $time, row, col, bcd_value, valid);
      end
    end

    
    #10;
    $finish;
  end

endmodule
