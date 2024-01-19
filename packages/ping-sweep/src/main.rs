use clap::{Arg, Command};
use ipnetwork::Ipv4Network;
use std::process::Command as SystemCommand;
use threadpool::ThreadPool;

fn main() {
    let args = cli().get_matches();

    // Retrieve the parsed arguments
    let network = *args.get_one::<Ipv4Network>("subnet").unwrap();
    let num_threads = *args.get_one::<usize>("threads").unwrap();

    // Create a thread pool
    let pool = ThreadPool::new(num_threads);

    // Iterate over each IP in the subnet
    for ip in network.iter() {
        let ip_addr = ip.to_string();

        pool.execute(move || {
            if ping(&ip_addr) {
                println!("{}", ip_addr);
            }
        });
    }

    // Wait for all threads to complete
    pool.join();
}

fn cli() -> Command {
    Command::new("Ping Sweep")
        .version("0.1.0")
        .author("Tupakkatapa")
        .about("Performs a ping sweep on a given subnet")
        .arg(
            Arg::new("subnet")
                .short('s')
                .long("subnet")
                .value_name("SUBNET")
                .help("Set the subnet to ping in CIDR notation (e.g., 192.168.1.0/24)")
                .default_value("192.168.1.0/24")
                .value_parser(clap::value_parser!(Ipv4Network)), // Parse as Ipv4Network
        )
        .arg(
            Arg::new("threads")
                .short('t')
                .long("threads")
                .value_name("THREADS")
                .help("Number of concurrent threads")
                .default_value("64")
                .value_parser(clap::value_parser!(usize)), // Parse as usize
        )
}

fn ping(ip_addr: &str) -> bool {
    let output = SystemCommand::new("ping")
        .arg(ip_addr)
        .arg("-c 1")
        .arg("-W 1")
        .output();

    match output {
        Ok(o) => o.status.success(),
        Err(e) => {
            eprintln!("Error pinging {}: {}", ip_addr, e);
            false
        }
    }
}
