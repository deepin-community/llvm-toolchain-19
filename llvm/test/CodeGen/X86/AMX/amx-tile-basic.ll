; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mattr=+amx-tile,+amx-int8,+amx-bf16,+avx512f -verify-machineinstrs | FileCheck %s

define void @test_amx(ptr %pointer, ptr %base, i64 %stride) {
; CHECK-LABEL: test_amx:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vxorps %xmm0, %xmm0, %xmm0
; CHECK-NEXT:    vmovups %zmm0, -{{[0-9]+}}(%rsp)
; CHECK-NEXT:    movb $1, -{{[0-9]+}}(%rsp)
; CHECK-NEXT:    movb $8, -{{[0-9]+}}(%rsp)
; CHECK-NEXT:    movw $8, -{{[0-9]+}}(%rsp)
; CHECK-NEXT:    movb $8, -{{[0-9]+}}(%rsp)
; CHECK-NEXT:    movw $8, -{{[0-9]+}}(%rsp)
; CHECK-NEXT:    movb $8, -{{[0-9]+}}(%rsp)
; CHECK-NEXT:    movw $8, -{{[0-9]+}}(%rsp)
; CHECK-NEXT:    ldtilecfg -{{[0-9]+}}(%rsp)
; CHECK-NEXT:    movw $8, %ax
; CHECK-NEXT:    tilezero %tmm0
; CHECK-NEXT:    tileloadd (%rsi,%rdx), %tmm1
; CHECK-NEXT:    tileloadd (%rsi,%rdx), %tmm2
; CHECK-NEXT:    tdpbssd %tmm2, %tmm1, %tmm0
; CHECK-NEXT:    tdpbsud %tmm2, %tmm1, %tmm0
; CHECK-NEXT:    tdpbusd %tmm2, %tmm1, %tmm0
; CHECK-NEXT:    tdpbuud %tmm2, %tmm1, %tmm0
; CHECK-NEXT:    tdpbf16ps %tmm2, %tmm1, %tmm0
; CHECK-NEXT:    tileloaddt1 (%rsi,%rdx), %tmm1
; CHECK-NEXT:    tilestored %tmm0, (%rdi,%rdx)
; CHECK-NEXT:    tilerelease
; CHECK-NEXT:    vzeroupper
; CHECK-NEXT:    retq
  %c = call x86_amx @llvm.x86.tilezero.internal(i16 8, i16 8)
  %a = call x86_amx @llvm.x86.tileloadd64.internal(i16 8, i16 8, ptr %base, i64 %stride)
  %b = call x86_amx @llvm.x86.tileloadd64.internal(i16 8, i16 8, ptr %base, i64 %stride)
  %d0 = call x86_amx @llvm.x86.tdpbssd.internal(i16 8, i16 8, i16 8, x86_amx %c, x86_amx %a, x86_amx %b)
  %d1 = call x86_amx @llvm.x86.tdpbsud.internal(i16 8, i16 8, i16 8, x86_amx %d0, x86_amx %a, x86_amx %b)
  %d2 = call x86_amx @llvm.x86.tdpbusd.internal(i16 8, i16 8, i16 8, x86_amx %d1, x86_amx %a, x86_amx %b)
  %d3 = call x86_amx @llvm.x86.tdpbuud.internal(i16 8, i16 8, i16 8, x86_amx %d2, x86_amx %a, x86_amx %b)
  %d4 = call x86_amx @llvm.x86.tdpbf16ps.internal(i16 8, i16 8, i16 8, x86_amx %d3, x86_amx %a, x86_amx %b)
  %e = call x86_amx @llvm.x86.tileloaddt164.internal(i16 8, i16 8, ptr %base, i64 %stride)
  call void @llvm.x86.tilestored64.internal(i16 8, i16 8, ptr %pointer, i64 %stride, x86_amx %d4)

  ret void
}

declare x86_amx @llvm.x86.tilezero.internal(i16, i16)
declare x86_amx @llvm.x86.tileloadd64.internal(i16, i16, ptr, i64)
declare x86_amx @llvm.x86.tileloaddt164.internal(i16, i16, ptr, i64)
declare x86_amx @llvm.x86.tdpbssd.internal(i16, i16, i16, x86_amx, x86_amx, x86_amx)
declare x86_amx @llvm.x86.tdpbsud.internal(i16, i16, i16, x86_amx, x86_amx, x86_amx)
declare x86_amx @llvm.x86.tdpbusd.internal(i16, i16, i16, x86_amx, x86_amx, x86_amx)
declare x86_amx @llvm.x86.tdpbuud.internal(i16, i16, i16, x86_amx, x86_amx, x86_amx)
declare x86_amx @llvm.x86.tdpbf16ps.internal(i16, i16, i16, x86_amx, x86_amx, x86_amx)
declare void @llvm.x86.tilestored64.internal(i16, i16, ptr, i64, x86_amx)

define void @PR90954(ptr %0, ptr %1, i32 %2) nounwind {
; CHECK-LABEL: PR90954:
; CHECK:       # %bb.0:
; CHECK-NEXT:    pushq %rbp
; CHECK-NEXT:    movq %rsp, %rbp
; CHECK-NEXT:    pushq %r15
; CHECK-NEXT:    pushq %r14
; CHECK-NEXT:    pushq %r13
; CHECK-NEXT:    pushq %r12
; CHECK-NEXT:    pushq %rbx
; CHECK-NEXT:    andq $-1024, %rsp # imm = 0xFC00
; CHECK-NEXT:    subq $5120, %rsp # imm = 0x1400
; CHECK-NEXT:    vxorps %xmm0, %xmm0, %xmm0
; CHECK-NEXT:    vmovups %zmm0, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    movb $1, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    movb $16, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    movw $64, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    movb $16, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    movw $64, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    movb $16, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    movw $64, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    ldtilecfg {{[0-9]+}}(%rsp)
; CHECK-NEXT:    shll $4, %edx
; CHECK-NEXT:    xorl %eax, %eax
; CHECK-NEXT:    movw $64, %cx
; CHECK-NEXT:    movw $16, %di
; CHECK-NEXT:    movb $1, %r8b
; CHECK-NEXT:    movl $64, %r9d
; CHECK-NEXT:    leaq {{[0-9]+}}(%rsp), %r10
; CHECK-NEXT:    leaq {{[0-9]+}}(%rsp), %r11
; CHECK-NEXT:    xorl %ebx, %ebx
; CHECK-NEXT:    xorl %r14d, %r14d
; CHECK-NEXT:    jmp .LBB1_1
; CHECK-NEXT:    .p2align 4, 0x90
; CHECK-NEXT:  .LBB1_5: # in Loop: Header=BB1_1 Depth=1
; CHECK-NEXT:    incq %r14
; CHECK-NEXT:    addl %edx, %ebx
; CHECK-NEXT:  .LBB1_1: # =>This Loop Header: Depth=1
; CHECK-NEXT:    # Child Loop BB1_2 Depth 2
; CHECK-NEXT:    movslq %ebx, %r15
; CHECK-NEXT:    leaq (%rsi,%r15,4), %r15
; CHECK-NEXT:    xorl %r12d, %r12d
; CHECK-NEXT:    xorl %r13d, %r13d
; CHECK-NEXT:    jmp .LBB1_2
; CHECK-NEXT:    .p2align 4, 0x90
; CHECK-NEXT:  .LBB1_4: # in Loop: Header=BB1_2 Depth=2
; CHECK-NEXT:    tilestored %tmm1, (%r15,%rax)
; CHECK-NEXT:    incq %r13
; CHECK-NEXT:    addq $64, %r15
; CHECK-NEXT:    decq %r12
; CHECK-NEXT:    je .LBB1_5
; CHECK-NEXT:  .LBB1_2: # Parent Loop BB1_1 Depth=1
; CHECK-NEXT:    # => This Inner Loop Header: Depth=2
; CHECK-NEXT:    tilezero %tmm0
; CHECK-NEXT:    tilezero %tmm1
; CHECK-NEXT:    testb %r8b, %r8b
; CHECK-NEXT:    jne .LBB1_4
; CHECK-NEXT:  # %bb.3: # in Loop: Header=BB1_2 Depth=2
; CHECK-NEXT:    vmovaps %zmm0, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    vmovaps %zmm0, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    vmovaps %zmm0, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    vmovaps %zmm0, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    vmovaps %zmm0, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    vmovaps %zmm0, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    vmovaps %zmm0, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    vmovaps %zmm0, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    vmovaps %zmm0, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    vmovaps %zmm0, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    vmovaps %zmm0, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    vmovaps %zmm0, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    vmovaps %zmm0, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    vmovaps %zmm0, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    vmovaps %zmm0, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    vmovaps %zmm0, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    tileloadd (%r10,%r9), %tmm1
; CHECK-NEXT:    vmovaps %zmm0, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    vmovaps %zmm0, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    vmovaps %zmm0, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    vmovaps %zmm0, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    vmovaps %zmm0, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    vmovaps %zmm0, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    vmovaps %zmm0, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    vmovaps %zmm0, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    vmovaps %zmm0, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    vmovaps %zmm0, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    vmovaps %zmm0, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    vmovaps %zmm0, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    vmovaps %zmm0, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    vmovaps %zmm0, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    vmovaps %zmm0, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    vmovaps %zmm0, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    tileloadd (%r11,%r9), %tmm2
; CHECK-NEXT:    tdpbf16ps %tmm2, %tmm1, %tmm0
; CHECK-NEXT:    movq %rax, {{[-0-9]+}}(%r{{[sb]}}p) # 8-byte Spill
; CHECK-NEXT:    movabsq $64, %rax
; CHECK-NEXT:    tilestored %tmm0, 3072(%rsp,%rax) # 1024-byte Folded Spill
; CHECK-NEXT:    tileloadd {{[-0-9]+}}(%r{{[sb]}}p), %tmm1 # 1024-byte Folded Reload
; CHECK-NEXT:    movq {{[-0-9]+}}(%r{{[sb]}}p), %rax # 8-byte Reload
; CHECK-NEXT:    jmp .LBB1_4
  %4 = shl i32 %2, 4
  %5 = icmp eq i64 0, 0
  br label %6

6:                                                ; preds = %31, %3
  %7 = phi i64 [ 0, %3 ], [ %32, %31 ]
  %8 = trunc nuw nsw i64 %7 to i32
  %9 = mul i32 %4, %8
  %10 = mul i32 0, %8
  %11 = sext i32 %9 to i64
  %12 = getelementptr inbounds i32, ptr %1, i64 %11
  br label %13

13:                                               ; preds = %25, %6
  %14 = phi i64 [ %29, %25 ], [ 0, %6 ]
  %15 = tail call x86_amx @llvm.x86.tilezero.internal(i16 16, i16 64)
  %16 = tail call <256 x i32> @llvm.x86.cast.tile.to.vector.v256i32(x86_amx %15)
  %17 = shl nsw i64 %14, 4
  %18 = getelementptr i32, ptr %0, i64 %17
  br i1 %5, label %25, label %19

19:                                               ; preds = %13
  %20 = tail call x86_amx @llvm.x86.cast.vector.to.tile.v256i32(<256 x i32> %16)
  %21 = tail call x86_amx @llvm.x86.cast.vector.to.tile.v256i32(<256 x i32> zeroinitializer)
  %22 = tail call x86_amx @llvm.x86.cast.vector.to.tile.v256i32(<256 x i32> zeroinitializer)
  %23 = tail call x86_amx @llvm.x86.tdpbf16ps.internal(i16 16, i16 64, i16 64, x86_amx %20, x86_amx %21, x86_amx %22)
  %24 = tail call noundef <256 x i32> @llvm.x86.cast.tile.to.vector.v256i32(x86_amx %23)
  br label %25

25:                                               ; preds = %19, %13
  %26 = phi <256 x i32> [ undef, %13 ], [ %24, %19 ]
  %27 = getelementptr inbounds i32, ptr %12, i64 %17
  %28 = tail call x86_amx @llvm.x86.cast.vector.to.tile.v256i32(<256 x i32> %26)
  tail call void @llvm.x86.tilestored64.internal(i16 16, i16 64, ptr %27, i64 0, x86_amx %28)
  %29 = add nuw nsw i64 %14, 1
  %30 = icmp eq i64 %29, 0
  br i1 %30, label %31, label %13

31:                                               ; preds = %25
  %32 = add nuw nsw i64 %7, 1
  br label %6
}

define void @multi_use() nounwind {
; CHECK-LABEL: multi_use:
; CHECK:       # %bb.0:
; CHECK-NEXT:    pushq %rbp
; CHECK-NEXT:    subq $2928, %rsp # imm = 0xB70
; CHECK-NEXT:    vxorps %xmm0, %xmm0, %xmm0
; CHECK-NEXT:    vmovups %zmm0, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    movb $1, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    movb $16, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    movw $64, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    movb $16, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    movw $64, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    movw $64, %ax
; CHECK-NEXT:    ldtilecfg {{[0-9]+}}(%rsp)
; CHECK-NEXT:    movw $16, %cx
; CHECK-NEXT:    tilezero %tmm0
; CHECK-NEXT:    movabsq $64, %rbp
; CHECK-NEXT:    tilestored %tmm0, 896(%rsp,%rbp) # 1024-byte Folded Spill
; CHECK-NEXT:    tileloadd {{[-0-9]+}}(%r{{[sb]}}p), %tmm1 # 1024-byte Folded Reload
; CHECK-NEXT:    tdpbf16ps %tmm0, %tmm0, %tmm1
; CHECK-NEXT:    tdpbf16ps %tmm0, %tmm0, %tmm0
; CHECK-NEXT:    addq $2928, %rsp # imm = 0xB70
; CHECK-NEXT:    popq %rbp
; CHECK-NEXT:    tilerelease
; CHECK-NEXT:    vzeroupper
; CHECK-NEXT:    retq
  %1 = call x86_amx @llvm.x86.tilezero.internal(i16 16, i16 64)
  %2 = call x86_amx @llvm.x86.tdpbf16ps.internal(i16 16, i16 64, i16 64, x86_amx %1, x86_amx %1, x86_amx %1)
  %3 = call x86_amx @llvm.x86.tdpbf16ps.internal(i16 16, i16 64, i16 64, x86_amx %1, x86_amx %1, x86_amx %1)
  ret void
}

declare x86_amx @llvm.x86.cast.vector.to.tile.v256i32(<256 x i32>)
declare <256 x i32> @llvm.x86.cast.tile.to.vector.v256i32(x86_amx)