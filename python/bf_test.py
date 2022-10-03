from bf_machine import BFMachine


def read_file(filename):
    from pathlib import Path
    filepath = Path(__file__).with_name(filename)
    with open(filepath) as f:
        program = f.read()
    return program

def first_example():
    bf = BFMachine([0,3,4], '.>.>.>>>>>>.', tape_length=-1)
    bf.run_repl(debug='full')
    return

    print(bf.show_machine_status())
    while(bf.exec_running):
        bf.run(1)
        print(bf.show_machine_status())

def repl_example():
    bf = BFMachine([], ',[[->+<]>.<,]', tape_length=10)
    bf.run_repl()

def repl_example2():
    program = read_file('tik_tak_toe.bf')
    bf = BFMachine([], program=program, tape_length=-1)
    bf.run_repl()
    #bf.run_repl(debug='small')

if __name__ == '__main__':
    first_example()
    #repl_example()
    #repl_example2()