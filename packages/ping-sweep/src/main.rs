use clap::{Arg, Command};
use futures::stream::{self, StreamExt};
use ipnetwork::Ipv4Network;
use std::process::Stdio;
use std::sync::Arc;
use tokio::process::Command as AsyncCommand;

#[tokio::main]
async fn main() {
    let args = cli().get_matches();

    // Retrieve the parsed arguments
    let network = *args.get_one::<Ipv4Network>("subnet").unwrap();
    let concurrency = *args.get_one::<usize>("threads").unwrap();

    // Convert subnet to a IP list
    let ip_list: Vec<String> = network.iter().map(|ip| ip.to_string()).collect();
    let ip_list = Arc::new(ip_list);

    // Iterate over each IP in the subnet
    stream::iter(ip_list.iter())
        .map(|ip| {
            let ip = ip.clone();
            tokio::spawn(async move {
                if ping(&ip).await {
                    println!("{}", ip);
                }
            })
        })
        .buffer_unordered(concurrency)
        .collect::<Vec<_>>()
        .await;
}

fn cli() -> Command {
    Command::new("Ping Sweep")
        .version("0.1.1")
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
                .help("Number of concurrent async tasks")
                .default_value("512")
                .value_parser(clap::value_parser!(usize)), // Parse as usize
        )
}

async fn ping(ip_addr: &str) -> bool {
    let output = AsyncCommand::new("ping")
        .arg("-n") // Disable DNS resolution
        .arg("-c").arg("1") // Only one ping attempt
        .arg("-W").arg("1") // 1-second timeout
        .arg(ip_addr)
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .await;

    matches!(output, Ok(status) if status.success())
}
