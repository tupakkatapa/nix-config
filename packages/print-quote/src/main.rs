use clap::{Arg, Command};
use serde_json::Value;
use rand::seq::SliceRandom;

fn main() {
    let args = cli().get_matches();

    // Retrieve the parsed arguments
    let max_length = *args.get_one::<usize>("max_length").unwrap();
    let min_length = *args.get_one::<usize>("min_length").unwrap();
    let prefix = process_escapes(args.get_one::<String>("prefix").unwrap());
    let suffix = process_escapes(args.get_one::<String>("suffix").unwrap());

    // Fetch and parse the JSON data
    let data = include_str!("movie-quotes.json");

    // Parse JSON data
    let parsed_data = serde_json::from_str::<Value>(data).unwrap_or_else(|e| {
        eprintln!("[-] Failed to parse the included JSON data: {}", e);
        std::process::exit(1);
    });

    // Ensure the parsed data is an array
    let quotes = parsed_data.as_array().unwrap_or_else(|| {
        eprintln!("[-] JSON data is not an array.");
        std::process::exit(1);
    });

    // Filter quotes based on the specified length criteria
    let filtered_quotes: Vec<_> = quotes
        .iter()
        .filter_map(|q| q.get("quote").and_then(|v| v.as_str()))
        .filter(|&q| q.len() >= min_length && q.len() <= max_length)
        .collect();

    // Select and print a random quote
    if let Some(&quote) = filtered_quotes.choose(&mut rand::thread_rng()) {
        println!("{}{}{}", prefix, quote, suffix);
    }
}

fn cli() -> Command {
    Command::new("Random Movie Quote")
        .version("0.1.0")
        .author("Tupakkatapa")
        .about("Print a random movie quote")
        .arg(
            Arg::new("max_length")
                .short('m')
                .long("max")
                .value_name("MAX_LENGTH")
                .help("Set a maximum length for the quote")
                .default_value("256")
                .value_parser(clap::value_parser!(usize)) // Parse as usize
        )
        .arg(
            Arg::new("min_length")
                .short('n')
                .long("min")
                .value_name("MIN_LENGTH")
                .help("Set a minimum length for the quote")
                .default_value("0")
                .value_parser(clap::value_parser!(usize)) // Parse as usize
        )
        .arg(
            Arg::new("prefix")
                .short('p')
                .long("prefix")
                .value_name("PREFIX")
                .help("Add a prefix to the quote")
                .default_value("")
        )
        .arg(
            Arg::new("suffix")
                .short('s')
                .long("suffix")
                .value_name("SUFFIX")
                .help("Add a suffix to the quote")
                .default_value("")
        )
}

/// Process escape sequences in a string
fn process_escapes(input: &str) -> String {
    input
        .replace("\\n", "\n")
        .replace("\\t", "\t")
}
