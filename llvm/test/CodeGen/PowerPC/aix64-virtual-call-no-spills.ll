; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -O0 -mtriple=powerpc64-ibm-aix-xcoff -mcpu=pwr10  < %s | \
; RUN: FileCheck --check-prefix=CHECK %s
; RUN: llc -O0 -mtriple=powerpc64-ibm-aix-xcoff -mcpu=pwr10 -vec-extabi < %s | \
; RUN: FileCheck --check-prefix=CHECK-VEXT %s

define dso_local noundef signext i32 @virtualCall(ptr noundef %b) #0 {
; CHECK-LABEL: virtualCall:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    mflr 0
; CHECK-NEXT:    std 0, 16(1)
; CHECK-NEXT:    stdu 1, -128(1)
; CHECK-NEXT:    std 3, 120(1)
; CHECK-NEXT:    ld 3, 120(1)
; CHECK-NEXT:    ld 4, 0(3)
; CHECK-NEXT:    ld 4, 0(4)
; CHECK-NEXT:    mr 5, 2
; CHECK-NEXT:    std 5, 40(1)
; CHECK-NEXT:    ld 5, 8(4)
; CHECK-NEXT:    ld 11, 16(4)
; CHECK-NEXT:    ld 4, 0(4)
; CHECK-NEXT:    mr 2, 5
; CHECK-NEXT:    mtctr 4
; CHECK-NEXT:    bctrl
; CHECK-NEXT:    ld 2, 40(1)
; CHECK-NEXT:    # kill: def $r3 killed $r3 killed $x3
; CHECK-NEXT:    extsw 3, 3
; CHECK-NEXT:    addi 1, 1, 128
; CHECK-NEXT:    ld 0, 16(1)
; CHECK-NEXT:    mtlr 0
; CHECK-NEXT:    blr
;
; CHECK-VEXT-LABEL: virtualCall:
; CHECK-VEXT:       # %bb.0: # %entry
; CHECK-VEXT-NEXT:    mflr 0
; CHECK-VEXT-NEXT:    std 0, 16(1)
; CHECK-VEXT-NEXT:    stdu 1, -128(1)
; CHECK-VEXT-NEXT:    std 3, 120(1)
; CHECK-VEXT-NEXT:    ld 3, 120(1)
; CHECK-VEXT-NEXT:    ld 4, 0(3)
; CHECK-VEXT-NEXT:    ld 4, 0(4)
; CHECK-VEXT-NEXT:    mr 5, 2
; CHECK-VEXT-NEXT:    std 5, 40(1)
; CHECK-VEXT-NEXT:    ld 5, 8(4)
; CHECK-VEXT-NEXT:    ld 11, 16(4)
; CHECK-VEXT-NEXT:    ld 4, 0(4)
; CHECK-VEXT-NEXT:    mr 2, 5
; CHECK-VEXT-NEXT:    mtctr 4
; CHECK-VEXT-NEXT:    bctrl
; CHECK-VEXT-NEXT:    ld 2, 40(1)
; CHECK-VEXT-NEXT:    # kill: def $r3 killed $r3 killed $x3
; CHECK-VEXT-NEXT:    extsw 3, 3
; CHECK-VEXT-NEXT:    addi 1, 1, 128
; CHECK-VEXT-NEXT:    ld 0, 16(1)
; CHECK-VEXT-NEXT:    mtlr 0
; CHECK-VEXT-NEXT:    blr
entry:
  %b.addr = alloca ptr, align 8
  store ptr %b, ptr %b.addr, align 8
  %0 = load ptr, ptr %b.addr, align 8
  %vtable = load ptr, ptr %0, align 8
  %1 = load ptr, ptr %vtable, align 8
  %call = call noundef signext i32 %1(ptr noundef nonnull align 8 dereferenceable(8) %0)
  ret i32 %call
}