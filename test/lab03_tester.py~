#!/usr/bin/env python3.4
import os.path
from mipsTester import runTests

if os.path.isfile("/usr/home/grads/courses/myy402/bin/MarsMYY402_4_5.jar"):
  # This is the path to MarsMYY402_4_5.jar for the lab machines.
  marsJar = "/usr/home/grads/courses/myy402/bin/MarsMYY402_4_5.jar"
else:
  ##########################################
  # This is my set-up for my machine,
  # MODIFY FOR YOUR PERSONAL COMPUTER SETUP!
  #  USING THE FULL PATH TO MarsMYY402_4_5.jar IN YOUR COMPUTER
  ##########################################
  marsJar = "/home/efthym/t/ca_course/MarsMYY402_4_5.jar"

tests = [ \
 ("Test all", \
  [],\
  {'s0' : 16, 's1' : 0, 's2' : 63, 's3' : 16, 's4' : 0, 'sp' : 0x7fffeffc}, \
  {} \
 ) \
]

print (runTests("../lab03.asm", tests, marsJar, verbose=True))

