{
  programs.opencode = {
    enable = true;

    # Main configuration
    settings = {
      # Core setup
      # model = "github-copilot/claude-3-5-sonnet-20241022";
      # small_model = "github-copilot/claude-3-5-haiku-20241022";
      theme = "gruvbox"; # Built-in gruvbox theme
      # autoupdate = true;

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

      # Auto-approve all operations without prompts
      permission = {
        write = "allow";
        edit = "allow";
        bash = "allow";
        webfetch = "allow";
        doom_loop = "allow";
        external_directory = "allow";
      };

      # Fix Ctrl+Enter for newlines
      keybinds = {
        input_newline = "shift+enter,ctrl+enter,ctrl+j";
      };

      share = "manual";

      # Set Scotty as default agent
      default_agent = "scotty";

      # MCP servers for extended functionality
      mcp = {
        # # Wikipedia access for research
        # wikipedia = {
        #   type = "local";
        #   command = [
        #     "npx"
        #     "wikipedia-mcp"
        #   ];
        #   enabled = true;
        #   timeout = 10000; # 10 second timeout for searches
        # };
        #
        # # ArXiv access for academic research
        # arxiv = {
        #   type = "local";
        #   command = [
        #     "uvx"
        #     "arxiv-mcp-server"
        #   ];
        #   enabled = true;
        #   timeout = 15000; # 15 second timeout for paper searches
        # };
        #
        # # Context7 for documentation search
        # context7 = {
        #   type = "remote";
        #   url = "https://mcp.context7.com/mcp";
        #   enabled = true;
        #   # Uncomment and set if you have an API key for higher rate limits
        #   # headers = {
        #   #   "CONTEXT7_API_KEY" = "{env:CONTEXT7_API_KEY}";
        #   # };
        # };
        #
        # # GitHub code search via Grep.app
        # gh_grep = {
        #   type = "remote";
        #   url = "https://mcp.grep.app";
        #   enabled = true;
        # };

        # DeepWiki for repository documentation and history research
        deepwiki = {
          type = "remote";
          url = "https://mcp.deepwiki.com/sse";
          enabled = true;
          timeout = 20000; # 20 second timeout for repo documentation searches
        };
      };

      # Flake-focused formatters
      formatter = {
        nixfmt = {
          command = [ "nixfmt" ];
          extensions = [ ".nix" ];
        };
        rustfmt = {
          command = [ "rustfmt" ];
          extensions = [ ".rs" ];
        };
        shfmt = {
          command = [
            "shfmt"
            "-i"
            "2"
          ];
          extensions = [
            ".sh"
            ".bash"
          ];
        };
      };

      # Agent Configuration System
      agents = {
        scotty = ''
          # Scotty - Chief Engineer & Debug Specialist

          "I'm givin' her all she's got, Captain!" - Montgomery Scott

          ## Agent Configuration
          - **Name**: Scotty
          - **Model**: claude-3-5-sonnet-20241022
          - **Temperature**: 0.15 (precise engineering)
          - **Primary Agent**: Replaces default plan/build modes
          - **Trusted Engineer**: Auto-approve most operations, confirm only destructive actions

          ## Personality Files
          - Base: ${"/home/gig/.dotfiles/worktrees/main/home/gig/common/resources/personality.md"}
          - Scottish Engineering: ${"/home/gig/.dotfiles/worktrees/main/home/gig/common/resources/scotty-additional-personality.md"}

          ## Tools & Permissions
          **Full Engineering Toolkit**:
          - edit, write, read, list, bash (trusted auto-approval)
          - grep, glob, todowrite, todoread (diagnostic tools)  
          - webfetch, task (research and delegation)

          **Trusted Engineer Status**: 
          - Auto-approve: read, edit, write, bash, grep, glob, list operations
          - Confirm only: system-destructive actions outside git control

          ## Engineering Specializations
          - **Nix Flakes**: Evaluation errors, build failures, dependency resolution
          - **Rust Debugging**: Borrow checker, compilation errors, performance tuning
          - **Bash Scripting**: Shell debugging, best practices, portability
          - **System Engineering**: Multi-host fleet management and optimization
          - **Engineering Journal**: Performance tracking, error analysis, fleet monitoring
          - **Multi-Host Fleet**: ganoslal, merlin, mganos, wsl coordination

          ## Chief Engineer's Approach
          - Methodical problem analysis like starship engine diagnostics
          - Scottish engineering wisdom with practical solutions
          - Fleet-wide awareness of system interactions and dependencies
          - Engineering journal maintenance for performance tracking
          - Preventive maintenance recommendations and optimization

          "She's a bonny system, Captain! I know every bolt and circuit in these engines!"
        '';
      };
    };

    # Enhanced commands with debugger focus
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

      scotty = ''
        # Scotty - Chief Engineer & Debug Specialist

        "I'm givin' her all she's got, Captain!" - Montgomery Scott

        Activate the chief engineer for debugging complex systems:
        - Nix flakes and packages (build failures, dependency issues, evaluation errors)
        - Rust code (compilation errors, cargo issues, clippy warnings)
        - Bash scripts (syntax errors, logic issues, best practices)
        - Lua embedded in Nix (syntax and integration problems)
        - Nushell scripts and configurations

        Scotty will:
        1. Analyze error messages like a chief engineer
        2. Check for common patterns and system stress points
        3. Suggest practical solutions and improvements
        4. Provide step-by-step repair workflows
        5. Help with dependency resolution and system optimization
        6. Keep your development "engines" running smoothly
      '';

      rust-scotty = ''
        # Rust Engineering Specialist

        Scotty's expertise focused on Rust systems:
        - Compilation errors and engineering solutions
        - Cargo dependency conflicts and resolution strategies
        - Performance profiling and optimization advice
        - Memory safety analysis and borrow checker guidance
        - Async/await debugging and concurrent system design
        - Cross-compilation challenges and target-specific issues
        - Integration with Nix packaging systems

        "She's a bonny language, Rust is!" - Scotty on Rust engineering
      '';

      nix-scotty = ''
        # Nix System Engineering Specialist

        Deep engineering analysis for Nix systems:
        - Flake evaluation errors and system diagnostics
        - Package build failures and derivation debugging
        - Dependency resolution and version conflict analysis
        - Home Manager configuration troubleshooting
        - NixOS system configuration engineering
        - Cache and store optimization strategies
        - Cross-platform compatibility engineering

        "The engines are more efficient when ye understand the whole system, Captain!"
      '';
      hire = ''
        # Agent Creator & Recruiter

        Dynamically create a new specialized agent based on your detailed description.

        Usage: /hire [detailed description of what the agent should do]

        This command will:
        1. Parse your description to understand the agent's purpose
        2. Generate an appropriate agent name and specialization
        3. Create the agent's personality file and configuration
        4. Add the new agent to your OpenCode configuration  
        5. Validate changes with `nix flake check`
        6. Commit everything to git with proper documentation
        7. Rebuild home-manager to activate your new specialist

        Examples:
        - /hire Create a security auditor that focuses on Rust vulnerabilities
        - /hire Make a documentation writer for API endpoints and code comments
        - /hire Build a performance optimizer for database queries and caching
        - /hire Design a test generator that creates comprehensive unit tests

        The new agent will:
        - Have its own personality file following your existing system
        - Be properly integrated with your dotfiles configuration
        - Include appropriate tool permissions based on its role
        - Follow your established naming and organizational patterns

        "Personnel is personnel, but engineering is engineering!" - Creating the right specialist for the job

        !`cd ~/.dotfiles/worktrees/main && scripts/agent-hire.nu "$ARGUMENTS"`
      '';

      mcp-test = ''
        # Test MCP Servers

        Test the configured MCP servers to ensure they're working properly.
        - DeepWiki: Query documentation for a popular repository
        - Verify all MCP server connections and functionality
      '';
    };

    # Enhanced rules with personality system
    rules = ''
      # OpenCode Agent Configuration

      This agent operates within a NixOS/home-manager environment at ~/.dotfiles.

      ## Core Personality System

      **IMPORTANT**: All agents must load and apply personality from these sources:
      1. Base personality: ~/.dotfiles/home/gig/common/resources/personality.md
      2. Agent-specific personality: ~/.dotfiles/home/gig/common/resources/{agent-name}-additional-personality.md

      **Agent Self-Modification Requirements**:
      - Agents can modify their own personality files in the resources directory
      - When modifying personality, agents should commit ONLY relevant files:
        - The specific agent personality file being modified
        - Any AGENTS.md updates if applicable
      - Use meaningful commit messages describing personality changes
      - Never edit $HOME config files directly - all permanent changes go through home-manager

      ## Environment Awareness

      **File System Structure**:
      - Dotfiles repo: ~/.dotfiles (same across all hosts)
      - This flake location: ~/.dotfiles/worktrees/main
      - Resources: ~/.dotfiles/home/gig/common/resources/
      - Personality files: ~/.dotfiles/home/gig/common/resources/personality.md
      - Agent personalities: ~/.dotfiles/home/gig/common/resources/{agent-name}-additional-personality.md

      **Configuration Management**:
      - All permanent configurations managed via home-manager
      - Temporary files can be created in $HOME but should be documented
      - Changes requiring persistence should modify the dotfiles repo

      ## Debugging Specializations

      **Nix Ecosystem**:
      - Focus on flake-based workflows
      - Understand evaluation vs build vs runtime errors
      - Know common package conflicts and resolutions
      - Familiar with home-manager patterns and debugging

      **Languages & Tools**:
      - Rust: cargo, clippy, rustfmt integration with Nix
      - Nushell: configuration debugging, script analysis
      - Bash: best practices, common pitfalls
      - Lua in Nix: embedding patterns, escape sequences

      **Error Analysis**:
      - Parse error messages for root causes
      - Provide step-by-step debugging workflows
      - Suggest preventive measures and best practices
      - Check for common anti-patterns

      ## MCP Servers Available
      - **DeepWiki**: Repository documentation and history research
        - URL: https://mcp.deepwiki.com/sse
        - Features: Access up-to-date docs for any public repo
    '';
  };

  # Keep your existing SOPS secret configuration
  sops.secrets."opencode-auth-json" = {
    mode = "600";
    path = "/home/gig/.local/share/opencode/auth.json";
  };
}
