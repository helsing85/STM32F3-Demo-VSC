# connect to OpenOCD
target extended-remote :3333

# print demangled symbols
set print asm-demangle on

# set backtrace limit to not have infinite backtrace loops
set backtrace limit 32

# load program
load

# Enable semihosting
monitor arm semihosting enable

# detect unhandled exceptions, hard faults and panics
break Reset_Handler
# break HardFault

# *try* to stop at the user entry point (it might be gone due to inlining)
break main

# start the process but immediately halt the processor
stepi
