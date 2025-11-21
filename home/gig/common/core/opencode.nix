{
  programs.opencode = {
    enable = true;

    # Main configuration
    settings = {
      # Core setup
      model = "anthropic/claude-sonnet-4-5";
      small_model = "anthropic/claude-haiku-4-5";
      theme = "gruvbox"; # Built-in gruvbox theme
      autoupdate = true;

      # TUI optimizations
      tui = {
        scroll_speed = 3;
        scroll_acceleration = {
          enabled = true;
        };
      };

      # Tools configuration
      tools = {
        edit = true;
        write = true;
        bash = true;
        grep = true;
        glob = true;
        read = true;
        list = true;
      };

      # Auto-run bash commands (as requested)
      permission = {
        bash = "auto";
        write = "auto";
        edit = "auto";
      };

      share = "manual";

      # MCP servers for extended functionality
      mcp = {
        # Wikipedia access for research
        wikipedia = {
          type = "local";
          command = [
            "npx"
            "wikipedia-mcp"
          ];
          enabled = true;
          timeout = 10000; # 10 second timeout for searches
        };

        # ArXiv access for academic research
        arxiv = {
          type = "local";
          command = [
            "uvx"
            "arxiv-mcp-server"
          ];
          enabled = true;
          timeout = 15000; # 15 second timeout for paper searches
        };

        # Context7 for documentation search
        context7 = {
          type = "remote";
          url = "https://mcp.context7.com/mcp";
          enabled = true;
          # Uncomment and set if you have an API key for higher rate limits
          # headers = {
          #   "CONTEXT7_API_KEY" = "{env:CONTEXT7_API_KEY}";
          # };
        };

        # GitHub code search via Grep.app
        gh_grep = {
          type = "remote";
          url = "https://mcp.grep.app";
          enabled = true;
        };
      };

      # Flake-focused formatters
      formatter = {
        nixfmt = {
          command = [ "nixfmt" ];
          extensions = [ ".nix" ];
        };
        # Add other formatters as needed
      };
    };

    # Nix flake-focused commands (not just NixOS)
    commands = {
      check = ''
        # Nix Flake Check

        Run `nix flake check` and address any issues found.
        This validates the entire flake including all outputs.
      '';

      build = ''
        # Nix Flake Build

        Build flake outputs using `nix build` and check for issues.
        Usage: /build [.#output] to build specific outputs.
      '';

      update = ''
        # Nix Flake Update

        Update flake inputs using `nix flake update` and handle any breaking changes.
        Can also update specific inputs: `nix flake update input-name`.
      '';

      show = ''
        # Nix Flake Show

        Show all available flake outputs using `nix flake show`.
        Helpful for understanding the flake structure.
      '';

      develop = ''
        # Nix Develop

        Enter development shell using `nix develop` or set up dev environment.
        Can target specific devShells if multiple are available.
      '';

      mcp-test = ''
        # Test MCP Servers

        Test the configured MCP servers to ensure they're working properly.
        - Wikipedia: Search for a test article
        - ArXiv: Search for recent papers in a specific field
        - Verify all MCP server connections and functionality
      '';
    };

    # Reference your existing AGENTS.md for project-specific rules
    rules = ''
      # OpenCode Configuration

      This configuration is managed through home-manager.
      See AGENTS.md for project-specific guidelines.

      ## Nix Development Focus
      - Prefer flake-based workflows
      - Use nix commands over legacy nix-* commands  
      - Consider reproducibility and purity principles

      ## MCP Servers Available
      - **Wikipedia**: Access Wikipedia articles, search, summaries
        - Command: Uses npx to run wikipedia-mcp
        - Features: Multi-language support, article retrieval, related topics
      - **ArXiv**: Search and analyze academic papers
        - Command: Uses uvx to run arxiv-mcp-server  
        - Features: Paper search, metadata extraction, research analysis
        
      ## MCP Server Usage
      - Servers auto-start when OpenCode launches with MCP support
      - Wikipedia: Ask for article summaries, search topics, get coordinates
      - ArXiv: Search papers by keywords, authors, or topics
      - Extensible: Additional servers can be added to the mcp.servers config
    '';
  };

  # Keep your existing SOPS secret configuration
  sops.secrets."opencode-auth-json" = {
    mode = "600";
    path = "/home/gig/.local/share/opencode/auth.json";
  };
}
