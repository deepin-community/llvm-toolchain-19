; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=x86_64-- | FileCheck %s

define i64 @test_clear_mask_i64_i32(i64 %x) nounwind {
; CHECK-LABEL: test_clear_mask_i64_i32:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    movq %rdi, %rax
; CHECK-NEXT:    testl %eax, %eax
; CHECK-NEXT:    js .LBB0_2
; CHECK-NEXT:  # %bb.1: # %t
; CHECK-NEXT:    movl $42, %eax
; CHECK-NEXT:  .LBB0_2: # %f
; CHECK-NEXT:    retq
entry:
  %a = and i64 %x, 2147483648
  %r = icmp eq i64 %a, 0
  br i1 %r, label %t, label %f
t:
  br label %f
f:
  %ret = phi i64 [ %x, %entry], [ 42, %t]
  ret i64 %ret
}

define i64 @test_set_mask_i64_i32(i64 %x) nounwind {
; CHECK-LABEL: test_set_mask_i64_i32:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    movq %rdi, %rax
; CHECK-NEXT:    testl %eax, %eax
; CHECK-NEXT:    jns .LBB1_2
; CHECK-NEXT:  # %bb.1: # %t
; CHECK-NEXT:    movl $42, %eax
; CHECK-NEXT:  .LBB1_2: # %f
; CHECK-NEXT:    retq
entry:
  %a = and i64 %x, 2147483648
  %r = icmp ne i64 %a, 0
  br i1 %r, label %t, label %f
t:
  br label %f
f:
  %ret = phi i64 [ %x, %entry], [ 42, %t]
  ret i64 %ret
}

define i64 @test_clear_mask_i64_i16(i64 %x) nounwind {
; CHECK-LABEL: test_clear_mask_i64_i16:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    movq %rdi, %rax
; CHECK-NEXT:    testw %ax, %ax
; CHECK-NEXT:    js .LBB2_2
; CHECK-NEXT:  # %bb.1: # %t
; CHECK-NEXT:    movl $42, %eax
; CHECK-NEXT:  .LBB2_2: # %f
; CHECK-NEXT:    retq
entry:
  %a = and i64 %x, 32768
  %r = icmp eq i64 %a, 0
  br i1 %r, label %t, label %f
t:
  br label %f
f:
  %ret = phi i64 [ %x, %entry], [ 42, %t]
  ret i64 %ret
}

define i64 @test_set_mask_i64_i16(i64 %x) nounwind {
; CHECK-LABEL: test_set_mask_i64_i16:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    movq %rdi, %rax
; CHECK-NEXT:    testw %ax, %ax
; CHECK-NEXT:    jns .LBB3_2
; CHECK-NEXT:  # %bb.1: # %t
; CHECK-NEXT:    movl $42, %eax
; CHECK-NEXT:  .LBB3_2: # %f
; CHECK-NEXT:    retq
entry:
  %a = and i64 %x, 32768
  %r = icmp ne i64 %a, 0
  br i1 %r, label %t, label %f
t:
  br label %f
f:
  %ret = phi i64 [ %x, %entry], [ 42, %t]
  ret i64 %ret
}

define i64 @test_clear_mask_i64_i8(i64 %x) nounwind {
; CHECK-LABEL: test_clear_mask_i64_i8:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    movq %rdi, %rax
; CHECK-NEXT:    testb %al, %al
; CHECK-NEXT:    js .LBB4_2
; CHECK-NEXT:  # %bb.1: # %t
; CHECK-NEXT:    movl $42, %eax
; CHECK-NEXT:  .LBB4_2: # %f
; CHECK-NEXT:    retq
entry:
  %a = and i64 %x, 128
  %r = icmp eq i64 %a, 0
  br i1 %r, label %t, label %f
t:
  br label %f
f:
  %ret = phi i64 [ %x, %entry], [ 42, %t]
  ret i64 %ret
}

define i64 @test_set_mask_i64_i8(i64 %x) nounwind {
; CHECK-LABEL: test_set_mask_i64_i8:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    movq %rdi, %rax
; CHECK-NEXT:    testb %al, %al
; CHECK-NEXT:    jns .LBB5_2
; CHECK-NEXT:  # %bb.1: # %t
; CHECK-NEXT:    movl $42, %eax
; CHECK-NEXT:  .LBB5_2: # %f
; CHECK-NEXT:    retq
entry:
  %a = and i64 %x, 128
  %r = icmp ne i64 %a, 0
  br i1 %r, label %t, label %f
t:
  br label %f
f:
  %ret = phi i64 [ %x, %entry], [ 42, %t]
  ret i64 %ret
}

define i32 @test_clear_mask_i32_i16(i32 %x) nounwind {
; CHECK-LABEL: test_clear_mask_i32_i16:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    movl %edi, %eax
; CHECK-NEXT:    testw %ax, %ax
; CHECK-NEXT:    js .LBB6_2
; CHECK-NEXT:  # %bb.1: # %t
; CHECK-NEXT:    movl $42, %eax
; CHECK-NEXT:  .LBB6_2: # %f
; CHECK-NEXT:    retq
entry:
  %a = and i32 %x, 32768
  %r = icmp eq i32 %a, 0
  br i1 %r, label %t, label %f
t:
  br label %f
f:
  %ret = phi i32 [ %x, %entry], [ 42, %t]
  ret i32 %ret
}

define i32 @test_set_mask_i32_i16(i32 %x) nounwind {
; CHECK-LABEL: test_set_mask_i32_i16:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    movl %edi, %eax
; CHECK-NEXT:    testw %ax, %ax
; CHECK-NEXT:    jns .LBB7_2
; CHECK-NEXT:  # %bb.1: # %t
; CHECK-NEXT:    movl $42, %eax
; CHECK-NEXT:  .LBB7_2: # %f
; CHECK-NEXT:    retq
entry:
  %a = and i32 %x, 32768
  %r = icmp ne i32 %a, 0
  br i1 %r, label %t, label %f
t:
  br label %f
f:
  %ret = phi i32 [ %x, %entry], [ 42, %t]
  ret i32 %ret
}

define i32 @test_clear_mask_i32_i8(i32 %x) nounwind {
; CHECK-LABEL: test_clear_mask_i32_i8:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    movl %edi, %eax
; CHECK-NEXT:    testb %al, %al
; CHECK-NEXT:    js .LBB8_2
; CHECK-NEXT:  # %bb.1: # %t
; CHECK-NEXT:    movl $42, %eax
; CHECK-NEXT:  .LBB8_2: # %f
; CHECK-NEXT:    retq
entry:
  %a = and i32 %x, 128
  %r = icmp eq i32 %a, 0
  br i1 %r, label %t, label %f
t:
  br label %f
f:
  %ret = phi i32 [ %x, %entry], [ 42, %t]
  ret i32 %ret
}

define i32 @test_set_mask_i32_i8(i32 %x) nounwind {
; CHECK-LABEL: test_set_mask_i32_i8:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    movl %edi, %eax
; CHECK-NEXT:    testb %al, %al
; CHECK-NEXT:    jns .LBB9_2
; CHECK-NEXT:  # %bb.1: # %t
; CHECK-NEXT:    movl $42, %eax
; CHECK-NEXT:  .LBB9_2: # %f
; CHECK-NEXT:    retq
entry:
  %a = and i32 %x, 128
  %r = icmp ne i32 %a, 0
  br i1 %r, label %t, label %f
t:
  br label %f
f:
  %ret = phi i32 [ %x, %entry], [ 42, %t]
  ret i32 %ret
}

define i16 @test_clear_mask_i16_i8(i16 %x) nounwind {
; CHECK-LABEL: test_clear_mask_i16_i8:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    movl %edi, %eax
; CHECK-NEXT:    testb %al, %al
; CHECK-NEXT:    js .LBB10_2
; CHECK-NEXT:  # %bb.1: # %t
; CHECK-NEXT:    movw $42, %ax
; CHECK-NEXT:  .LBB10_2: # %f
; CHECK-NEXT:    # kill: def $ax killed $ax killed $eax
; CHECK-NEXT:    retq
entry:
  %a = and i16 %x, 128
  %r = icmp eq i16 %a, 0
  br i1 %r, label %t, label %f
t:
  br label %f
f:
  %ret = phi i16 [ %x, %entry], [ 42, %t]
  ret i16 %ret
}

define i16 @test_set_mask_i16_i8(i16 %x) nounwind {
; CHECK-LABEL: test_set_mask_i16_i8:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    movl %edi, %eax
; CHECK-NEXT:    testb %al, %al
; CHECK-NEXT:    jns .LBB11_2
; CHECK-NEXT:  # %bb.1: # %t
; CHECK-NEXT:    movw $42, %ax
; CHECK-NEXT:  .LBB11_2: # %f
; CHECK-NEXT:    # kill: def $ax killed $ax killed $eax
; CHECK-NEXT:    retq
entry:
  %a = and i16 %x, 128
  %r = icmp ne i16 %a, 0
  br i1 %r, label %t, label %f
t:
  br label %f
f:
  %ret = phi i16 [ %x, %entry], [ 42, %t]
  ret i16 %ret
}

define i16 @test_set_mask_i16_i7(i16 %x) nounwind {
; CHECK-LABEL: test_set_mask_i16_i7:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    movl %edi, %eax
; CHECK-NEXT:    testb $64, %al
; CHECK-NEXT:    je .LBB12_2
; CHECK-NEXT:  # %bb.1: # %t
; CHECK-NEXT:    movw $42, %ax
; CHECK-NEXT:  .LBB12_2: # %f
; CHECK-NEXT:    # kill: def $ax killed $ax killed $eax
; CHECK-NEXT:    retq
entry:
  %a = and i16 %x, 64
  %r = icmp ne i16 %a, 0
  br i1 %r, label %t, label %f
t:
  br label %f
f:
  %ret = phi i16 [ %x, %entry], [ 42, %t]
  ret i16 %ret
}