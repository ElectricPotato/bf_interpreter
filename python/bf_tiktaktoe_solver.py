from bf_machine import BFMachine

def solve():
    from pathlib import Path
    filepath = Path(__file__).with_name('tik_tak_toe.bf')
    with open(filepath) as f:
        program = f.read()
    bf = BFMachine([], program=program, tape_length=-1)

    #[8,6,4,2,0]
    def run_one_game(sequence):
        game_running = True
        steps = 0

        real_sequence = []
        
        bf.add_input([ord(str(sequence[0]+1))])
        real_sequence += [sequence[0]+1]
        while(game_running):
            for n in sequence[1:]:
                output = bf.run()
                output_str = ''.join([chr(c) for c in output])
                board = output_str[1:6:2] + output_str[8:13:2] + output_str[15:20:2]
                #print(output_str, board)

                turnout = -1
                if  ("Lose" in output_str): turnout = 0
                elif("Draw" in output_str): turnout = 1
                elif("Win"  in output_str): turnout = 2
                if(turnout != -1):
                    return (turnout, real_sequence[:steps+1])

                #find the nth occurance of '-' in string
                chosen_input = 0
                for i in range(len(board)):
                    if(board[i] == '-'):
                        if(n==0):
                            chosen_input = i
                            break
                        else:
                            n -= 1
                
                bf.add_input([ord(str(chosen_input+1))])
                real_sequence += [chosen_input+1]
                #input()
                steps += 1


    combination = [0] * 5
    comb_range = [8,6,4,2,0]
    for combination[0] in range(comb_range[0]+1):
        for combination[1] in range(comb_range[1]+1):
            for combination[2] in range(comb_range[2]+1):
                for combination[3] in range(comb_range[3]+1):
                    for combination[4] in range(comb_range[4]+1):
                        turnout = run_one_game(combination)
                        if(turnout[0] == 2):
                            print(turnout)

if __name__ == '__main__':
    solve()

#winning moves:
#16897, 18697, 1879, 2413, 24913, 2631, 26731, 27631, 34879, 38479, 3897, 4213, 42913, 43879, 48379, 4879, 5936, 61897, 6231, 62731, 68197, 6897, 72631, 81697, 8179, 83479, 8397, 84379, 8479, 86197, 8697