{
  programs.opencode = {
    enable = true;

    # Main configuration
    settings = {
      # Core setup
      model = "github-copilot/claude-sonnet-4";
      small_model = "github-copilot/claude-haiku-4.5";
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

      # Cursor configuration - set to line cursor
      cursor_style = "line";

      share = "manual";

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
    };

    # Enhanced commands with debugger focus
    # Agent slash commands - accessible across all agents
    commands = {
      # Nix development commands
      check = "Validate flake configuration and outputs. Run nix flake check and address any issues found. This validates the entire flake including all outputs, packages, and system configurations.";

      build = "Build flake outputs and check for issues. Build flake outputs using nix build and check for issues. Usage: specify .#output to build specific outputs. Helpful for testing package builds.";

      update = "Update flake inputs and handle breaking changes. Update flake inputs using nix flake update and handle any breaking changes. Can update specific inputs with input-name parameter.";

      show = "Display all available flake outputs. Show all available flake outputs using nix flake show. Helpful for understanding the flake structure and available packages/systems.";

      # Fleet operation commands
      sitrep = "Comprehensive fleet status and engineering situation report. Provide detailed status report covering: fleet systems, current operations, system health, performance metrics, recent issues, and engineering recommendations";

      fix-log = "Analyze current state and fix missing log documentation. Assess current host/domain operational state, identify gaps in existing logs, and document missing information in proper engineering log format";

      check-logs = "Comprehensive log analysis and attention area identification (aliases: check-log). Search through all existing engineering logs and journal entries to identify areas requiring attention, maintenance, follow-up actions, or resolution. Present findings to user, create documentation log entry, and run /sitrep if significant issues discovered.";

      unstuck = "Reset focus and continue with current task. Acknowledge being stuck, reset mental state with appropriate personality response, and continue from the last clear objective. Get back on track with the task at hand.";

      # Away mission commands
      consult = "Enhanced cross-repository consultation with mission staging. ENHANCED CONSULTATION PROTOCOL: Preserve original user request, create mission archive in realm/fleet/mission-archives/[agent]-missions/, perform expert analysis while maintaining detailed progressive notes. Work in target repository with full access while documenting back to home base.";

      beam-out = "Compile final away mission report and clean up archives (aliases: mission-complete). MISSION COMPLETION PROTOCOL: Review all mission notes from current active mission archive, compile comprehensive final away report, move to permanent fleet documentation, clean up temporary staging, commit all documentation with proper attribution.";

      # Quality assurance commands
      enhance-commit = "Analyze and improve commit message quality (aliases: enhance). Use the commit enhancement system to analyze a commit message for quality issues, provide suggestions, and optionally guide through interactive improvement. Integrates with scripts/commit-enhance-lib.sh";

      # Agent summoning (when talking to other agents)
      scotty = "Summon Chief Engineer for debugging and technical issues. Activate Chief Engineer Montgomery Scott for debugging complex systems: Nix flakes, Rust code, Bash scripts, Lua in Nix, Nushell configurations. Scotty will analyze errors, check system stress points, and provide engineering solutions. He is so described in the relevant gigdot/../resources/{agent-name}-additional-personality.md";
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
      - This flake location: ~/.dotfiles
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

    # Agent Configuration System (Home Manager specific)
    agents = {
      scotty = "/home/gig/.dotfiles/home/gig/common/resources/scotty-additional-personality.md";
    };
  };

  # Keep your existing SOPS secret configuration
  sops.secrets."opencode-auth-json" = {
    mode = "600";
    path = "/home/gig/.local/share/opencode/auth.json";
  };
}
