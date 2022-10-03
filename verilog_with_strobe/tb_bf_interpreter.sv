`timescale  1ns / 1ps

module test;
  
  parameter PERIOD    = 10;
  parameter WORD_SIZE = 8;
  
  typedef logic [WORD_SIZE-1:0] t_word;

  // bf_machine Inputs
  logic  clk;
  logic  rst;

  t_word machine_input;
  logic  machine_input_ready;
  logic  machine_input_valid;

  // bf_machine Outputs
  t_word machine_output;
  logic  machine_output_ready;
  logic  machine_output_valid;

  bf_machine #(
      .TAPE_LENGTH(16),
      .WORD_SIZE(8),
      //.PROGRAM_LENGTH(256),
      .MAX_DEPTH(15)
  ) UUT (
      .clk,
      .rst,

      .machine_input,
      .machine_input_valid,
      .machine_input_ready,

      .machine_output,
      .machine_output_valid,
      .machine_output_ready
  );


  initial begin //clock generator
    clk = 0;
    forever #(PERIOD/2) clk=~clk;
  end

  initial begin //watchdog
    #(PERIOD*1000);
    $finish;
  end
          
  initial begin
    // Dump waves
    $dumpfile("dump.vcd");
    $dumpvars(0); // level 1 = dump signals only in this module, level 0 = dump all signals in lower modules
    
    machine_input = 0;
    machine_input_valid = 0;
    machine_output_ready = 0;

    rst = 1;
    #(PERIOD*2);
    rst = 0;

    sendInputWhenReady(3);
    sendInputWhenReady(9);
    sendInputWhenReady(5);

    #(PERIOD*20);
    $finish;
  end
  
  initial begin
    while(1) begin
      @(posedge clk);
      if(machine_output_valid) begin
        $display("output:%d\n", machine_output);

        @(posedge clk); //wait N cycles to test the stall
        @(posedge clk);
      
        machine_output_ready = 1;
        @(posedge clk);
        machine_output_ready = 0;
        
        @(posedge clk); //wait an extra few cycles to avoid retriggering
        @(posedge clk);
      end
    end
  end

  task sendInputWhenReady(t_word word);
    while(1) begin
      @(posedge clk);
      if(machine_input_ready) begin
        
        @(posedge clk); //wait N cycles to test the stall
        @(posedge clk);

        machine_input = word;
        machine_input_valid = 1;
        @(posedge clk);
        machine_input = 0;
        machine_input_valid = 0;
        
        @(posedge clk); //wait an extra few cycles to avoid retriggering
        @(posedge clk);
        
        break;
      end
    end

  endtask
endmodule


 
