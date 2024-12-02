; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py UTC_ARGS: --version 2
; RUN: llc -mcpu=pwr9 -ppc-asm-full-reg-names \
; RUN:   -mtriple=powerpc64-linux-gnu < %s | FileCheck  %s \
; RUN:   -check-prefix=BE64
; RUN: llc -mcpu=pwr9 -ppc-asm-full-reg-names \
; RUN:   -mtriple=powerpc-linux-gnu < %s | FileCheck  %s \
; RUN:   -check-prefix=BE32
; RUN: llc -mcpu=pwr9 -ppc-asm-full-reg-names \
; RUN:   -mtriple=powerpc64le-linux-gnu < %s | FileCheck  %s \
; RUN:   -check-prefix=LE
define dso_local signext i32 @test(i32 noundef signext %a) local_unnamed_addr #0 {
; BE64-LABEL: test:
; BE64:       # %bb.0: # %entry
; BE64-NEXT:    lwz r4, -28772(r13)
; BE64-NEXT:    andis. r4, r4, 128
; BE64-NEXT:    bne cr0, .LBB0_3
; BE64-NEXT:  # %bb.1: # %if.else
; BE64-NEXT:    lwz r4, -28776(r13)
; BE64-NEXT:    andis. r4, r4, 1024
; BE64-NEXT:    bne cr0, .LBB0_4
; BE64-NEXT:  # %bb.2: # %if.else3
; BE64-NEXT:    lwz r4, -28764(r13)
; BE64-NEXT:    cmplwi r4, 39
; BE64-NEXT:    addi r4, r3, 5
; BE64-NEXT:    slwi r3, r3, 1
; BE64-NEXT:    iseleq r3, r3, r4
; BE64-NEXT:  .LBB0_3: # %return
; BE64-NEXT:    extsw r3, r3
; BE64-NEXT:    blr
; BE64-NEXT:  .LBB0_4: # %if.then2
; BE64-NEXT:    addi r3, r3, -5
; BE64-NEXT:    extsw r3, r3
; BE64-NEXT:    blr
; BE64:       .quad   __parse_hwcap_and_convert_at_platform
;
; BE32-LABEL: test:
; BE32:       # %bb.0: # %entry
; BE32-NEXT:    lwz r4, -28732(r2)
; BE32-NEXT:    andis. r4, r4, 128
; BE32-NEXT:    bnelr cr0
; BE32-NEXT:  # %bb.1: # %if.else
; BE32-NEXT:    lwz r4, -28736(r2)
; BE32-NEXT:    andis. r4, r4, 1024
; BE32-NEXT:    bne cr0, .LBB0_3
; BE32-NEXT:  # %bb.2: # %if.else3
; BE32-NEXT:    lwz r4, -28724(r2)
; BE32-NEXT:    cmplwi r4, 39
; BE32-NEXT:    addi r4, r3, 5
; BE32-NEXT:    slwi r3, r3, 1
; BE32-NEXT:    iseleq r3, r3, r4
; BE32-NEXT:    blr
; BE32-NEXT:  .LBB0_3: # %if.then2
; BE32-NEXT:    addi r3, r3, -5
; BE32-NEXT:    blr
; BE32:       .long   __parse_hwcap_and_convert_at_platform
;
; LE-LABEL: test:
; LE:       # %bb.0: # %entry
; LE-NEXT:    lwz r4, -28776(r13)
; LE-NEXT:    andis. r4, r4, 128
; LE-NEXT:    bne cr0, .LBB0_3
; LE-NEXT:  # %bb.1: # %if.else
; LE-NEXT:    lwz r4, -28772(r13)
; LE-NEXT:    andis. r4, r4, 1024
; LE-NEXT:    bne cr0, .LBB0_4
; LE-NEXT:  # %bb.2: # %if.else3
; LE-NEXT:    lwz r4, -28764(r13)
; LE-NEXT:    cmplwi r4, 39
; LE-NEXT:    addi r4, r3, 5
; LE-NEXT:    slwi r3, r3, 1
; LE-NEXT:    iseleq r3, r3, r4
; LE-NEXT:  .LBB0_3: # %return
; LE-NEXT:    extsw r3, r3
; LE-NEXT:    blr
; LE-NEXT:  .LBB0_4: # %if.then2
; LE-NEXT:    addi r3, r3, -5
; LE-NEXT:    extsw r3, r3
; LE-NEXT:    blr
; LE:       .quad   __parse_hwcap_and_convert_at_platform
entry:
  %cpu_supports = tail call i32 @llvm.ppc.fixed.addr.ld(i32 2)
  %0 = and i32 %cpu_supports, 8388608
  %.not = icmp eq i32 %0, 0
  br i1 %.not, label %if.else, label %return

if.else:                                          ; preds = %entry
  %cpu_supports1 = tail call i32 @llvm.ppc.fixed.addr.ld(i32 1)
  %1 = and i32 %cpu_supports1, 67108864
  %.not12 = icmp eq i32 %1, 0
  br i1 %.not12, label %if.else3, label %if.then2

if.then2:                                         ; preds = %if.else
  %sub = add nsw i32 %a, -5
  br label %return

if.else3:                                         ; preds = %if.else
  %cpu_is = tail call i32 @llvm.ppc.fixed.addr.ld(i32 3)
  %2 = icmp eq i32 %cpu_is, 39
  br i1 %2, label %if.then4, label %if.end6

if.then4:                                         ; preds = %if.else3
  %add = shl nsw i32 %a, 1
  br label %return

if.end6:                                          ; preds = %if.else3
  %add7 = add nsw i32 %a, 5
  br label %return

return:                                           ; preds = %entry, %if.end6, %if.then4, %if.then2
  %retval.0 = phi i32 [ %sub, %if.then2 ], [ %add, %if.then4 ], [ %add7, %if.end6 ], [ %a, %entry ]
  ret i32 %retval.0
}

declare i32 @llvm.ppc.fixed.addr.ld(i32 immarg) #1