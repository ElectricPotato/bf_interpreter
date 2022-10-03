

`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

/*
    Note: the design is as simple as possible and doesnt have input/output strobes.
    This is handled by the program instead:

    machine outputs -1 (255) to signal it is ready to recieve input
        [-]-. //send -1
        ,+[,+]   //wait for -1

        //wait for not -1
                                if(b!=255)       final: a=(b==255), c= input
        a=1 a=in,b=0,c=0 b=c=a,a=0 a=1  if(b+1){a=0},b=0
        +  [,>[-]>[-]<<  [->+>+<<] +   >+[[-]<->]        <]>>.
        a   a bbb ccc    aa b c  a a    bbbbb a b        a   c

        //output a 0
        [-].


        //example 2
        [-]+++++++++++++++++++++++++++++++++. //send !
        ,---------------------------------[,---------------------------------]   //wait for !
        +  [,>[-]>[-]<<  [->+>+<<] +   >---------------------------------[[-]<->]        <]>>. //wait for not !

        

    machine outputs -2 (254) to signal the next signal change is an output
        [-]--. //send -2
        >.     //send output
*/

module TB_top ();
    parameter WORD_SIZE = 8;

    logic clk;
    logic rst;

    logic [WORD_SIZE-1:0] machine_input;
    logic [WORD_SIZE-1:0] machine_output;

    bf_machine UUT (.*);

    parameter CLOCK_PERIOD = 10; // 10ns = 100MHz
    always begin //clock generator
        #(CLOCK_PERIOD/2) clk = 1'b1;
        #(CLOCK_PERIOD/2) clk = 1'b0;
    end

    initial begin //reset generator
        rst = 1'b1;
        #100 rst = 1'b0;
    end

    /* program:
        [-]-.,+[,+]+[,>[-]>[-]<<[->+>+<<]+>+[[-]<->]<]>.> // input routine
        [ //main loop
            [->+<]   //add c to d, d is the total
            >>[-]--. //set e to -2 and output
            <.       //output d
            <<<      //go back to a
            [-]-.,+[,+]+[,>[-]>[-]<<[->+>+<<]+>+[[-]<->]<]>.> // input routine
        ]
    */

    //machine_input_sequence = [1,5,10,-4,-8,0]

    initial begin //input / output
        //wait for -1 to be present on machine output
        //send value
        //waid for 0 to be present on machine output
        //advance input_sequence pointer

        //make a task:
        //when the output goes from -2 (254) to a different value, print it
    end
   
endmodule // case_statement
