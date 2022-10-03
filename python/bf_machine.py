import math

class BFMachine:
    '''A brainfuck interpreter'''

    valid_instructions = '><+-.,[]'

    def __init__(self, tape_list=[], program='', machine_input=[], tape_length=-1, max_int=255, input_mode = 'bytes'):
        #this can be used for reset of the machine too
        #set tape length to -1 for dynamic tape

        self.dynamic_tape = False
        self.input_mode = input_mode
        if(tape_length == -1):
            self.tape_length = 1
            self.dynamic_tape = True
        else:
            self.tape_length = tape_length
        self.max_int = max_int

        self.init_tape(tape_list)
        self.program = [instr for instr in program if instr in BFMachine.valid_instructions]
        self.machine_input = machine_input

        self.exec_tape_pos = 0
        self.exec_program_pos = 0
        self.exec_level = 0
        self.exec_running = True
        self.exec_cycles = 0

        self.exec_expecting_input = False

    def init_tape(self, tape_list):
        def extend_list(lst, target_length, padding_element, dynamic_tape):
            if(len(lst) > target_length):
                return lst if(dynamic_tape) else lst[:target_length]
            else:
                return lst + [padding_element] * (target_length - len(lst))
        
        if(len(tape_list) > 0):
                self.tape_length = len(tape_list)
                
        self.tape = extend_list(tape_list, self.tape_length, 0, self.dynamic_tape)

    def init_program(self, program):
        self.program = program

    def init_input(self, machine_input):
        self.machine_input = machine_input

    def add_input(self, machine_input):
        self.machine_input += machine_input

    def run(self, max_cycles = -1):
        def find_matching_bracket(direction):
            base_level = self.exec_level

            while(True):
                self.exec_program_pos += direction
                if((self.exec_program_pos >= len(self.program)) or (self.exec_program_pos < 0)):
                    print("unmatched brackets")
                    self.exec_running = False
                    break

                if(self.program[self.exec_program_pos] == ']'):
                    if(direction == +1 and self.exec_level == base_level):
                        break
                    else:
                        self.exec_level += -direction
                elif(self.program[self.exec_program_pos] == '['):
                    if(direction == -1 and self.exec_level == base_level):
                        break
                    else:
                        self.exec_level += +direction

        output = []
        run_cycles = 0
        self.exec_running = True
        
        if(self.exec_program_pos >= len(self.program)):
            self.exec_running = False
            return []

        while(self.exec_running and (run_cycles != max_cycles)):
            instr = self.program[self.exec_program_pos]
            if  (instr == '>'):
                if(self.exec_tape_pos == self.tape_length - 1):
                    if(self.dynamic_tape):
                        self.tape_length += 1
                        self.tape.append(0)
                        #print(f'new tape length: {self.tape_length}')
                    else:
                        print(" > WRAPAROUND")

                self.exec_tape_pos = (self.exec_tape_pos + 1) % self.tape_length
            elif(instr == '<'):
                if(self.exec_tape_pos == 0):
                    print(" < WRAPAROUND")
                self.exec_tape_pos = (self.exec_tape_pos - 1) % self.tape_length
            elif(instr == '+'):
                self.tape[self.exec_tape_pos] = (self.tape[self.exec_tape_pos] + 1) % (self.max_int + 1)
            elif(instr == '-'):
                self.tape[self.exec_tape_pos] = (self.tape[self.exec_tape_pos] - 1) % (self.max_int + 1)
            elif(instr == '.'):
                output += [self.tape[self.exec_tape_pos]]
            elif(instr == ','):
                if(self.machine_input):
                    self.tape[self.exec_tape_pos] = self.machine_input.pop(0)
                    self.exec_expecting_input = False
                else:
                    self.exec_expecting_input = True
                    self.exec_running = False

            elif(instr == '['):
                if(self.tape[self.exec_tape_pos] == 0): #jump forward to the position after the matching ]
                    find_matching_bracket(+1)
                else:
                    self.exec_level += 1

            elif(instr == ']'):
                if(self.tape[self.exec_tape_pos] != 0):
                    find_matching_bracket(-1)
                else:
                    self.exec_level -= 1

            if(self.exec_running):
                self.exec_program_pos += 1
                self.exec_cycles += 1
                run_cycles += 1
                if(self.exec_program_pos >= len(self.program)):
                    self.exec_running = False
                

        return output

    def get_tape(self):
        return self.tape

    def show_program_pos(self, max_characters_per_row = 25):
        output = ''
        pointer_line = ' '*self.exec_program_pos + '^'
        for i in range(math.ceil(len(self.program) / max_characters_per_row)):
            output += ''.join(self.program[i*max_characters_per_row : i*max_characters_per_row + max_characters_per_row]) + '\n'
            output += pointer_line[i*max_characters_per_row : i*max_characters_per_row + max_characters_per_row] + '\n'
        return output

    def show_tape_pos(self, max_characters_per_row = 100, digits_per_element=3, seperator=' '):
        output = ''
        format_str = f'{{:{digits_per_element}}}' + seperator

        element_len = digits_per_element + len(seperator)
        elements_per_row = int(max_characters_per_row / element_len)
        max_characters_per_row = elements_per_row * element_len

        pointer_line = ' ' * (self.exec_tape_pos * element_len) + '^' * digits_per_element
        for i in range(math.ceil(self.tape_length / elements_per_row)):
            for tape_pos in range(i*elements_per_row, min(i*elements_per_row + elements_per_row, len(self.tape))):
                output += format_str.format(self.tape[tape_pos])
            output += '\n'
            output += pointer_line[i*max_characters_per_row : i*max_characters_per_row + max_characters_per_row] + '\n'
        return output

    def show_status(self):
        if(self.exec_running):
            status = 'Running'
        elif(self.exec_expecting_input):
            status = 'Expecting input'
        else:
            status = 'Not running'

        output = f'Cycle {self.exec_cycles}, {status}, Level: {self.exec_level}\n'

        return output

    def show_machine_status(self):
        output = ''
        output += self.show_status()
        output += self.show_program_pos()
        output += self.show_tape_pos()

        return output

    def run_repl(self, debug=''):
        while(self.exec_running or self.exec_expecting_input):
            output = []
            cycle_output = []

            def show_state():
                if(debug == 'full'):
                    if(cycle_output):
                        print(f'Output: {cycle_output[0]} ({chr(cycle_output[0])})')

                    print(self.show_machine_status())
                elif(debug == 'small'):
                    print(f'{self.exec_cycles} {cycle_output} {self.exec_program_pos} {self.exec_tape_pos} {self.exec_level} {self.tape_length}')

            if(debug == 'small'):
                print('Columns:')
                print('{self.exec_cycles} {cycle_output} {self.exec_program_pos} {self.exec_tape_pos} {self.exec_level} {self.tape_length}')
            show_state()
            while(self.exec_running or (self.exec_expecting_input and self.machine_input)):
                cycle_output = self.run(1)
                output += cycle_output

                show_state()
            if(not self.exec_running):
                import string
                printable = string.ascii_letters + string.digits + string.punctuation + ' \n\t\r'
                def hex_escape(s):
                    return ''.join(c if c in printable else r'\x{0:02x}'.format(ord(c)) for c in s)
                output_str = hex_escape([chr(c) for c in output])
                print(f'Outputs: {output} ({output_str})')

            if(self.exec_expecting_input):
                if(self.input_mode == 'int'):
                    ns = [int(i) for i in input(">").split()]
                else:
                    ns = [ord(i) for i in input(">")]
                self.add_input(ns)