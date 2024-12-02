; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt < %s -passes=sccp -S | FileCheck %s

; Test that SCCP has basic knowledge of when and/or/mul nuke overdefined values.

 define i32 @test(i32 %X) {
; CHECK-LABEL: @test(
; CHECK-NEXT:    ret i32 0
;
  %Y = and i32 %X, 0
  ret i32 %Y
}

define i32 @test2(i32 %X) {
; CHECK-LABEL: @test2(
; CHECK-NEXT:    ret i32 -1
;
  %Y = or i32 -1, %X
  ret i32 %Y
}

define i32 @test3(i32 %X) {
; CHECK-LABEL: @test3(
; CHECK-NEXT:    [[Y:%.*]] = and i32 undef, [[X:%.*]]
; CHECK-NEXT:    ret i32 [[Y]]
;
  %Y = and i32 undef, %X
  ret i32 %Y
}

define i32 @test4(i32 %X) {
; CHECK-LABEL: @test4(
; CHECK-NEXT:    [[Y:%.*]] = or i32 [[X:%.*]], undef
; CHECK-NEXT:    ret i32 [[Y]]
;
  %Y = or i32 %X, undef
  ret i32 %Y
}

; X * 0 = 0 even if X is overdefined.
define i32 @test5(i32 %foo) {
; CHECK-LABEL: @test5(
; CHECK-NEXT:    ret i32 0
;
  %patatino = mul i32 %foo, 0
  ret i32 %patatino
}