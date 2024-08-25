// ----------------------------------------------------------------
// IMPORTS
// ----------------------------------------------------------------

// extern crate package;

// use package::path::to::external::module;

// use crate::path::to::local::file;

// ----------------------------------------------------------------
// METHODS
// ----------------------------------------------------------------

pub fn greet_message(name: &String) -> String {
    let message: String;
    message = format!("Hello {}!", name);
    return message;
}

pub fn two_digits(x: i8, y: i8) -> i8 {
    return 10 * x + y;
}
