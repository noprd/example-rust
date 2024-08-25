// ----------------------------------------------------------------
// IMPORTS
// ----------------------------------------------------------------

use crate::core::utils;

// ----------------------------------------------------------------
// METHODS
// ----------------------------------------------------------------

// // Note this useful idiom: importing names from outer (for mod tests) scope.
// use super::*;

#[test]
fn test_two_digits() {
    assert_eq!(utils::two_digits(1, 2), 12);
    assert_eq!(utils::two_digits(5, 1), 51);
    assert_eq!(utils::two_digits(5, 31), 81);
}

#[test]
fn test_two_digits_border_cases() {
    assert_eq!(utils::two_digits(0, 8), 8);
    assert_eq!(utils::two_digits(8, 0), 80);
}
