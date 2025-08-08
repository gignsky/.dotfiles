#!/usr/bin/env nu

# Bootstrap NixOS installer script
# Rewritten from bash to nushell for better safety and readability

use std log

# Color helper functions for output
def color_print [color: string, message: string] {
    match $color {
        "red" => { print $"(ansi red)[!] ($message)(ansi reset)" }
        "green" => { print $"(ansi green)[+] ($message)(ansi reset)" }
        "yellow" => { print $"(ansi yellow)[*] ($message)(ansi reset)" }
        _ => { print $message }
    }
}

def red [message: string] { color_print "red" $message }
def green [message: string] { color_print "green" $message }
def yellow [message: string] { color_print "yellow" $message }

# Yes/no confirmation function
def yes_or_no [prompt: string] -> bool {
    loop {
        let answer = (input $"(ansi green)[+] ($prompt) [y/n] (default: y): (ansi reset)")
        let choice = if ($answer | is-empty) { "y" } else { $answer }
        match ($choice | str downcase) {
            "y" | "yes" => { return true }
            "n" | "no" => { return false }
            _ => { continue }
        }
    }
}

# Configuration structure
def default_config [] {
    {
        target_hostname: "",
        target_destination: "",
        target_user: "gig",
        ssh_key: "/home/gig/.ssh/id_rsa",
        ssh_port: "22",
        always_yes: false,
        persist_dir: "",
        debug: false
    }
}

# Help function
def show_help [] {
    print ""
    print "Remotely installs NixOS on a target machine using this .dotfiles."
    print ""
    print "USAGE: bootstrap-nixos.nu -n <target_hostname> -d <target_destination> -k <ssh_key> [OPTIONS]"
    print ""
    print "ARGS:"
    print "  -n <target_hostname>      specify target_hostname of the target host to deploy the nixos config on."
    print "  -d <target_destination>   specify ip or url to the target host."
    print "  -k <ssh_key>              specify the full path to the ssh_key you'll use for remote access to the"
    print "                            target during install process."
    print "                            Example: -k /home/gig/.ssh/my_ssh_key"
    print ""
    print "OPTIONS:"
    print "  -u <target_user>          specify target_user with sudo access. .dotfiles will be cloned to their home."
    print "                            Default='gig'."
    print "  --port <ssh_port>         specify the ssh port to use for remote access. Default=22."
    print "  --impermanence            Use this flag if the target machine has impermanence enabled. WARNING: Assumes /persist path."
    print "  --debug                   Enable debug mode."
    print "  -h | --help               Print this help."
    print ""
}

# Parse command line arguments
def parse_args [args: list<string>] -> record {
    mut config = (default_config)
    mut i = 0
    
    while $i < ($args | length) {
        match ($args | get $i) {
            "-n" => {
                $i = $i + 1
                if $i < ($args | length) {
                    $config.target_hostname = ($args | get $i)
                }
            }
            "-d" => {
                $i = $i + 1
                if $i < ($args | length) {
                    $config.target_destination = ($args | get $i)
                }
            }
            "-u" => {
                $i = $i + 1
                if $i < ($args | length) {
                    $config.target_user = ($args | get $i)
                }
            }
            "-k" => {
                $i = $i + 1
                if $i < ($args | length) {
                    $config.ssh_key = ($args | get $i)
                }
            }
            "--port" => {
                $i = $i + 1
                if $i < ($args | length) {
                    $config.ssh_port = ($args | get $i)
                }
            }
            "--impermanence" => {
                $config.persist_dir = "/persist"
            }
            "--debug" => {
                $config.debug = true
            }
            "-always_yes" => {
                $i = $i + 1
                if $i < ($args | length) {
                    $config.always_yes = (($args | get $i) == "true")
                }
            }
            "-h" | "--help" => {
                show_help
                exit 0
            }
            _ => {
                red "Invalid option detected."
                show_help
                exit 1
            }
        }
        $i = $i + 1
    }
    
    $config
}

# Get unique disk ID for safety
def get_disk_id [disk_path: string] -> string {
    let disk_info = (run-external "lsblk" "-no" "name,serial,model" $disk_path | complete)
    if $disk_info.exit_code == 0 {
        let serial = ($disk_info.stdout | lines | get 0 | str trim)
        yellow $"Using disk with serial: ($serial)"
        $serial
    } else {
        red $"Failed to get disk serial for ($disk_path)"
        red "SAFETY WARNING: Cannot verify disk identity!"
        exit 1
    }
}

# SSH command helpers
def ssh_cmd [config: record, command: string] -> string {
    let ssh_command = $"ssh -oport=($config.ssh_port) -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ($config.ssh_key) -t ($config.target_user)@($config.target_destination) ($command)"
    if $config.debug {
        yellow $"SSH CMD: ($ssh_command)"
    }
    run-external "ssh" "-oport" $config.ssh_port "-o" "StrictHostKeyChecking=no" "-o" "UserKnownHostsFile=/dev/null" "-i" $config.ssh_key "-t" $"($config.target_user)@($config.target_destination)" $command
}

def ssh_root_cmd [config: record, command: string] -> string {
    let ssh_command = $"ssh -oport=($config.ssh_port) -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ($config.ssh_key) -t root@($config.target_destination) ($command)"
    if $config.debug {
        yellow $"SSH ROOT CMD: ($ssh_command)"
    }
    run-external "ssh" "-oport" $config.ssh_port "-o" "StrictHostKeyChecking=no" "-o" "UserKnownHostsFile=/dev/null" "-i" $config.ssh_key "-t" $"root@($config.target_destination)" $command
}

def scp_cmd [config: record, source: string, destination: string] -> string {
    run-external "scp" "-oport" $config.ssh_port "-o" "StrictHostKeyChecking=no" "-i" $config.ssh_key $source $destination
}

# Main nixos-anywhere installation function
def nixos_anywhere [config: record] {
    # Create temporary directory for host keys
    let temp_dir = (mktemp -d)
    
    try {
        green $"Installing NixOS on remote host ($config.target_hostname) at ($config.target_destination)"
        
        # Clear known hosts
        green $"Wiping known_hosts of ($config.target_destination)"
        let known_hosts_file = $"($env.HOME)/.ssh/known_hosts"
        if ($known_hosts_file | path exists) {
            # Remove entries for this host
            run-external "sed" "-i" $"/($config.target_hostname)/d; /($config.target_destination)/d" $known_hosts_file
        }
        
        # Generate SSH host keys
        green $"Preparing a new ssh_host_ed25519_key pair for ($config.target_hostname)."
        let ssh_dir = $"($temp_dir)/($config.persist_dir)/etc/ssh"
        mkdir $ssh_dir
        
        let key_path = $"($ssh_dir)/ssh_host_ed25519_key"
        run-external "ssh-keygen" "-t" "ed25519" "-f" $key_path "-C" $"root@($config.target_hostname)" "-N" ""
        chmod 600 $key_path
        
        # Add SSH host fingerprint
        print "Adding ssh host fingerprint to known_hosts"
        try {
            run-external "ssh-keyscan" "-p" $config.ssh_port $config.target_destination | save -a $known_hosts_file
        } catch {
            yellow "Failed to add ssh-keyscan result to known_hosts, continuing..."
        }
        
        # Change to nixos-installer directory
        cd nixos-installer
        
        # Set up temporary password for disko
        green "Setting up temporary password for disko"
        ssh_root_cmd $config "rm -f /tmp/disko-password"
        ssh_root_cmd $config "printf 'passphrase' > /tmp/disko-password && chmod 600 /tmp/disko-password"
        
        # Verify password file
        green "Verifying disko password file..."
        ssh_root_cmd $config "ls -la /tmp/disko-password"
        
        # Generate hardware configuration
        green $"Generating hardware-config.nix for ($config.target_hostname)"
        ssh_root_cmd $config "nixos-generate-config --no-filesystems --root /mnt"
        
        # Get git root and ensure target directory exists
        let git_root = (git rev-parse --show-toplevel)
        let target_dir = $"($git_root)/hosts/($config.target_hostname)"
        mkdir $target_dir
        
        # Copy hardware configuration
        green "Copying hardware-configuration.nix from remote system..."
        scp_cmd $config $"root@($config.target_destination):/mnt/etc/nixos/hardware-configuration.nix" $"($target_dir)/hardware-configuration.nix"
        
        # Verify the copied file
        green "Verifying hardware-configuration.nix was copied..."
        if (open $"($target_dir)/hardware-configuration.nix" | str contains "broadcom_sta") {
            green "✅ broadcom_sta module found in hardware-configuration.nix"
        } else {
            yellow "⚠️ broadcom_sta module not found in hardware-configuration.nix"
            yellow "Manual intervention may be required after installation"
        }
        
        # Add files to git
        yellow "Adding files to git"
        run-external "git" "ls-files" "--others" "--exclude-standard" "--" "*.nix" | lines | each { |file| 
            run-external "git" "add" "-v" $file
        }
        
        # Create nix configuration for unfree packages
        let nix_config_dir = $"($temp_dir)/etc/nix"
        mkdir $nix_config_dir
        "allow-unfree = true" | save $"($nix_config_dir)/nix.conf"
        
        # Run nixos-anywhere
        print $"Running nixos-anywhere for ($config.target_hostname)..."
        let env_vars = {
            NIXPKGS_ALLOW_UNFREE: "1",
            NIX_CONFIG: "allow-unfree = true",
            SHELL: "/bin/sh"
        }
        
        with-env $env_vars {
            let result = (run-external "nix" "run" "github:nix-community/nixos-anywhere" "--impure" "--" "--ssh-port" $config.ssh_port "--extra-files" $temp_dir "--flake" $".#($config.target_hostname)" $"root@($config.target_destination)" | complete)
            
            if $result.exit_code != 0 {
                yellow "Main installation failed, attempting retry..."
                # Copy unfree package script and retry
                scp_cmd $config $"($git_root)/nixos-installer/ensure-unfree-packages.sh" $"root@($config.target_destination):/tmp/ensure-unfree-packages.sh"
                ssh_root_cmd $config "chmod +x /tmp/ensure-unfree-packages.sh && /tmp/ensure-unfree-packages.sh"
                
                # Retry installation
                run-external "nix" "run" "github:nix-community/nixos-anywhere" "--impure" "--" "--ssh-port" $config.ssh_port "--extra-files" $temp_dir "--flake" $".#($config.target_hostname)" $"root@($config.target_destination)"
            }
        }
        
        # Update known hosts again
        yellow "Updating ssh host fingerprint..."
        try {
            run-external "ssh-keyscan" "-p" $config.ssh_port $config.target_destination | save -a $known_hosts_file
        } catch {
            yellow "Failed to update known_hosts after installation"
        }
        
        # Handle impermanence
        if ($config.persist_dir | is-not-empty) {
            ssh_root_cmd $config $"cp /etc/machine-id ($config.persist_dir)/etc/machine-id || true"
            ssh_root_cmd $config $"cp -R /etc/ssh/ ($config.persist_dir)/etc/ssh/ || true"
        }
        
        cd -
        green "nixos-anywhere installation completed successfully!"
        
    } catch { |e|
        red $"Installation failed: ($e.msg)"
        exit 1
    } finally {
        # Cleanup
        rm -rf $temp_dir
    }
}

# Generate host age key
def generate_host_age_key [config: record] {
    green "Generating age key based on ssh_host_ed25519_key"
    
    let ssh_key_result = (run-external "ssh-keyscan" "-p" $config.ssh_port "-t" "ssh-ed25519" $config.target_destination | complete)
    
    if $ssh_key_result.exit_code != 0 {
        red "Failed to get SSH key. Host down?"
        exit 1
    }
    
    let target_key = ($ssh_key_result.stdout | lines | where { |line| $line | str contains "ssh-ed25519" } | get 0 | split column " " | get 1 2 | str join " ")
    
    if $config.debug {
        yellow $"Retrieved SSH key: ($target_key)"
    }
    
    let age_key_result = (echo $target_key | run-external "nix" "shell" "nixpkgs#ssh-to-age.out" "-c" "ssh-to-age" | complete)
    
    if $age_key_result.exit_code != 0 {
        red "Failed to generate age key"
        exit 1
    }
    
    let host_age_key = ($age_key_result.stdout | str trim)
    
    if $config.debug {
        yellow $"Generated age key: ($host_age_key)"
    }
    
    if not ($host_age_key | str starts-with "age1") {
        red "Generated age key does not match expected format"
        yellow $"Result: ($host_age_key)"
        yellow "Expected format: age1..."
        exit 1
    }
    
    green "Updating nix-secrets/.sops.yaml"
    update_sops_file $config.target_hostname "hosts" $host_age_key
    $host_age_key
}

# Update SOPS file
def update_sops_file [key_name: string, key_type: string, key: string] {
    if not ($key_type in ["hosts", "users"]) {
        red "Invalid key type. Must be either 'hosts' or 'users'."
        exit 1
    }
    
    let git_root = (git rev-parse --show-toplevel)
    cd $"($git_root)/../nix-secrets"
    
    let sops_file = ".sops.yaml"
    # Use sed to update the SOPS file (keeping original logic for compatibility)
    run-external "sed" "-i" $"/{/*,&($key_name)/ d; /age:/{n; p; s/\\(.*- \\*\\).*/\\1($key_name)/}; /&($key_type):/{n; p; s/\\(.*- &\\).*/\\1($key_name) ($key)/}" $sops_file
    
    green "Updated nix-secrets/.sops.yaml"
    cd -
}

# Generate user age key
def generate_user_age_key [config: record] {
    print $"Checking if ($config.target_hostname) age key already exists"
    
    let git_root = (git rev-parse --show-toplevel)
    let secret_file = $"($git_root)/../nix-secrets/secrets.yaml"
    
    # Check if user age key exists
    let key_exists = (try {
        run-external "sops" "-d" "--extract" "[\"user_age_keys\"]" $secret_file | complete
        run-external "sops" "-d" "--extract" $"[\"user_age_keys\"][\"($config.target_hostname)\"]" $secret_file | complete
        true
    } catch {
        false
    })
    
    if not $key_exists {
        print "Age key does not exist. Generating."
        let age_output = (run-external "nix" "shell" "nixpkgs#age" "-c" "age-keygen")
        let lines = ($age_output | lines)
        let secret_key = ($lines | get 2)
        let public_key = ($lines | get 1 | split column ":" | get 1 | str trim)
        let key_name = $"($config.target_user)_($config.target_hostname)"
        
        run-external "sops" "--set" $"[\"user_age_keys\"][\"($key_name)\"] \"($secret_key)\"" $secret_file
        update_sops_file $key_name "users" $public_key
    } else {
        print $"Age key already exists for ($config.target_hostname)"
    }
}

# Main function
def main [args?: list<string>] {
    let config = if ($args == null) {
        parse_args ($env.args | skip 1)
    } else {
        parse_args $args
    }
    
    # Validate required arguments
    if ($config.target_hostname | is-empty) or ($config.target_destination | is-empty) or ($config.ssh_key | is-empty) {
        red "ERROR: -n, -d, and -k are all required"
        show_help
        exit 1
    }
    
    # Enable debug mode if requested
    if $config.debug {
        $env.RUST_LOG = "debug"
    }
    
    mut updated_age_keys = false
    
    if not $config.always_yes {
        # Interactive mode
        if (yes_or_no "Run nixos-anywhere installation?") {
            nixos_anywhere $config
        }
        
        if (yes_or_no "Generate host (ssh-based) age key?") {
            generate_host_age_key $config
            $updated_age_keys = true
        }
        
        if (yes_or_no "Generate user age key?") {
            generate_user_age_key $config
            $updated_age_keys = true
        }
        
        if $updated_age_keys {
            green "Rekeying secrets..."
            run-external "just" "rekey-no-hooks"
            green "Updating flake input to pick up new .sops.yaml"
            run-external "nix" "flake" "lock" "--update-input" "nix-secrets"
        }
        
        # Additional setup steps would go here...
        
    } else {
        # Non-interactive mode
        nixos_anywhere $config
        generate_host_age_key $config
        generate_user_age_key $config
        $updated_age_keys = true
        
        if $updated_age_keys {
            run-external "just" "rekey-no-hooks"
            run-external "nix" "flake" "lock" "--update-input" "nix-secrets"
        }
    }
    
    green "Bootstrap completed successfully!"
    if $updated_age_keys {
        green "Don't forget to commit and push changes to both .dotfiles and nix-secrets repositories"
    }
}

# Run main function
main