// ----------------------------------------------------------------
// IMPORTS
// ----------------------------------------------------------------

use dotenv;

// ----------------------------------------------------------------
// METHODS
// ----------------------------------------------------------------

pub fn load_env() {
    dotenv::dotenv().ok();
}

pub fn get_ip() -> String {
    load_env();
    let ip: String = match dotenv::var("HTTP_IP") {
        Ok(val) => val,
        Err(_) => String::from("127.0.0.1"),
    };
    return ip;
}

pub fn get_port() -> u16 {
    load_env();
    let port: u16 = match dotenv::var("HTTP_PORT") {
        Ok(val) => val.parse().expect("Custom Handler port is not a number!"),
        Err(_) => 8000,
    };
    return port;
}
