#!/usr/bin/env python3.4

# -----------------------------------------------------------------------------
# mipsTester.py 
# Coder: Aris Efthymiou
# 
# This code was developed for the following course:
#   MYY402 - Computer Architecture,
#   Department of Computer Science and Enginnering, University of Ioannina
# 
# -----------------------------------------------------------------------------

import os, subprocess, re, ast, operator, tempfile

# Colours for pretty printing of messages!
FAIL = '\033[91m'
ENDC = '\033[0m'

# Max instructions to execute
MAX_INST = 500000


# Thanks to poke from stackoverflow for this improved arithmetic evaluator:
# http://stackoverflow.com/questions/20748202/valueerror-malformed-string-when-using-ast-literal-eval
binOps = {
    ast.Add: operator.add,
    ast.Sub: operator.sub,
    ast.Mult: operator.mul,
    ast.Div: operator.truediv,
    ast.Mod: operator.mod
}

def arithmeticEval (s):
    node = ast.parse(s, mode='eval')

    def _eval(node):
        if isinstance(node, ast.Expression):
            return _eval(node.body)
        elif isinstance(node, ast.Str):
            return node.s
        elif isinstance(node, ast.Num):
            return node.n
        elif isinstance(node, ast.BinOp):
            return binOps[type(node.op)](_eval(node.left), _eval(node.right))
        else:
            raise Exception('Unsupported type {}'.format(node))

    return _eval(node.body)

# -----------------------------------------------------------------------------
# Function: runMars
#   Executes a MIPS program using the Mars simulator. Checks expected values
#   against Mars output at the end of simulation.
# Parameters:
#   prog    = String containing filename of the assembly program to run
#   expect_regs - dictionary of expected register - value pairs
#                 They may be strings such as t0, sp or numbers e.g. 12
#                 They should *not* start with $
#   expect_mem  - dictionary of expected mem-address/label - value pairs
#                 Expected mem addresses can be nu, both must be on word boundary. Option may be repeated.mbers or strings
#                   strings may contain 1 label on its own or within an
#                   arithmetic expression, but it must not start with a number
#                   example: label+3*16-4
#                 Memory addresses **must be** word-aligned!
#   marsJar - String containing full-path filename of Mars jar file
#   verbose - boolean for verbose reporting / debugging
# Returns:
#   (int, int, String) - a tuple containing the error code,
#                        number of executed instructions
#                        and a message (mars output, error message)
#                   zero in error code means all is good.
# -----------------------------------------------------------------------------
def runMars(prog, expect_regs, expect_mem_in, \
            marsJar = "/usr/home/grads/courses/myy402/bin/MarsMYY402_4_5.jar",\
            verbose = False):

  # Check valididy of inputs -------------------------------------------------
  if not os.path.isfile(marsJar):
    return (1, 0, FAIL+"ERROR: cannot find MARS at "+marsJar+ENDC)
  if not os.path.isfile(prog):
    return (1, 0, FAIL+"ERROR: cannot find assembly program "+prog+ENDC)

  # Assemble program and get label addresses ----------------------------------
  try:
    marsOutput = subprocess.check_output("java -jar " + marsJar + " nc ld ae5 " + prog,\
                 stderr=subprocess.STDOUT, shell=True, universal_newlines=True)
  except subprocess.CalledProcessError as e:
    return (e.returncode, 0, e.output)

  # Parse label - address output of assembler ---------------------------------
  allLabels = {}
  pattern = re.compile(r'^(\w+) address (.*)$')
  for line in marsOutput.split('\n'):
    match = re.search(pattern, line)
    if match:
      allLabels[match.group(1)] = match.group(2)
      #allLabels[match.group(1)] = int(match.group(2),0)

  # Scan expect_regs, check register names, convert keys to strings 
  #   All Mars output is read as strings, so types need to match.
  validRegs = re.compile(r'^(zero|a[0-3t]|v[01]|s[0-7]|t\d|k[01]|gp|sp|fp|ra|\d|1\d|2\d|3[01])$')
  for reg in expect_regs.keys():
    if type(reg) is int:
        # Add it to the dictionary with a string key
        regName = str(reg)
        expect_regs[regName] = expect_regs[reg]
        # remove numeric key
        del expect_regs[reg]
        reg = regName # assign to reg in order to do checks

    # parse the expect_regs[reg] for expressions!
    exp_label = expect_regs[reg]
    if not type(exp_label) is int:
        found = False
        for known_label in allLabels:
            if re.search(known_label, exp_label):
              # In exp_label (which could be a math expression) replace known_label
              #  with its address
              temp = exp_label.replace(known_label, allLabels.get(known_label))
              address = arithmeticEval(temp)
              found = True
              # assume only one label will be used in an expected expression
              break
        if not found:
            return (2, 0, FAIL+"ERROR: cannot find label '"+exp_label+"' in program"+ENDC)
        expect_regs[reg] = address
    # Check if regname is valid
    match = re.search(validRegs,reg)
    if not match:
      return (1, 0, FAIL+"ERROR: unknown register ("+reg+") in expect_regs"+ENDC)



  # Scan expect_mem_in replacing labels with memory addresses
  #   due to strange bug, I'm copying replaced labels in dict expect_mem
  #   it wasn't always removing keys from the dict...
  #  Keep "inverted map": address -> label in invLabelDict
  invLabelDict = {}
  expect_mem = {}
  for exp_label in expect_mem_in:
    if type(exp_label) is int:
      hexAddr = hex(exp_label)
      expect_mem[hexAddr] = expect_mem_in[exp_label]
      exp_label = hexAddr
      invLabelDict[exp_label] = exp_label
      continue
    # exp_label is not an int
    match = re.search(r'^\d', exp_label)
    if match:  # User provided an address, i.e. starts with a digit (also captures 0x...)
      expect_mem[exp_label] = expect_mem_in[exp_label]
      invLabelDict[exp_label] = exp_label
    else:  # "exp_label" is **not** an address
      ##################################################
      # Could be an expression containing a label!
      #   try to match all known labels from assembler to "exp_label"
      #    if no match, error
      #    if match, replace with address and eval the thing to get a number
      #        then convert to hex and carry on...
      ##################################################
      found = False
      for known_label in allLabels:
        if re.search(known_label, exp_label):
          # In exp_label (which could be a math expression) replace known_label
          #  with its address
          temp = exp_label.replace(known_label, allLabels.get(known_label))
          address = hex(arithmeticEval(temp))
          found = True
          # assume only one label will be used in an expected expression
          break
      if not found:
        return (2, 0, FAIL+"ERROR: cannot find label '"+exp_label+"' in program"+ENDC)
      exp_value = expect_mem_in[exp_label]
      # replace exp_label with corresponding address
      expect_mem[address] = exp_value
      # keep address -> exp_label, "inverse map"
      invLabelDict[address] = exp_label

  # Run program in Mars ---------------------------------------------------------
  # Create list of expected registers and mem addresses in format 
  #   required by Mars
  # Convert all expected registers into a string.
  regs = " ".join(expect_regs.keys())
  # Ditto for mem addresses, but they have to be in form: addr-addr
  mems = " ".join(["%s-%s" % (k,k) for k in expect_mem.keys()])
  try: 
    # Run Mars with options:
    #   Do not print copyright (nc)
    #   Output instruction count (ic)
    #   Display all contents in hexadecimal (hex)
    #   Return code 6 if execution fails (se6)
    #   Start execution from main (sm)
    #   Max number of instructions to execute (MAX_INST). Catch infinite loops
    marsOutput = subprocess.check_output("java -jar %s nc ic hex se6 sm %d %s %s %s" \
                 % (marsJar, MAX_INST, regs, mems, prog), \
                 stderr=subprocess.STDOUT, shell=True, universal_newlines=True)
  except subprocess.CalledProcessError as e:
    return (e.returncode, 0, FAIL+"ERROR: Mars error:\n"+ENDC+e.output)

  # Get values and compare against expected values for registers/memory addresses
  asExpected = True  # Stays true is all values are as expected
  ic = 0  # Instruction count
  out_reg = {}  # Register comparison output dictionary
  out_mem = {}  # Memory comparison output dictionary
  # Anything starting with $ is reg contents
  regPattern = re.compile(r'^\$(.*)\s(0x.*)$')
  # Anything starting with Mem[ is memory contents
  memPattern = re.compile(r'^Mem\[(.*)\]\s(0x.*)$')
  # Just a number should be instruction count. NOTE: could be program output!
  icPattern = re.compile(r'^([0-9]+)$')
  for line in marsOutput.split('\n'):
    # match registers ------------------
    match = re.search(regPattern, line)
    if match:
      if comp(expect_regs[match.group(1)], match.group(2)):
        out_reg[match.group(1)] = "ok: both equal to %s" %(match.group(2))
      else:
        asExpected = False
        out_reg[match.group(1)] = FAIL+"WRONG: expected %s (%s), Mars output %s" \
                                  %(expect_regs[match.group(1)],
                                    my_hex(expect_regs[match.group(1)]), match.group(2)) + ENDC
    # match memory ---------------------
    match = re.search(memPattern, line)
    if match:
      label = invLabelDict[match.group(1)]  # Get the label of this address
      if comp(expect_mem[match.group(1)], match.group(2)):
        out_mem[label] = "ok: both equal to %s" %(match.group(2))
      else:
        asExpected = False
        out_mem[label] = FAIL+"WRONG: expected %s (%s), Mars output %s"\
                         %(expect_mem[match.group(1)],
                          my_hex(expect_mem[match.group(1)]), match.group(2))+ENDC 
    # Instruction count
    match = re.search(icPattern, line)
    if match:
      ic = int(match.group(1))

  if ic == MAX_INST:
    asExpected = False
    marsOutput = marsOutput + FAIL + \
      "\nReached maximum number of executed instructions. Infinite loop in program?\n"+ENDC
  if verbose:
    marsOutput = marsOutput + "---- Expected results ---- \nRegisters:\n" + \
                 "\n".join(["%s -> %s" % (k,v) for (k,v) in out_reg.items()]) + \
                 "\nMemory:\n" + \
                 "\n".join(["%s -> %s" % (k,v) for (k,v) in out_mem.items()])
  if asExpected:
    return (0, ic, marsOutput)
  else:
    return (3, ic, FAIL+"FAILED TO MATCH EXPECTED RESULS\n"+ENDC + \
               "---- Mars output ----\n" + marsOutput)



# -----------------------------------------------------------------------------
# Function: comp
# Parameters:
#  userVal - user provided value
#  marsVal - value scanned/parsed from mars output
#    Compare user provided (expected) value to MARS output
#    The user may provide an integer or a string. It could be negative.
#    MARS always outputs 32b hex string
#    User value is converted to integer, then to 32bits (using 2's complement if negative) 
#    and then Mars output is converted to int and compared.
# Returns:
#    Boolean - true if values match
# -----------------------------------------------------------------------------
def comp(userVal, marsVal):
  if not type(userVal) is int: 
    userVal = int(userVal, 0) # Convert provided number to int (in case it is string)
  if userVal < 0:  # provided number is negative
    userVal = 0xffffffff & (0x100000000 + userVal)   # Convert to 32bit 2's complement
  # Convert marsVal to int and compare
  return userVal == int(marsVal,16)


# -----------------------------------------------------------------------------
# Convers to hex, with negative numbers converted to 32'b 2's complement
# -----------------------------------------------------------------------------
def my_hex(val):
  if val < 0:
    val = 0xffffffff & (0x100000000 + val)   # Convert to 32bit 2's complement
  return hex(val)


# -----------------------------------------------------------------------------
# Run multiple 'tests' on a program using the runMars function
# Parameters:
#   prog - the filename of the assembly program to run/test
#   tests - a list of tuples. Each tuple is a test:
#            1st element is a string for the test name
#            2nd element is a list of strings containing sed replacement commands
#               They are used to provide input to the program, by modifying
#               data under specific labels
#            3rd element is a dict for expected registers (see runMars() above)
#            4th element is a dict for expected memory (see runMars() above)
# Returns:
#   a string with result of execution of all tests
# -----------------------------------------------------------------------------
def runTests(prog, tests, \
            marsJar = "/usr/home/grads/courses/myy402/bin/MarsMYY402_4_5.jar",\
            verbose = False):

  out = ""
  if not os.path.isfile(prog):
    return FAIL+"ERROR: cannot find assembly program "+prog+ENDC
  for idx, test in enumerate(tests):
    test_name = test[0]
    input_changes = test[1]   # get the sed replacement commands
    expect_regs = test[2]
    expect_mem = test[3]
    # ------------
    modFile = tempfile.NamedTemporaryFile(mode='w+',suffix=".asm",encoding="utf-8",delete=False)
    # Do not delete. Windows requires tempFile 2b closed b4 Mars opens it for execution
    changed = False
    with open (prog, 'r', encoding="latin-1", errors="surrogateescape") as origFile:
      for line in origFile:
        new = line
        for i in input_changes:
          if re.match(i[0], line):
              new = re.sub(i[0], i[1], line)
              changed = True
              break
        modFile.write(new)
      modFile.close()
    if not changed:
        out += '\nCHECK: test did not modify the file.'
    # RunMars
    (s, ic, m) = runMars(modFile.name, expect_regs, expect_mem, marsJar, True)
    # Delete temp
    os.unlink(modFile.name)
    # ----- Old code ----
    # Assemble the sed command:
    #c = 'sed -b -i_b%d' % (idx)
    #for i in input_changes:
    #  c += ' -e "%s"' %(i)
    #c += ' ' + prog
    ## Run sed to modify input
    #if input_changes:
    #  os.system(c)
    ## RunMars
    #(s, ic, m) = runMars(prog, expect_regs, expect_mem, marsJar, True)

    if s == 0:
      out += "\n------------------------------\nPASSED %s" % (test_name)
      out += "\nExecuted %d instructions\n" %(ic)
      if verbose:
        out += "---- Mars output ----\n%s" % (m)
    else:
      out += FAIL+"\n-------------------------\nFAILED %s" % (test_name) + ENDC
      out += "\nExecuted %d instructions\n%s" % (ic, m) 

  return out
    
