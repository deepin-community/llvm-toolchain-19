; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --version 4
; RUN: opt --passes=slp-vectorizer -S -mtriple=x86_64-unknown-linux-gnu -mcpu=cascadelake < %s | FileCheck %s

define void @test() {
; CHECK-LABEL: define void @test(
; CHECK-SAME: ) #[[ATTR0:[0-9]+]] {
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[TMP0:%.*]] = call <2 x i2> @llvm.smin.v2i2(<2 x i2> zeroinitializer, <2 x i2> zeroinitializer)
; CHECK-NEXT:    [[TMP1:%.*]] = select <2 x i1> zeroinitializer, <2 x i2> zeroinitializer, <2 x i2> [[TMP0]]
; CHECK-NEXT:    [[TMP2:%.*]] = or <2 x i2> [[TMP1]], zeroinitializer
; CHECK-NEXT:    [[TMP3:%.*]] = extractelement <2 x i2> [[TMP2]], i32 1
; CHECK-NEXT:    [[ADD:%.*]] = zext i2 [[TMP3]] to i32
; CHECK-NEXT:    [[SHR:%.*]] = ashr i32 [[ADD]], 0
; CHECK-NEXT:    [[TMP5:%.*]] = extractelement <2 x i2> [[TMP2]], i32 0
; CHECK-NEXT:    [[ADD45:%.*]] = zext i2 [[TMP5]] to i32
; CHECK-NEXT:    [[ADD152:%.*]] = or i32 [[ADD45]], [[ADD]]
; CHECK-NEXT:    [[IDXPROM153:%.*]] = sext i32 [[ADD152]] to i64
; CHECK-NEXT:    [[ARRAYIDX154:%.*]] = getelementptr i8, ptr null, i64 [[IDXPROM153]]
; CHECK-NEXT:    [[CALL155:%.*]] = tail call i32 null(ptr null, i32 0, ptr [[ARRAYIDX154]], i32 0)
; CHECK-NEXT:    ret void
;
entry:
  %conv = sext i16 0 to i32
  %cmp.i = icmp sgt i32 0, %conv
  %cond.i = tail call i32 @llvm.smin.i32(i32 %conv, i32 0)
  %cond5.i = select i1 %cmp.i, i32 0, i32 %cond.i
  %conv43 = sext i16 0 to i32
  %cmp.i6193 = icmp sgt i32 0, %conv43
  %cond.i6194 = tail call i32 @llvm.smin.i32(i32 %conv43, i32 0)
  %cond5.i6195 = select i1 %cmp.i6193, i32 0, i32 %cond.i6194
  %add = or i32 %cond5.i, 0
  %shr = ashr i32 %add, 0
  %add45 = or i32 %cond5.i6195, 0
  %add152 = or i32 %add45, %add
  %idxprom153 = sext i32 %add152 to i64
  %arrayidx154 = getelementptr i8, ptr null, i64 %idxprom153
  %call155 = tail call i32 null(ptr null, i32 0, ptr %arrayidx154, i32 0)
  ret void
}

declare i32 @llvm.smin.i32(i32, i32)
