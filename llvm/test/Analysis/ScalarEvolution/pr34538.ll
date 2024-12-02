; NOTE: Assertions have been autogenerated by utils/update_analyze_test_checks.py UTC_ARGS: --version 4
; RUN: opt -disable-output "-passes=print<scalar-evolution>"  -scalar-evolution-classify-expressions=0 < %s 2>&1 | FileCheck %s

define i32 @pr34538() local_unnamed_addr #0 {
; CHECK-LABEL: 'pr34538'
; CHECK-NEXT:  Determining loop execution counts for: @pr34538
; CHECK-NEXT:  Loop %do.body: backedge-taken count is i32 10000
; CHECK-NEXT:  Loop %do.body: constant max backedge-taken count is i32 10000
; CHECK-NEXT:  Loop %do.body: symbolic max backedge-taken count is i32 10000
; CHECK-NEXT:  Loop %do.body: Trip multiple is 10001
;
entry:
  br label %do.body

do.body:                                          ; preds = %do.body, %entry
  %start.0 = phi i32 [ 0, %entry ], [ %inc.start.0, %do.body ]
  %cmp = icmp slt i32 %start.0, 10000
  %inc = zext i1 %cmp to i32
  %inc.start.0 = add nsw i32 %start.0, %inc
  br i1 %cmp, label %do.body, label %do.end

do.end:                                           ; preds = %do.body
  ret i32 0
}


define i32 @foo() {
; CHECK-LABEL: 'foo'
; CHECK-NEXT:  Determining loop execution counts for: @foo
; CHECK-NEXT:  Loop %do.body: backedge-taken count is i32 5000
; CHECK-NEXT:  Loop %do.body: constant max backedge-taken count is i32 5000
; CHECK-NEXT:  Loop %do.body: symbolic max backedge-taken count is i32 5000
; CHECK-NEXT:  Loop %do.body: Trip multiple is 5001
;
entry:
  br label %do.body

do.body:                                          ; preds = %do.body, %entry
  %start.0 = phi i32 [ 0, %entry ], [ %inc.start.0, %do.body ]
  %cmp = icmp slt i32 %start.0, 10000
  %select_ext = select i1 %cmp, i32 2 , i32 1
  %inc.start.0 = add nsw i32 %start.0, %select_ext
  br i1 %cmp, label %do.body, label %do.end

do.end:                                           ; preds = %do.body
  ret i32 0
}