# Type your program here
addi $t1, $t1, 1
add $t2, $t2, $zero
addi $t3, $zero, 144

Start:
   jal Store
   
   beq $t1, $t3, End
   
   addi $t4, $t4, 4
   bne $t1, $t3, Start
   
j End

Store:
   sw $t2, 5000($t4)
   j Sum
   
Sum:
   add $t0, $t1, $t2
   add $t2, $t1, $zero
   add $t1, $t0, $zero
   
   jr $ra
   
End:
   