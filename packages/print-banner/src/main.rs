use clap::{Arg, Command};
use rand::seq::SliceRandom;
use regex::Regex;
use serde_json::Value;
use std::process::Command as ProcessCommand;

fn main() {
    let args = cli().get_matches();

    let max_length = *args.get_one::<usize>("max_length").unwrap();
    let min_length = *args.get_one::<usize>("min_length").unwrap();
    let prefix = process_escapes(args.get_one::<String>("prefix").unwrap());
    let suffix = process_escapes(args.get_one::<String>("suffix").unwrap());
    let option = args.get_one::<String>("option").unwrap();

    match option.as_str() {
        "manpage" => {
            let output = ProcessCommand::new("sh")
                .arg("-c")
                .arg("man -k . -s 1")
                .output()
                .expect("Failed to execute command");

            if let Ok(manpage_list) = String::from_utf8(output.stdout) {
                let re = Regex::new(r"\s*\(\d+[a-zA-Z]*\)\s*").unwrap();

                let filtered_manpages: Vec<_> = manpage_list
                    .lines()
                    .map(|line| re.replace_all(line, " ").to_string())
                    .filter(|line| line.len() >= min_length && line.len() <= max_length)
                    .collect();

                if let Some(manpage) = filtered_manpages.choose(&mut rand::thread_rng()) {
                    println!("{}{}{}", prefix, manpage, suffix);
                }
            }
        }
        "quote" => {
            process_and_print_quote(
                include_str!("quotes.json"),
                min_length,
                max_length,
                &prefix,
                &suffix,
                "text",
            );
        }
        "movie-quote" => {
            process_and_print_quote(
                include_str!("movie-quotes.json"),
                min_length,
                max_length,
                &prefix,
                &suffix,
                "quote",
            );
        }
        _ => eprintln!("Invalid option. Please choose 'manpage', 'quote' or 'movie-quote'."),
    }

    fn format_quote(quote: &str, author: Option<&str>) -> String {
        let trimmed_quote = quote.trim().replace("\\n", "\n").replace("\\t", "\t");
        let stripped_quote =
            trimmed_quote.trim_matches(|c| c == '"' || c == '\'' || c == '“' || c == '”');

        match author {
            Some(author) => format!("“{}” - {}", stripped_quote, author),
            None => format!("“{}”", stripped_quote),
        }
    }

    fn process_and_print_quote(
        data: &str,
        min_length: usize,
        max_length: usize,
        prefix: &str,
        suffix: &str,
        quote_key: &str,
    ) {
        let parsed_data = serde_json::from_str::<Value>(data).unwrap_or_else(|e| {
            eprintln!("[-] Failed to parse the JSON data: {}", e);
            std::process::exit(1);
        });

        let quotes = parsed_data.as_array().unwrap_or_else(|| {
            eprintln!("[-] JSON data is not an array.");
            std::process::exit(1);
        });

        let filtered_quotes: Vec<_> = quotes
            .iter()
            .filter_map(|q| {
                q.get(quote_key).and_then(|v| v.as_str()).map(|quote| {
                    let author = q.get("author").and_then(|a| a.as_str());
                    (quote, author)
                })
            })
            .filter(|&(q, _)| q.len() >= min_length && q.len() <= max_length)
            .map(|(quote, author)| format_quote(quote, author))
            .collect();

        if let Some(formatted_quote) = filtered_quotes.choose(&mut rand::thread_rng()) {
            println!("{}{}{}", prefix, formatted_quote, suffix);
        }
    }
}

fn cli() -> Command {
    Command::new("Random Shell Banner")
        .version("0.1.0")
        .author("Tupakkatapa")
        .about("Print a random shell banner")
        .arg(
            Arg::new("max_length")
                .short('m')
                .long("max")
                .value_name("MAX_LENGTH")
                .help("Set a maximum length")
                .default_value("512")
                .value_parser(clap::value_parser!(usize)),
        )
        .arg(
            Arg::new("min_length")
                .short('n')
                .long("min")
                .value_name("MIN_LENGTH")
                .help("Set a minimum length")
                .default_value("0")
                .value_parser(clap::value_parser!(usize)),
        )
        .arg(
            Arg::new("prefix")
                .short('p')
                .long("prefix")
                .value_name("PREFIX")
                .help("Add a prefix")
                .default_value(""),
        )
        .arg(
            Arg::new("suffix")
                .short('s')
                .long("suffix")
                .value_name("SUFFIX")
                .help("Add a suffix")
                .default_value(""),
        )
        .arg(
            Arg::new("option")
                .short('o')
                .long("option")
                .value_name("OPTION")
                .help("Choose between 'manpage', 'quote' or 'movie-quote'")
                .default_value("manpage")
                .value_parser(clap::value_parser!(String)),
        )
}

fn process_escapes(input: &str) -> String {
    input.replace("\\n", "\n").replace("\\t", "\t")
}
