(module
  (import "imports" "imported_func" (func $imported_func (param $lhs i64) (param $rhs i32) (result i32)))
  (func (export "exported_func") (result i32)
    (local i32)
    i64.const 42
    i32.const -3333
    (local.set 0 (call $imported_func)
    (local.get 0))))
