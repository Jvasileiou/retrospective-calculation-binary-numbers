# Calculate the population count of an array
# for MYΥ-402 - Computer Architecture
# Department of Computer Engineering, University of Ioannina
# John Vasileiou

        .globl main # declare the label main as global. 
        
        .text 

main:
        # These are for providing input and testing, don't change in your
        #  final submission
        li    $v0, -1   # non-zero v0 to catch code dependent on zeroed regs

        li    $a0, 0xa5ca3695
        jal   popc
        addu  $s0, $v0, $zero   # Move the result to s0 for tester to check

        li    $a0, 0x0
        jal   popc
        addu  $s1, $v0, $zero   # Move the result to s1 for tester to check

        # Try it with an array
        la    $a0, array
        li    $a1, 4
        jal   sum_popc
        addu  $s2, $v0, $zero   # Move the result to s2 for tester to check

        # Try it with 1 item 
        la    $a0, array
        addi  $a0, $a0, 12
        li    $a1, 1
        jal   sum_popc
        addu  $s3, $v0, $zero   # Move the result to s3 for tester to check

        # ----- Try with 0
        la    $a0, array
        li    $a1, 0
        jal   sum_popc
        addu  $s4, $v0, $zero   # Move the result to s4 for tester to check


        addiu      $v0, $zero, 10    # system service 10 is exit
        syscall                      # we are outta here.

 
        ########################################################################

        ########################################################################

popc:		
		#Create our Masks
		li     $t3, 0x55555555 # mask1 = $t3
		li     $t4, 0x33333333 # mask2 = $t4 
		li     $t5, 0x0F0F0F0F # mask3 = $t5
		li     $t6, 0x00FF00FF # mask4 = $t6
		li     $t7, 0x0000FFFF # mask5 = $t7
		
		#the value of $a0 is our number (inpout)
		and     $t0, $a0, $t3  # t0 = (a0 >> 0) & 0101 0101 0101 0101 0101 0101 0101 0101 
		srl     $t1, $a0, 1    # shift right 1 bit , t1 = (a0 >> 1)
		and     $t1, $t1, $t3  # t1 = (a0 >> 1) & 0101 0101 0101 0101 0101 0101 0101 0101
		addu    $t9, $t0, $t1  # $t9 = $t0 + $t1
		
		and     $t0, $t9, $t4  # t0 = ($t9 >> 0) & 0011 0011 0011 0011 0011 0011 0011 0011
		srl     $t1, $t9, 2    # shift right 2 bit , t1 = ($t9 >> 2)          
		and     $t1, $t1, $t4  # t1 = ($t9 >> 2) & 0011 0011 0011 0011 0011 0011 0011 0011 
		addu    $t9, $t0, $t1  # $t9 = $t0 + $t1
		
		and     $t0, $t9, $t5  # t0 = ($t9 >> 0) & 0000 1111 0000 1111 0000 1111 0000 1111
		srl     $t1, $t9, 4    # shift right 4 bit , t1 = ($t9 >> 4)          
		and     $t1, $t1, $t5  # t1 = ($t9 >> 4) & 0000 1111 0000 1111 0000 1111 0000 1111
		addu    $t9, $t0, $t1  # $t9 = $t0 + $t1
		
		and     $t0, $t9, $t6  # t0 = ($t9 >> 0) & 0000 0000 1111 1111 0000 0000 1111 1111
		srl     $t1, $t9, 8    # shift right 8 bit , t1 = ($t9 >> 8)          
		and     $t1, $t1, $t6  # t1 = ($t9 >> 8) & 0000 0000 1111 1111 0000 0000 1111 1111 
		addu    $t9, $t0, $t1  # $t9 = $t0 + $t1
		
		and     $t0, $t9, $t7  # t0 = ($t9 >> 8) & 0000 0000 0000 0000 1111 1111 1111 1111
		srl     $t1, $t9, 16   # shift right 16 bit , t1 = ($t9 >> 16)   
		and     $t1, $t1, $t7  # t1 = ($t9 >> 8) & 0000 0000 0000 0000 1111 1111 1111 1111
		addu    $v0, $t0, $t1  # $v0 = $t0 + $t1 , return $v0
		
        	jr      $ra


sum_popc:
       		addi 	$sp, $sp, -8      # adjust stack or 2 items		
		sw	$ra, 4($sp)       # save the return address
		
		add     $t8, $zero, $a0   # copy of $a0 = address of array = address of array[0] 
		bne	$a1,$zero,L1      # if the value of array[i] != 0, got to L1
		add	$v0,$zero,$zero   # return 0
		addi 	$sp, $sp,8  	  # pop 2 items off stack
		
		jr      $ra    		  # return to caller
		
L1: 							
		addi 	$a1, $a1, -1      # zero = zero - 1
		add 	$t1, $zero, $zero # initialization of a counter = $t1
loop:
		beq 	$t1, $a1, exit    # if counter == size , go to exit 
		addi	$a0, $a0, 4       # $a0 += 4 ,go to the next item 
		addi 	$t1, $t1, 1       # counter ++
		j 	loop              # go to loop
		
exit:	
		lw 	$a0, 0($a0)       # get the number, means the value of array[size]
		jal	popc 		  # call popc with input array[size]	
		
		add 	$a0, $zero, $t8   # $ao gets the address of the array
		sw	$v0,0($sp)	  # save the result (how many ones the number has)	
		jal 	sum_popc	  # call sum_popc with (array,size-1)
		
		lw 	$ra, 4($sp)       # restore the return address 
		lw 	$t2, 0($sp)       # restore the result
		add  	$v0, $v0, $t2	  # v0 += result , return $v0
		addi 	$sp, $sp, 8 	  # adjust $sp to pop 2 items
		
        	jr    $ra		  # return to the caller

        
        ###############################################################################
        # Data input.
        ###############################################################################
       .data
array: .word 0xa5ca3691, 0x5a3695ca, 0x36a9ca55, 0xc55a36a9
