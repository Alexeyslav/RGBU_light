.macro set_bit
  SET
  BLD   @0,@1
.endmacro

.macro clear_bit
  CLT
  BLD   @0,@1
.endmacro

.macro test_bit
  BST   @0,@1
.endmacro

.macro go_if_set
 BST    @0,@1
 BRTS   @2
.endmacro

.macro go_if_clear
 BST    @0,@1
 BRTC   @2
.endmacro

.macro set_io  ; ������������ ������� ACCUM ��� �������� ��������� � ����
  LDI   ACCUM,  @1    ; 1 ����
  OUT   @0,      ACCUM ; 1 ����
.endmacro

.macro set_reg
  LDI   ACCUM,  @1
  MOV   @0,     ACCUM
.endmacro