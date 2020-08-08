(module
  (import "imports" "imported_add_func" (func $imported_add_func (param $lhs i64) (param $rhs i32) (result i32)))
  (func (export "integer_provider_func") (result i32)
    (local i32)
    i64.const 42
    i32.const -3333
    (call $imported_add_func)))
