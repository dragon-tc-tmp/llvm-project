; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt %s -instcombine -S | FileCheck %s

; If we have some pattern that leaves only some low bits set, and then performs
; left-shift of those bits, we can combine those two shifts into a shift+mask.

; There are many variants to this pattern:
;   c)  (x & (-1 >> maskNbits)) << shiftNbits
; simplify to:
;   (x << shiftNbits) & (-1 >> ((-(maskNbits+shiftNbits))+32))

; Simple tests.

declare void @use32(i32)

define i32 @t0_basic(i32 %x, i32 %nbits) {
; CHECK-LABEL: @t0_basic(
; CHECK-NEXT:    [[T0:%.*]] = lshr i32 -1, [[NBITS:%.*]]
; CHECK-NEXT:    [[T2:%.*]] = add i32 [[NBITS]], -1
; CHECK-NEXT:    call void @use32(i32 [[T0]])
; CHECK-NEXT:    call void @use32(i32 [[T2]])
; CHECK-NEXT:    [[TMP1:%.*]] = shl i32 [[X:%.*]], [[T2]]
; CHECK-NEXT:    [[T3:%.*]] = and i32 [[TMP1]], 2147483647
; CHECK-NEXT:    ret i32 [[T3]]
;
  %t0 = lshr i32 -1, %nbits
  %t1 = and i32 %t0, %x
  %t2 = add i32 %nbits, -1
  call void @use32(i32 %t0)
  call void @use32(i32 %t2)
  %t3 = shl i32 %t1, %t2 ; shift is smaller than mask
  ret i32 %t3
}

; Vectors

declare void @use8xi32(<8 x i32>)

define <8 x i32> @t1_vec_splat(<8 x i32> %x, <8 x i32> %nbits) {
; CHECK-LABEL: @t1_vec_splat(
; CHECK-NEXT:    [[T0:%.*]] = lshr <8 x i32> <i32 -1, i32 -1, i32 -1, i32 -1, i32 -1, i32 -1, i32 -1, i32 -1>, [[NBITS:%.*]]
; CHECK-NEXT:    [[T2:%.*]] = add <8 x i32> [[NBITS]], <i32 -1, i32 -1, i32 -1, i32 -1, i32 -1, i32 -1, i32 -1, i32 -1>
; CHECK-NEXT:    call void @use8xi32(<8 x i32> [[T0]])
; CHECK-NEXT:    call void @use8xi32(<8 x i32> [[T2]])
; CHECK-NEXT:    [[TMP1:%.*]] = shl <8 x i32> [[X:%.*]], [[T2]]
; CHECK-NEXT:    [[T3:%.*]] = and <8 x i32> [[TMP1]], <i32 2147483647, i32 2147483647, i32 2147483647, i32 2147483647, i32 2147483647, i32 2147483647, i32 2147483647, i32 2147483647>
; CHECK-NEXT:    ret <8 x i32> [[T3]]
;
  %t0 = lshr <8 x i32> <i32 -1, i32 -1, i32 -1, i32 -1, i32 -1, i32 -1, i32 -1, i32 -1>, %nbits
  %t1 = and <8 x i32> %t0, %x
  %t2 = add <8 x i32> %nbits, <i32 -1, i32 -1, i32 -1, i32 -1, i32 -1, i32 -1, i32 -1, i32 -1>
  call void @use8xi32(<8 x i32> %t0)
  call void @use8xi32(<8 x i32> %t2)
  %t3 = shl <8 x i32> %t1, %t2 ; shift is smaller than mask
  ret <8 x i32> %t3
}

define <8 x i32> @t1_vec_nonsplat(<8 x i32> %x, <8 x i32> %nbits) {
; CHECK-LABEL: @t1_vec_nonsplat(
; CHECK-NEXT:    [[T0:%.*]] = lshr <8 x i32> <i32 -1, i32 -1, i32 -1, i32 -1, i32 -1, i32 -1, i32 -1, i32 -1>, [[NBITS:%.*]]
; CHECK-NEXT:    [[T2:%.*]] = add <8 x i32> [[NBITS]], <i32 -32, i32 -31, i32 -1, i32 0, i32 1, i32 31, i32 32, i32 33>
; CHECK-NEXT:    call void @use8xi32(<8 x i32> [[T0]])
; CHECK-NEXT:    call void @use8xi32(<8 x i32> [[T2]])
; CHECK-NEXT:    [[TMP1:%.*]] = shl <8 x i32> [[X:%.*]], [[T2]]
; CHECK-NEXT:    [[T3:%.*]] = and <8 x i32> [[TMP1]], <i32 undef, i32 1, i32 2147483647, i32 -1, i32 -1, i32 -1, i32 -1, i32 undef>
; CHECK-NEXT:    ret <8 x i32> [[T3]]
;
  %t0 = lshr <8 x i32> <i32 -1, i32 -1, i32 -1, i32 -1, i32 -1, i32 -1, i32 -1, i32 -1>, %nbits
  %t1 = and <8 x i32> %t0, %x
  %t2 = add <8 x i32> %nbits, <i32 -32, i32 -31, i32 -1, i32 0, i32 1, i32 31, i32 32, i32 33>
  call void @use8xi32(<8 x i32> %t0)
  call void @use8xi32(<8 x i32> %t2)
  %t3 = shl <8 x i32> %t1, %t2 ; shift is smaller than mask
  ret <8 x i32> %t3
}

; Extra uses.

define i32 @n3_extrause(i32 %x, i32 %nbits) {
; CHECK-LABEL: @n3_extrause(
; CHECK-NEXT:    [[T0:%.*]] = lshr i32 -1, [[NBITS:%.*]]
; CHECK-NEXT:    [[T1:%.*]] = and i32 [[T0]], [[X:%.*]]
; CHECK-NEXT:    [[T2:%.*]] = add i32 [[NBITS]], -1
; CHECK-NEXT:    call void @use32(i32 [[T0]])
; CHECK-NEXT:    call void @use32(i32 [[T1]])
; CHECK-NEXT:    call void @use32(i32 [[T2]])
; CHECK-NEXT:    [[T3:%.*]] = shl i32 [[T1]], [[T2]]
; CHECK-NEXT:    ret i32 [[T3]]
;
  %t0 = lshr i32 -1, %nbits
  %t1 = and i32 %t0, %x
  %t2 = add i32 %nbits, -1
  call void @use32(i32 %t0)
  call void @use32(i32 %t1) ; BAD
  call void @use32(i32 %t2)
  %t3 = shl i32 %t1, %t2 ; shift is smaller than mask
  ret i32 %t3
}
