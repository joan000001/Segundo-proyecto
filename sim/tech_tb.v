`timescale 1ns/1ps

module tb_keypad_decoder;

  // Inputs to DUT
  logic [1:0] row;
  logic [1:0] col;

  // Outputs from DUT
  logic [3:0] bcd_value;
  logic       valid;

  // Instantiate the decoder
  keypad_decoder uut (
    .row       (row),
    .col       (col),
    .bcd_value (bcd_value),
    .valid     (valid)
  );

  // Dump waves for GTKWave
  initial begin
    $dumpfile("tb_keypad_decoder.vcd");
    $dumpvars(0, tb_keypad_decoder);
  end

  // Test stimulus
  initial begin
    integer i, j;

    // Header
    $display("Time | row col | bcd_value | valid");
    $display("-----------------------------------");

    // Apply all combinations of row and col (0 to 3)
    for (i = 0; i < 4; i++) begin
      for (j = 0; j < 4; j++) begin
        row = i;
        col = j;
        #10;  // wait for output to settle
        $display("%4dns |   %0d   %0d |     %0d     |   %b", $time, row, col, bcd_value, valid);
      end
    end

    // Finish simulation
    #10;
    $finish;
  end

endmodule


module tb_sevseg;

  // Input to DUT
  logic [3:0] bcd;

  // Output from DUT
  logic [6:0] segments;

  // Instantiate the seven-segment decoder
  sevseg uut (
    .bcd      (bcd),
    .segments (segments)
  );

  // Dump waves for GTKWave
  initial begin
    $dumpfile("tb_sevseg.vcd");
    $dumpvars(0, tb_sevseg);
  end

  // Test stimulus: cycle through all BCD values 0-F
  initial begin
    integer i;
    // Header
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

  // Parameters for simulation (shorten REFRESH_CNT)
  localparam int SIM_REFRESH = 20;

  // Clock and reset
  logic clk;
  logic rst_n;

  // Inputs to DUT
  logic [3:0] digit0;
  logic [3:0] digit1;
  logic [3:0] digit2;

  // Outputs from DUT
  logic [6:0] segments;
  logic [2:0] enable_displays;

  // Instantiate the multiplex_display with reduced refresh count
  multiplex_display #(
    .REFRESH_CNT(SIM_REFRESH)
  ) uut (
    .clk            (clk),
    .rst_n          (rst_n),
    .digit0         (digit0),
    .digit1         (digit1),
    .digit2         (digit2),
    .segments       (segments),
    .enable_displays(enable_displays)
  );

  // Clock generation: 10ns period
  initial clk = 0;
  always #5 clk = ~clk;

  // Waveform dump
  initial begin
    $dumpfile("tb_multiplex_display.vcd");
    $dumpvars(0, tb_multiplex_display);
  end

  // Stimulus
  initial begin
    // Initialize
    rst_n   = 1'b0;
    digit0  = 4'd1;
    digit1  = 4'd2;
    digit2  = 4'd3;

    #25;
    rst_n = 1'b1; // Release reset

    // Change digits after some time
    #200;
    digit0 = 4'd7;
    digit1 = 4'd8;
    digit2 = 4'd9;

    // Let it run for a few refresh cycles
    #500;
    $finish;
  end

  // Monitor outputs
  initial begin
    $display("Time | seg hex | enable");
    $display("--------------------------");
    forever begin
      @(posedge clk);
      $display("%4dns | %b | %b", $time, segments, enable_displays);
    end
  end

endmodule