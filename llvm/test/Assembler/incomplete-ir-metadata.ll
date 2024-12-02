; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --version 4
; RUN: opt -S -allow-incomplete-ir < %s | FileCheck %s

@g = global i8 0, !exclude !4

define void @test(ptr %p) !dbg !3 {
; CHECK-LABEL: define void @test(
; CHECK-SAME: ptr [[P:%.*]]) {
; CHECK-NEXT:    [[V1:%.*]] = load i8, ptr [[P]], align 1
; CHECK-NEXT:    [[V2:%.*]] = load i8, ptr [[P]], align 1
; CHECK-NEXT:    [[V3:%.*]] = load i8, ptr [[P]], align 1, !noalias [[META0:![0-9]+]]
; CHECK-NEXT:    call void @llvm.experimental.noalias.scope.decl(metadata [[META0]])
; CHECK-NEXT:    ret void
;
  %v1 = load i8, ptr %p, !noalias !0
  %v2 = load i8, ptr %p, !tbaa !1
  %v3 = load i8, ptr %p, !dbg !2, !noalias !100
  call void @llvm.experimental.noalias.scope.decl(metadata !5)
  call void @llvm.dbg.value(metadata i32 0, metadata !7, metadata !8)
  call void @llvm.experimental.noalias.scope.decl(metadata !100)
  ret void
}

declare void @llvm.experimental.noalias.scope.decl(metadata)
declare void @llvm.dbg.value(metadata, metadata, metadata)

!100 = !{!101}
!101 = !{!101, !102}
!102 = !{!102}
;.
; CHECK: [[META0]] = !{[[META1:![0-9]+]]}
; CHECK: [[META1]] = distinct !{[[META1]], [[META2:![0-9]+]]}
; CHECK: [[META2]] = distinct !{[[META2]]}
;.