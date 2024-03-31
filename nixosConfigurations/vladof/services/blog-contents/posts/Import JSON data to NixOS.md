---
date: "2024-01-01"
---

In this blog post, I will briefly demonstrate how to import JSON data into a NixOS configuration. This concept originated when I was trying to incorporate user input data from a web frontend into a NixOS configuration dynamically.

For a comprehensive understanding how this could be used, refer to [this documentation](https://github.com/ponkila/HomestakerOS/blob/main/docs/workflow.md) from a related project, HomestakerOS. It describes the entire workflow, including a data schema for the user input.

**Important note:** Adding configurations dynamically somewhat contradicts the principles of the Nix philosophy and may potentially be exploited for malicious intentions. Therefore, it's advised to manually check the contents of the imported configuration and limit the configuration's scope to enhance security, especially if the data is sent over the internet.

## 1. Converting JSON to Nix

The conversion from JSON to Nix expressions is straightforward thanks to Nix's `fromJSON` function. Here's a script that takes JSON data from STDIN and converts it into a Nix expression:

```bash
#!/usr/bin/env bash

set -o pipefail

# Read JSON data from stdin if available
if [ -p /dev/stdin ]; then
  json_data=$(</dev/stdin)
else
  echo "error: JSON data not provided."
  exit 1
fi

# Escape double quotes
esc_json_data="${json_data//\"/\\\"}"

# Convert JSON to Nix expression
nix_expr=$(nix-instantiate --eval --expr "builtins.fromJSON \"$esc_json_data\"") || exit 1

# Print to stdout
echo "$nix_expr"
```

## 2. Insert to a Broilerplate

To import this data into your NixOS configuration, we should also encapsulate it within the basic syntax. This is also a great opportunity to restrict the scope of the configuration to prevent some nasty things. Append this to the bash script from earlier:

```bash
# Output to a temporary file
cat > "/tmp/data.nix" << EOF
{ pkgs, config, inputs, lib, ... }:
{
  <module_name> = $nix_expr;
}
EOF
```

## 3. Conditional Import in NixOS

To automagically import the generated Nix file into your NixOS configuration, let's use the following method. It checks for the file's existence at a predetermined location (`/tmp/data.nix`) and imports it if present:

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/unstable";

  outputs = inputs @ { self, nixpkgs, ... }: let
    inherit (self) outputs;
  in {
    nixosConfigurations = {
      your-hostname = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs outputs;};
        modules =
          [
            ./configuration.nix
          ]
          # Importing generated config conditionally if it exists
          ++ nixpkgs.lib.optional (builtins.pathExists /tmp/data.nix) /tmp/data.nix;
      };
    };
  };
}
```

## Bonus Conversions

- Nix expression to JSON
  ```bash
  nix-instantiate --eval --expr "builtins.toJSON (import ./example.nix)"
  ```

- Evaluating from flake to JSON
  ```bash
  nix eval --json .#nixosConfigurations.<hostname>.config.<module_name> | jq
  ```
