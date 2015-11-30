# Test automation script 

import os, sys, glob
from subprocess32 import check_output, Popen, PIPE, call

# if len(sys.argv) == 1:
#     print('Running with default configurations:\n')

# else:
#     print('usage: -f,  or no command line args')
#     print('-f: prints full results of every test')
#     print('-e: show stderr of menhir')
#     print ('no command line args: runs all tests and only prints tests that failed, suppresses stderr of menhir.\n')
#     sys.exit()

path = r'dtest'
for dir_entry in os.listdir(path):
    filepath = os.path.join(path, dir_entry)
    if os.path.isfile(filepath) and filepath[-5:] == '.dots':
        print('\nRunning tests in ' + dir_entry)
        print('================================')
        dotc_input = Popen(['cat', filepath], stdout=PIPE)
        try:
            output = check_output(['./gdc'], stdin=dotc_input.stdout, timeout=30)
        except:
            print 'You probably forgot to make the compiler dumbass...'
            continue;

        output_filepath = os.path.join(path, dir_entry[:-5] + '.outc')
        with open(output_filepath, 'w') as intermediate_output:
            intermediate_output.write(output)

        out_filepath = os.path.join(path, dir_entry[:-5] + '.out')
        output_filepath = os.path.join(path, dir_entry[:-5] + '.outc')

        diff_command = ['diff', '-b', out_filepath, output_filepath]
        diff_child = Popen(diff_command, stdout=PIPE)

        if diff_child.returncode == 0:
            print 'passed'
        else: 
            print 'failed, writing diff to .dif file'
            with open(os.path.join(path, dir_entry[:-5] + '.dif'), 'w') as diff_output:
                diff_output.write(diff_child.communicate()[0])

for f in glob.glob(os.path.join(path,'*.outc')):
    os.remove(f)

if '-k' not in sys.argv:
    for f in glob.glob(os.path.join(path,'*.dif')):
        os.remove(f)

print('\n Tests completed.')
