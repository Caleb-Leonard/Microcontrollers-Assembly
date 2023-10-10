add $t1, $zero, $zero
addi $t2, $zero, 1
add $t3, $zero, $zero
addi $t4, $zero, 143
addi $t5, $zero, $zero

Start:
   jal Store

   jal Sum
   
   beq $t0, $t4, End
   
   addi $t5, $t5, 4
   
   j Start
   
   Sum:
      add $t3, $t1, $t2
      add $t0, $t0, $t3
      jr $ra
   
   Store:
      sw $t0, 5000($t5)
      
      add $t1, $t2, $zero
      add $t2, $t3, $zero
      
      jr $ra

End: