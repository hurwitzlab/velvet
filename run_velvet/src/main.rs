extern crate run_velvet;
use std::process;

fn main() {
    let config = match run_velvet::get_args() {
        Ok(c) => c,
        Err(e) => {
            println!("Error: {}", e);
            process::exit(1);
        }
    };

    if let Err(e) = run_velvet::run(config) {
        println!("Error: {}", e);
        process::exit(1);
    }
}
