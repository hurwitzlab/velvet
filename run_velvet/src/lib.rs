extern crate clap;

use clap::{App, Arg};
use std::{
    env, error::Error, fs::{self, DirBuilder}, path::PathBuf,
};

#[derive(Debug)]
pub struct Config {
    query: Vec<String>,
    out_dir: PathBuf,
}

type MyResult<T> = Result<T, Box<Error>>;

// --------------------------------------------------
pub fn get_args() -> MyResult<Config> {
    let matches = App::new("run_velvet")
        .version("0.1.0")
        .author("Ken Youens-Clark <kyclark@email.arizona.edu>")
        .about("runs velvet")
        .arg(
            Arg::with_name("query")
                .short("q")
                .long("query")
                .value_name("FILE_OR_DIR")
                .help("File input or directory")
                .required(true)
                .min_values(1),
        )
        .arg(
            Arg::with_name("out_dir")
                .short("o")
                .long("out_dir")
                .value_name("DIR")
                .help("Output directory"),
        )
        .get_matches();

    let out_dir = match matches.value_of("out_dir") {
        Some(x) => PathBuf::from(x),
        _ => {
            let cwd = env::current_dir()?;
            cwd.join(PathBuf::from("velvet-out"))
        }
    };

    Ok(Config {
        query: matches.values_of_lossy("query").unwrap(),
        out_dir: out_dir,
    })
}

// --------------------------------------------------
pub fn run(config: Config) -> MyResult<()> {
    let files = find_files(&config.query)?;

    if files.len() == 0 {
        let msg = format!("No input files from query \"{:?}\"", &config.query);
        return Err(From::from(msg));
    }

    println!(
        "Will process {} file{}",
        files.len(),
        if files.len() == 1 { "" } else { "s" }
    );

    let out_dir = &config.out_dir;
    if !out_dir.is_dir() {
        DirBuilder::new().recursive(true).create(&out_dir)?;
    }

    let velvet_dir = run_velveth(&config, &files)?;

    println!("Done, see {:?}", velvet_dir);
    Ok(())
}

// --------------------------------------------------
fn run_velveth(config: &Config, files: &Vec<String>) -> MyResult<PathBuf> {
    let dir = config.out_dir.join("velveth");

    Ok(dir)
}

// --------------------------------------------------
fn find_files(paths: &Vec<String>) -> Result<Vec<String>, Box<Error>> {
    let mut files = vec![];
    for path in paths {
        let meta = fs::metadata(path)?;
        if meta.is_file() {
            files.push(path.to_owned());
        } else {
            for entry in fs::read_dir(path)? {
                let entry = entry?;
                let meta = entry.metadata()?;
                if meta.is_file() {
                    files.push(entry.path().display().to_string());
                }
            }
        };
    }

    if files.len() == 0 {
        return Err(From::from("No input files"));
    }

    Ok(files)
}
