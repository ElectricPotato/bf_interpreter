`default_nettype none

//verilog brainfuck interpreter
//TODO: integrate this into a larger system
//expose i_machine_input_valid as a pin, alternatively,
//   make the input instruction take two bytes over SPI - one for if the input is ready one for the data byte
//this will be driven by an arduino uno 
//
//SCK, MOSI, MISO,
//CS0 for memory, CS1 for output, CS2 for input


module mod_bf_machine #(
    TAPE_LENGTH = 256,
    WORD_SIZE = 8,
    PROGRAM_LENGTH = 9, //infer from program somehow?
    MAX_DEPTH = 15
) (
    input logic i_clk,
    input logic i_rst,

    input  logic [WORD_SIZE-1:0] i_machine_input,
    input  logic i_machine_input_valid,
    output logic o_machine_input_ready,

    output logic [WORD_SIZE-1:0] o_machine_output,
    output logic o_machine_output_valid,
    input  logic i_machine_output_ready
);
    typedef enum bit [2:0] {
        INSTR_P = 0, //+ plus
        INSTR_M = 1, //- minus
        INSTR_R = 2, //> right
        INSTR_L = 3, //< left
        INSTR_O = 4, //. output
        INSTR_I = 5, //, input
        INSTR_J = 6, //[ open bracket
        INSTR_K = 7  //] close bracket
    } t_instr;

    t_instr machine_program[0:PROGRAM_LENGTH-1]; //program has an 8 character set -> 3 bits / character
    //initial begin
    //    $readmemh ("program.hex", machine_program, 0); // synthesizable on Xilinx
    //end

    //+[,[.-]+]
    assign machine_program[0]  = INSTR_P; 
    assign machine_program[1]  = INSTR_J;
    assign machine_program[2]  = INSTR_I;
    assign machine_program[3]  = INSTR_J;
    assign machine_program[4]  = INSTR_O;
    assign machine_program[5]  = INSTR_M;
    assign machine_program[6]  = INSTR_K;
    assign machine_program[7]  = INSTR_P;
    assign machine_program[8]  = INSTR_K;

    typedef enum bit [2:0] {
        STATE_RUNNING,  //executing as normal
        STATE_SEARCH_L, //traversing the program left (backwards) to find the matching bracket
        STATE_SEARCH_R, //traversing the program right (forwards) to find the matching bracket

        STATE_STALL_OUTPUT, //wait until output is ready to accept this machine's output
        STATE_STALL_INPUT   //wait until input is valid
    } t_sm_state;

    t_sm_state sm_state;

    logic [WORD_SIZE-1:0]            tape             [0:TAPE_LENGTH-1];
    logic [$clog2(TAPE_LENGTH)-1:0]    tape_pointer;
    logic [$clog2(PROGRAM_LENGTH)-1:0] program_pointer;
    logic [$clog2(MAX_DEPTH + 1)-1:0]  program_depth;

    logic advance_program_pointer;

    always@(posedge clk) begin
        machine_output_valid = 0;
        machine_output = 0;

        machine_input_ready = 0;

        if (rst) begin
            sm_state = STATE_RUNNING;
            tape = '{default:'0}; //set the whole tape to 0
            tape_pointer = 0;
            program_pointer = 0;
            program_depth = 0;
        end else begin

            //advance program pointer if the input/output was made available last cycle, otherwise keep stalling
            if (sm_state == STATE_STALL_OUTPUT) begin
                if (machine_output_ready) begin
                    sm_state = STATE_RUNNING;
                    program_pointer += 1;
                end else begin
                    machine_output = tape[tape_pointer];
                    machine_output_valid = 1;
                end
            end else if (sm_state == STATE_STALL_INPUT) begin
                if (machine_input_valid) begin
                    sm_state = STATE_RUNNING;
                    program_pointer += 1;
                    tape[tape_pointer] = machine_input;
                end else begin
                    machine_input_ready = 1;
                end
            end

            if (sm_state == STATE_RUNNING) begin
                advance_program_pointer = 1;
                case (machine_program[program_pointer])
                    INSTR_P: tape[tape_pointer] += 1; //+
                    INSTR_M: tape[tape_pointer] -= 1; //-
                    INSTR_R: tape_pointer += 1; //>
                    INSTR_L: tape_pointer -= 1; //<
                    INSTR_O: begin //.
                        machine_output = tape[tape_pointer];
                        machine_output_valid = 1;
                        if (!machine_output_ready) begin
                            advance_program_pointer = 0; //stall
                            sm_state = STATE_STALL_OUTPUT;
                        end
                    end
                    INSTR_I: begin //,
                        machine_input_ready = 1;
                        if (!machine_input_valid) begin
                            advance_program_pointer = 0; //stall
                            sm_state = STATE_STALL_INPUT;
                        end else begin
                            tape[tape_pointer] = machine_input;
                        end
                    end
                    INSTR_J: //[
                        if (!tape[tape_pointer]) begin
                            program_depth = 1;
                            sm_state = STATE_SEARCH_R;
                        end
                    INSTR_K: //]
                        if (tape[tape_pointer]) begin
                            program_depth = 1;
                            advance_program_pointer = 0;
                            sm_state = STATE_SEARCH_L;
                        end
                    default:
                        begin
                            //Nothing
                        end
                endcase

                if (advance_program_pointer) program_pointer += 1;

            end else if (sm_state == STATE_SEARCH_R) begin
                if (program_depth) begin
                    if (machine_program[program_pointer] == INSTR_K /* ] */) program_depth -= 1;
                    if (machine_program[program_pointer] == INSTR_J /* [ */) program_depth += 1;
                    program_pointer += 1;
                end else begin
                    sm_state = STATE_RUNNING;
                end
            end else if (sm_state == STATE_SEARCH_L) begin
                if (program_depth) begin
                    program_pointer -= 1;
                    if (machine_program[program_pointer] == INSTR_J /* [ */) program_depth -= 1;
                    if (machine_program[program_pointer] == INSTR_K /* ] */) program_depth += 1;
                end else begin
                    sm_state = STATE_RUNNING;
                end
            end
        end
    end
    
endmodule

