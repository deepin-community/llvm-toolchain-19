; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt -passes='debugify,memcpyopt,check-debugify' -S < %s 2>&1 -verify-memoryssa | FileCheck %s
; RUN: opt -passes='debugify,memcpyopt,check-debugify' -S < %s 2>&1 -verify-memoryssa --try-experimental-debuginfo-iterators | FileCheck %s

; CHECK: CheckModuleDebugify: PASS

%struct.Foo = type { i64, i64, i64 }

@a = dso_local global ptr null, align 8

define dso_local void @_Z3bar3Foo(ptr byval(%struct.Foo) align 8 %0) {
; CHECK-LABEL: @_Z3bar3Foo(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[AGG_TMP:%.*]] = alloca [[STRUCT_FOO:%.*]], align 8, !dbg [[DBG12:![0-9]+]]
; CHECK-NEXT:      #dbg_value(ptr [[AGG_TMP]], [[META9:![0-9]+]], !DIExpression(), [[DBG12]])
; CHECK-NEXT:    [[TMP1:%.*]] = load ptr, ptr @a, align 8, !dbg [[DBG13:![0-9]+]]
; CHECK-NEXT:      #dbg_value(ptr [[TMP1]], [[META11:![0-9]+]], !DIExpression(), [[DBG13]])
; CHECK-NEXT:    call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) [[AGG_TMP]], ptr nonnull align 8 dereferenceable(24) [[TMP1]], i64 24, i1 false), !dbg [[DBG14:![0-9]+]]
; CHECK-NEXT:    call void @_Z3bar3Foo(ptr nonnull byval([[STRUCT_FOO]]) align 8 [[TMP1]]), !dbg [[DBG15:![0-9]+]]
; CHECK-NEXT:    ret void, !dbg [[DBG16:![0-9]+]]
;
entry:
  %agg.tmp = alloca %struct.Foo, align 8
  %1 = load ptr, ptr @a, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %agg.tmp, ptr nonnull align 8 dereferenceable(24) %1, i64 24, i1 false)
  call void @_Z3bar3Foo(ptr nonnull byval(%struct.Foo) align 8 %agg.tmp)
  ret void
}

declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #0