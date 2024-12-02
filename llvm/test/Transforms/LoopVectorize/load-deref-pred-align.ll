; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt -passes=loop-vectorize -force-vector-width=2 -force-vector-interleave=1 -S %s | FileCheck %s

target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128-ni:1-p:16:16:16:16"

declare void @init(ptr nocapture nofree)

; Test case where the predicated load in the loop has an access size of 2 but
; has an alignment of 4.
define i16 @test_access_size_not_multiple_of_align(i64 %len, ptr %test_base) {
; CHECK-LABEL: @test_access_size_not_multiple_of_align(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[ALLOCA:%.*]] = alloca [163840 x i16], align 4
; CHECK-NEXT:    call void @init(ptr [[ALLOCA]])
; CHECK-NEXT:    br i1 false, label [[SCALAR_PH:%.*]], label [[VECTOR_PH:%.*]]
; CHECK:       vector.ph:
; CHECK-NEXT:    br label [[VECTOR_BODY:%.*]]
; CHECK:       vector.body:
; CHECK-NEXT:    [[INDEX:%.*]] = phi i64 [ 0, [[VECTOR_PH]] ], [ [[INDEX_NEXT:%.*]], [[PRED_LOAD_CONTINUE2:%.*]] ]
; CHECK-NEXT:    [[VEC_PHI:%.*]] = phi <2 x i16> [ zeroinitializer, [[VECTOR_PH]] ], [ [[TMP15:%.*]], [[PRED_LOAD_CONTINUE2]] ]
; CHECK-NEXT:    [[TMP0:%.*]] = add i64 [[INDEX]], 0
; CHECK-NEXT:    [[TMP1:%.*]] = getelementptr inbounds i8, ptr [[TEST_BASE:%.*]], i64 [[TMP0]]
; CHECK-NEXT:    [[TMP2:%.*]] = getelementptr inbounds i8, ptr [[TMP1]], i32 0
; CHECK-NEXT:    [[WIDE_LOAD:%.*]] = load <2 x i8>, ptr [[TMP2]], align 1
; CHECK-NEXT:    [[TMP3:%.*]] = icmp sge <2 x i8> [[WIDE_LOAD]], zeroinitializer
; CHECK-NEXT:    [[TMP4:%.*]] = extractelement <2 x i1> [[TMP3]], i32 0
; CHECK-NEXT:    br i1 [[TMP4]], label [[PRED_LOAD_IF:%.*]], label [[PRED_LOAD_CONTINUE:%.*]]
; CHECK:       pred.load.if:
; CHECK-NEXT:    [[TMP5:%.*]] = getelementptr inbounds i16, ptr [[ALLOCA]], i64 [[TMP0]]
; CHECK-NEXT:    [[TMP6:%.*]] = load i16, ptr [[TMP5]], align 4
; CHECK-NEXT:    [[TMP7:%.*]] = insertelement <2 x i16> poison, i16 [[TMP6]], i32 0
; CHECK-NEXT:    br label [[PRED_LOAD_CONTINUE]]
; CHECK:       pred.load.continue:
; CHECK-NEXT:    [[TMP8:%.*]] = phi <2 x i16> [ poison, [[VECTOR_BODY]] ], [ [[TMP7]], [[PRED_LOAD_IF]] ]
; CHECK-NEXT:    [[TMP9:%.*]] = extractelement <2 x i1> [[TMP3]], i32 1
; CHECK-NEXT:    br i1 [[TMP9]], label [[PRED_LOAD_IF1:%.*]], label [[PRED_LOAD_CONTINUE2]]
; CHECK:       pred.load.if1:
; CHECK-NEXT:    [[TMP10:%.*]] = add i64 [[INDEX]], 1
; CHECK-NEXT:    [[TMP11:%.*]] = getelementptr inbounds i16, ptr [[ALLOCA]], i64 [[TMP10]]
; CHECK-NEXT:    [[TMP12:%.*]] = load i16, ptr [[TMP11]], align 4
; CHECK-NEXT:    [[TMP13:%.*]] = insertelement <2 x i16> [[TMP8]], i16 [[TMP12]], i32 1
; CHECK-NEXT:    br label [[PRED_LOAD_CONTINUE2]]
; CHECK:       pred.load.continue2:
; CHECK-NEXT:    [[TMP14:%.*]] = phi <2 x i16> [ [[TMP8]], [[PRED_LOAD_CONTINUE]] ], [ [[TMP13]], [[PRED_LOAD_IF1]] ]
; CHECK-NEXT:    [[PREDPHI:%.*]] = select <2 x i1> [[TMP3]], <2 x i16> [[TMP14]], <2 x i16> zeroinitializer
; CHECK-NEXT:    [[TMP15]] = add <2 x i16> [[VEC_PHI]], [[PREDPHI]]
; CHECK-NEXT:    [[INDEX_NEXT]] = add nuw i64 [[INDEX]], 2
; CHECK-NEXT:    [[TMP16:%.*]] = icmp eq i64 [[INDEX_NEXT]], 4096
; CHECK-NEXT:    br i1 [[TMP16]], label [[MIDDLE_BLOCK:%.*]], label [[VECTOR_BODY]], !llvm.loop [[LOOP0:![0-9]+]]
; CHECK:       middle.block:
; CHECK-NEXT:    [[TMP17:%.*]] = call i16 @llvm.vector.reduce.add.v2i16(<2 x i16> [[TMP15]])
; CHECK-NEXT:    br i1 true, label [[LOOP_EXIT:%.*]], label [[SCALAR_PH]]
; CHECK:       scalar.ph:
; CHECK-NEXT:    [[BC_RESUME_VAL:%.*]] = phi i64 [ 4096, [[MIDDLE_BLOCK]] ], [ 0, [[ENTRY:%.*]] ]
; CHECK-NEXT:    [[BC_MERGE_RDX:%.*]] = phi i16 [ [[TMP17]], [[MIDDLE_BLOCK]] ], [ 0, [[ENTRY]] ]
; CHECK-NEXT:    br label [[LOOP:%.*]]
; CHECK:       loop:
; CHECK-NEXT:    [[IV:%.*]] = phi i64 [ [[BC_RESUME_VAL]], [[SCALAR_PH]] ], [ [[IV_NEXT:%.*]], [[LATCH:%.*]] ]
; CHECK-NEXT:    [[ACCUM:%.*]] = phi i16 [ [[BC_MERGE_RDX]], [[SCALAR_PH]] ], [ [[ACCUM_NEXT:%.*]], [[LATCH]] ]
; CHECK-NEXT:    [[IV_NEXT]] = add i64 [[IV]], 1
; CHECK-NEXT:    [[TEST_ADDR:%.*]] = getelementptr inbounds i8, ptr [[TEST_BASE]], i64 [[IV]]
; CHECK-NEXT:    [[L_T:%.*]] = load i8, ptr [[TEST_ADDR]], align 1
; CHECK-NEXT:    [[CMP:%.*]] = icmp sge i8 [[L_T]], 0
; CHECK-NEXT:    br i1 [[CMP]], label [[PRED:%.*]], label [[LATCH]]
; CHECK:       pred:
; CHECK-NEXT:    [[ADDR:%.*]] = getelementptr inbounds i16, ptr [[ALLOCA]], i64 [[IV]]
; CHECK-NEXT:    [[VAL:%.*]] = load i16, ptr [[ADDR]], align 4
; CHECK-NEXT:    br label [[LATCH]]
; CHECK:       latch:
; CHECK-NEXT:    [[VAL_PHI:%.*]] = phi i16 [ 0, [[LOOP]] ], [ [[VAL]], [[PRED]] ]
; CHECK-NEXT:    [[ACCUM_NEXT]] = add i16 [[ACCUM]], [[VAL_PHI]]
; CHECK-NEXT:    [[EXIT:%.*]] = icmp eq i64 [[IV]], 4095
; CHECK-NEXT:    br i1 [[EXIT]], label [[LOOP_EXIT]], label [[LOOP]], !llvm.loop [[LOOP3:![0-9]+]]
; CHECK:       loop_exit:
; CHECK-NEXT:    [[ACCUM_NEXT_LCSSA:%.*]] = phi i16 [ [[ACCUM_NEXT]], [[LATCH]] ], [ [[TMP17]], [[MIDDLE_BLOCK]] ]
; CHECK-NEXT:    ret i16 [[ACCUM_NEXT_LCSSA]]
;
entry:
  %alloca = alloca [163840 x i16], align 4
  call void @init(ptr %alloca)
  br label %loop
loop:
  %iv = phi i64 [ 0, %entry ], [ %iv.next, %latch ]
  %accum = phi i16 [ 0, %entry ], [ %accum.next, %latch ]
  %iv.next = add i64 %iv, 1
  %test_addr = getelementptr inbounds i8, ptr %test_base, i64 %iv
  %l.t = load i8, ptr %test_addr
  %cmp = icmp sge i8 %l.t, 0
  br i1 %cmp, label %pred, label %latch
pred:
  %addr = getelementptr inbounds i16, ptr %alloca, i64 %iv
  %val = load i16, ptr %addr, align 4
  br label %latch
latch:
  %val.phi = phi i16 [0, %loop], [%val, %pred]
  %accum.next = add i16 %accum, %val.phi
  %exit = icmp eq i64 %iv, 4095
  br i1 %exit, label %loop_exit, label %loop

loop_exit:
  ret i16 %accum.next
}

; Test case where the predicated load in the loop has an access size of 4 and
; an alignment of 4, but the start pointer is offset by 1.
define i32 @test_access_size_multiple_of_align_but_offset_by_1(i64 %len, ptr %test_base) {
; CHECK-LABEL: @test_access_size_multiple_of_align_but_offset_by_1(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[ALLOCA:%.*]] = alloca [163840 x i32], align 4
; CHECK-NEXT:    call void @init(ptr [[ALLOCA]])
; CHECK-NEXT:    [[START:%.*]] = getelementptr i8, ptr [[ALLOCA]], i64 2
; CHECK-NEXT:    br i1 false, label [[SCALAR_PH:%.*]], label [[VECTOR_PH:%.*]]
; CHECK:       vector.ph:
; CHECK-NEXT:    br label [[VECTOR_BODY:%.*]]
; CHECK:       vector.body:
; CHECK-NEXT:    [[INDEX:%.*]] = phi i64 [ 0, [[VECTOR_PH]] ], [ [[INDEX_NEXT:%.*]], [[PRED_LOAD_CONTINUE2:%.*]] ]
; CHECK-NEXT:    [[VEC_PHI:%.*]] = phi <2 x i32> [ zeroinitializer, [[VECTOR_PH]] ], [ [[TMP15:%.*]], [[PRED_LOAD_CONTINUE2]] ]
; CHECK-NEXT:    [[TMP0:%.*]] = add i64 [[INDEX]], 0
; CHECK-NEXT:    [[TMP1:%.*]] = getelementptr inbounds i8, ptr [[TEST_BASE:%.*]], i64 [[TMP0]]
; CHECK-NEXT:    [[TMP2:%.*]] = getelementptr inbounds i8, ptr [[TMP1]], i32 0
; CHECK-NEXT:    [[WIDE_LOAD:%.*]] = load <2 x i8>, ptr [[TMP2]], align 1
; CHECK-NEXT:    [[TMP3:%.*]] = icmp sge <2 x i8> [[WIDE_LOAD]], zeroinitializer
; CHECK-NEXT:    [[TMP4:%.*]] = extractelement <2 x i1> [[TMP3]], i32 0
; CHECK-NEXT:    br i1 [[TMP4]], label [[PRED_LOAD_IF:%.*]], label [[PRED_LOAD_CONTINUE:%.*]]
; CHECK:       pred.load.if:
; CHECK-NEXT:    [[TMP5:%.*]] = getelementptr inbounds i32, ptr [[START]], i64 [[TMP0]]
; CHECK-NEXT:    [[TMP6:%.*]] = load i32, ptr [[TMP5]], align 4
; CHECK-NEXT:    [[TMP7:%.*]] = insertelement <2 x i32> poison, i32 [[TMP6]], i32 0
; CHECK-NEXT:    br label [[PRED_LOAD_CONTINUE]]
; CHECK:       pred.load.continue:
; CHECK-NEXT:    [[TMP8:%.*]] = phi <2 x i32> [ poison, [[VECTOR_BODY]] ], [ [[TMP7]], [[PRED_LOAD_IF]] ]
; CHECK-NEXT:    [[TMP9:%.*]] = extractelement <2 x i1> [[TMP3]], i32 1
; CHECK-NEXT:    br i1 [[TMP9]], label [[PRED_LOAD_IF1:%.*]], label [[PRED_LOAD_CONTINUE2]]
; CHECK:       pred.load.if1:
; CHECK-NEXT:    [[TMP10:%.*]] = add i64 [[INDEX]], 1
; CHECK-NEXT:    [[TMP11:%.*]] = getelementptr inbounds i32, ptr [[START]], i64 [[TMP10]]
; CHECK-NEXT:    [[TMP12:%.*]] = load i32, ptr [[TMP11]], align 4
; CHECK-NEXT:    [[TMP13:%.*]] = insertelement <2 x i32> [[TMP8]], i32 [[TMP12]], i32 1
; CHECK-NEXT:    br label [[PRED_LOAD_CONTINUE2]]
; CHECK:       pred.load.continue2:
; CHECK-NEXT:    [[TMP14:%.*]] = phi <2 x i32> [ [[TMP8]], [[PRED_LOAD_CONTINUE]] ], [ [[TMP13]], [[PRED_LOAD_IF1]] ]
; CHECK-NEXT:    [[PREDPHI:%.*]] = select <2 x i1> [[TMP3]], <2 x i32> [[TMP14]], <2 x i32> zeroinitializer
; CHECK-NEXT:    [[TMP15]] = add <2 x i32> [[VEC_PHI]], [[PREDPHI]]
; CHECK-NEXT:    [[INDEX_NEXT]] = add nuw i64 [[INDEX]], 2
; CHECK-NEXT:    [[TMP16:%.*]] = icmp eq i64 [[INDEX_NEXT]], 4096
; CHECK-NEXT:    br i1 [[TMP16]], label [[MIDDLE_BLOCK:%.*]], label [[VECTOR_BODY]], !llvm.loop [[LOOP4:![0-9]+]]
; CHECK:       middle.block:
; CHECK-NEXT:    [[TMP17:%.*]] = call i32 @llvm.vector.reduce.add.v2i32(<2 x i32> [[TMP15]])
; CHECK-NEXT:    br i1 true, label [[LOOP_EXIT:%.*]], label [[SCALAR_PH]]
; CHECK:       scalar.ph:
; CHECK-NEXT:    [[BC_RESUME_VAL:%.*]] = phi i64 [ 4096, [[MIDDLE_BLOCK]] ], [ 0, [[ENTRY:%.*]] ]
; CHECK-NEXT:    [[BC_MERGE_RDX:%.*]] = phi i32 [ [[TMP17]], [[MIDDLE_BLOCK]] ], [ 0, [[ENTRY]] ]
; CHECK-NEXT:    br label [[LOOP:%.*]]
; CHECK:       loop:
; CHECK-NEXT:    [[IV:%.*]] = phi i64 [ [[BC_RESUME_VAL]], [[SCALAR_PH]] ], [ [[IV_NEXT:%.*]], [[LATCH:%.*]] ]
; CHECK-NEXT:    [[ACCUM:%.*]] = phi i32 [ [[BC_MERGE_RDX]], [[SCALAR_PH]] ], [ [[ACCUM_NEXT:%.*]], [[LATCH]] ]
; CHECK-NEXT:    [[IV_NEXT]] = add i64 [[IV]], 1
; CHECK-NEXT:    [[TEST_ADDR:%.*]] = getelementptr inbounds i8, ptr [[TEST_BASE]], i64 [[IV]]
; CHECK-NEXT:    [[L_T:%.*]] = load i8, ptr [[TEST_ADDR]], align 1
; CHECK-NEXT:    [[CMP:%.*]] = icmp sge i8 [[L_T]], 0
; CHECK-NEXT:    br i1 [[CMP]], label [[PRED:%.*]], label [[LATCH]]
; CHECK:       pred:
; CHECK-NEXT:    [[ADDR:%.*]] = getelementptr inbounds i32, ptr [[START]], i64 [[IV]]
; CHECK-NEXT:    [[VAL:%.*]] = load i32, ptr [[ADDR]], align 4
; CHECK-NEXT:    br label [[LATCH]]
; CHECK:       latch:
; CHECK-NEXT:    [[VAL_PHI:%.*]] = phi i32 [ 0, [[LOOP]] ], [ [[VAL]], [[PRED]] ]
; CHECK-NEXT:    [[ACCUM_NEXT]] = add i32 [[ACCUM]], [[VAL_PHI]]
; CHECK-NEXT:    [[EXIT:%.*]] = icmp eq i64 [[IV]], 4095
; CHECK-NEXT:    br i1 [[EXIT]], label [[LOOP_EXIT]], label [[LOOP]], !llvm.loop [[LOOP5:![0-9]+]]
; CHECK:       loop_exit:
; CHECK-NEXT:    [[ACCUM_NEXT_LCSSA:%.*]] = phi i32 [ [[ACCUM_NEXT]], [[LATCH]] ], [ [[TMP17]], [[MIDDLE_BLOCK]] ]
; CHECK-NEXT:    ret i32 [[ACCUM_NEXT_LCSSA]]
;
entry:
  %alloca = alloca [163840 x i32], align 4
  call void @init(ptr %alloca)
  %start = getelementptr i8, ptr %alloca, i64 2
  br label %loop
loop:
  %iv = phi i64 [ 0, %entry ], [ %iv.next, %latch ]
  %accum = phi i32 [ 0, %entry ], [ %accum.next, %latch ]
  %iv.next = add i64 %iv, 1
  %test_addr = getelementptr inbounds i8, ptr %test_base, i64 %iv
  %l.t = load i8, ptr %test_addr
  %cmp = icmp sge i8 %l.t, 0
  br i1 %cmp, label %pred, label %latch
pred:
  %addr = getelementptr inbounds i32, ptr %start, i64 %iv
  %val = load i32, ptr %addr, align 4
  br label %latch
latch:
  %val.phi = phi i32 [0, %loop], [%val, %pred]
  %accum.next = add i32 %accum, %val.phi
  %exit = icmp eq i64 %iv, 4095
  br i1 %exit, label %loop_exit, label %loop

loop_exit:
  ret i32 %accum.next
}


; Test where offset relative to alloca is negative and we shouldn't
; treat predicated loads as being always dereferenceable.
define i8 @test_negative_off(i16 %len, ptr %test_base) {
; CHECK-LABEL: @test_negative_off(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[ALLOCA:%.*]] = alloca [64638 x i8], align 1
; CHECK-NEXT:    call void @init(ptr [[ALLOCA]])
; CHECK-NEXT:    br i1 false, label [[SCALAR_PH:%.*]], label [[VECTOR_PH:%.*]]
; CHECK:       vector.ph:
; CHECK-NEXT:    br label [[VECTOR_BODY:%.*]]
; CHECK:       vector.body:
; CHECK-NEXT:    [[INDEX:%.*]] = phi i32 [ 0, [[VECTOR_PH]] ], [ [[INDEX_NEXT:%.*]], [[PRED_LOAD_CONTINUE2:%.*]] ]
; CHECK-NEXT:    [[VEC_PHI:%.*]] = phi <2 x i8> [ zeroinitializer, [[VECTOR_PH]] ], [ [[TMP18:%.*]], [[PRED_LOAD_CONTINUE2]] ]
; CHECK-NEXT:    [[DOTCAST:%.*]] = trunc i32 [[INDEX]] to i16
; CHECK-NEXT:    [[OFFSET_IDX:%.*]] = add i16 -1000, [[DOTCAST]]
; CHECK-NEXT:    [[TMP0:%.*]] = add i16 [[OFFSET_IDX]], 0
; CHECK-NEXT:    [[TMP1:%.*]] = add i16 [[OFFSET_IDX]], 1
; CHECK-NEXT:    [[TMP2:%.*]] = getelementptr inbounds i1, ptr [[TEST_BASE:%.*]], i16 [[TMP0]]
; CHECK-NEXT:    [[TMP3:%.*]] = getelementptr inbounds i1, ptr [[TEST_BASE]], i16 [[TMP1]]
; CHECK-NEXT:    [[TMP4:%.*]] = load i1, ptr [[TMP2]], align 1
; CHECK-NEXT:    [[TMP5:%.*]] = load i1, ptr [[TMP3]], align 1
; CHECK-NEXT:    [[TMP6:%.*]] = insertelement <2 x i1> poison, i1 [[TMP4]], i32 0
; CHECK-NEXT:    [[TMP7:%.*]] = insertelement <2 x i1> [[TMP6]], i1 [[TMP5]], i32 1
; CHECK-NEXT:    [[TMP8:%.*]] = extractelement <2 x i1> [[TMP7]], i32 0
; CHECK-NEXT:    br i1 [[TMP8]], label [[PRED_LOAD_IF:%.*]], label [[PRED_LOAD_CONTINUE:%.*]]
; CHECK:       pred.load.if:
; CHECK-NEXT:    [[TMP9:%.*]] = getelementptr i8, ptr [[ALLOCA]], i16 [[TMP0]]
; CHECK-NEXT:    [[TMP10:%.*]] = load i8, ptr [[TMP9]], align 1
; CHECK-NEXT:    [[TMP11:%.*]] = insertelement <2 x i8> poison, i8 [[TMP10]], i32 0
; CHECK-NEXT:    br label [[PRED_LOAD_CONTINUE]]
; CHECK:       pred.load.continue:
; CHECK-NEXT:    [[TMP12:%.*]] = phi <2 x i8> [ poison, [[VECTOR_BODY]] ], [ [[TMP11]], [[PRED_LOAD_IF]] ]
; CHECK-NEXT:    [[TMP13:%.*]] = extractelement <2 x i1> [[TMP7]], i32 1
; CHECK-NEXT:    br i1 [[TMP13]], label [[PRED_LOAD_IF1:%.*]], label [[PRED_LOAD_CONTINUE2]]
; CHECK:       pred.load.if1:
; CHECK-NEXT:    [[TMP14:%.*]] = getelementptr i8, ptr [[ALLOCA]], i16 [[TMP1]]
; CHECK-NEXT:    [[TMP15:%.*]] = load i8, ptr [[TMP14]], align 1
; CHECK-NEXT:    [[TMP16:%.*]] = insertelement <2 x i8> [[TMP12]], i8 [[TMP15]], i32 1
; CHECK-NEXT:    br label [[PRED_LOAD_CONTINUE2]]
; CHECK:       pred.load.continue2:
; CHECK-NEXT:    [[TMP17:%.*]] = phi <2 x i8> [ [[TMP12]], [[PRED_LOAD_CONTINUE]] ], [ [[TMP16]], [[PRED_LOAD_IF1]] ]
; CHECK-NEXT:    [[PREDPHI:%.*]] = select <2 x i1> [[TMP7]], <2 x i8> [[TMP17]], <2 x i8> zeroinitializer
; CHECK-NEXT:    [[TMP18]] = add <2 x i8> [[VEC_PHI]], [[PREDPHI]]
; CHECK-NEXT:    [[INDEX_NEXT]] = add nuw i32 [[INDEX]], 2
; CHECK-NEXT:    [[TMP19:%.*]] = icmp eq i32 [[INDEX_NEXT]], 12
; CHECK-NEXT:    br i1 [[TMP19]], label [[MIDDLE_BLOCK:%.*]], label [[VECTOR_BODY]], !llvm.loop [[LOOP6:![0-9]+]]
; CHECK:       middle.block:
; CHECK-NEXT:    [[TMP20:%.*]] = call i8 @llvm.vector.reduce.add.v2i8(<2 x i8> [[TMP18]])
; CHECK-NEXT:    br i1 true, label [[LOOP_EXIT:%.*]], label [[SCALAR_PH]]
; CHECK:       scalar.ph:
; CHECK-NEXT:    [[BC_RESUME_VAL:%.*]] = phi i16 [ -988, [[MIDDLE_BLOCK]] ], [ -1000, [[ENTRY:%.*]] ]
; CHECK-NEXT:    [[BC_MERGE_RDX:%.*]] = phi i8 [ [[TMP20]], [[MIDDLE_BLOCK]] ], [ 0, [[ENTRY]] ]
; CHECK-NEXT:    br label [[LOOP:%.*]]
; CHECK:       loop:
; CHECK-NEXT:    [[IV:%.*]] = phi i16 [ [[BC_RESUME_VAL]], [[SCALAR_PH]] ], [ [[IV_NEXT:%.*]], [[LATCH:%.*]] ]
; CHECK-NEXT:    [[ACCUM:%.*]] = phi i8 [ [[BC_MERGE_RDX]], [[SCALAR_PH]] ], [ [[ACCUM_NEXT:%.*]], [[LATCH]] ]
; CHECK-NEXT:    [[IV_NEXT]] = add i16 [[IV]], 1
; CHECK-NEXT:    [[TEST_ADDR:%.*]] = getelementptr inbounds i1, ptr [[TEST_BASE]], i16 [[IV]]
; CHECK-NEXT:    [[EARLYCND:%.*]] = load i1, ptr [[TEST_ADDR]], align 1
; CHECK-NEXT:    br i1 [[EARLYCND]], label [[PRED:%.*]], label [[LATCH]]
; CHECK:       pred:
; CHECK-NEXT:    [[ADDR:%.*]] = getelementptr i8, ptr [[ALLOCA]], i16 [[IV]]
; CHECK-NEXT:    [[VAL:%.*]] = load i8, ptr [[ADDR]], align 1
; CHECK-NEXT:    br label [[LATCH]]
; CHECK:       latch:
; CHECK-NEXT:    [[VAL_PHI:%.*]] = phi i8 [ 0, [[LOOP]] ], [ [[VAL]], [[PRED]] ]
; CHECK-NEXT:    [[ACCUM_NEXT]] = add i8 [[ACCUM]], [[VAL_PHI]]
; CHECK-NEXT:    [[EXIT:%.*]] = icmp ugt i16 [[IV]], -990
; CHECK-NEXT:    br i1 [[EXIT]], label [[LOOP_EXIT]], label [[LOOP]], !llvm.loop [[LOOP7:![0-9]+]]
; CHECK:       loop_exit:
; CHECK-NEXT:    [[ACCUM_NEXT_LCSSA:%.*]] = phi i8 [ [[ACCUM_NEXT]], [[LATCH]] ], [ [[TMP20]], [[MIDDLE_BLOCK]] ]
; CHECK-NEXT:    ret i8 [[ACCUM_NEXT_LCSSA]]
;
entry:
  %alloca = alloca [64638 x i8]
  call void @init(ptr %alloca)
  br label %loop
loop:
  %iv = phi i16 [ -1000, %entry ], [ %iv.next, %latch ]
  %accum = phi i8 [ 0, %entry ], [ %accum.next, %latch ]
  %iv.next = add i16 %iv, 1
  %test_addr = getelementptr inbounds i1, ptr %test_base, i16 %iv
  %earlycnd = load i1, ptr %test_addr
  br i1 %earlycnd, label %pred, label %latch
pred:
  %addr = getelementptr i8, ptr %alloca, i16 %iv
  %val = load i8, ptr %addr
  br label %latch
latch:
  %val.phi = phi i8 [ 0, %loop ], [ %val, %pred ]
  %accum.next = add i8 %accum, %val.phi
  %exit = icmp ugt i16 %iv, -990
  br i1 %exit, label %loop_exit, label %loop
loop_exit:
  ret i8 %accum.next
}