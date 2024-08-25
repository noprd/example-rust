// ----------------------------------------------------------------
// IMPORTS
// ----------------------------------------------------------------

use actix_web::get;
use actix_web::http::header::ContentType;
use actix_web::middleware::Logger;
use actix_web::post;
use actix_web::web;
use actix_web::App;
use actix_web::HttpResponse;
use actix_web::HttpServer;
use actix_web::Responder;
use serde::Deserialize;

pub mod core;
pub mod environment;
use environment::http as env_http;

// ----------------------------------------------------------------
// MAIN
// ----------------------------------------------------------------

/// Entry method
#[tokio::main]
async fn main() -> std::io::Result<()> {
    dotenv::dotenv().ok();

    env_logger::init_from_env(env_logger::Env::new().default_filter_or("info"));

    let ip = env_http::get_ip();
    let port = env_http::get_port();
    let result = HttpServer::new(|| {
        App::new()
            .wrap(Logger::default())
            .wrap(Logger::new("%a %{User-Agent}i"))
            .service(endpoint_ping)
            .service(endpoint_token)
    })
    .bind((ip, port))?
    .run()
    .await;

    return result;
}

// ----------------------------------------------------------------
// ENDPOINTS
// ----------------------------------------------------------------

#[get("/api/ping")]
async fn endpoint_ping() -> impl Responder {
    return HttpResponse::Ok()
        .content_type(ContentType::plaintext())
        .body("success");
}

#[post("/api/token")]
async fn endpoint_token(text: web::Json<Text>) -> impl Responder {
    let hash = hash_to_sha(&text.text);
    let payload = Hash { hash };
    return HttpResponse::Ok()
        .content_type(ContentType::json())
        .json(payload);
}

// ----------------------------------------------------------------
// MODELS
// ----------------------------------------------------------------

/// used to deserialise JSON payload
#[derive(Deserialize)]
struct Text {
    text: String,
}

/// for serialisation of response using serde and hash as the key
#[derive(serde::Serialize)]
struct Hash {
    hash: String,
}

// ----------------------------------------------------------------
// METHODS
// ----------------------------------------------------------------

/// computes sha256 hash of the string
fn hash_to_sha(text: &str) -> String {
    use sha2::{Digest, Sha256};
    let mut hasher = Sha256::new();
    hasher.update(text);
    let result = hasher.finalize();
    return format!("{:x}", result);
}
