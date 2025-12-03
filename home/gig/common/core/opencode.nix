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

      consult = ''
        # Cross-Repository Consultation Command

        "Acting as a rogue agent for external repository analysis!" - Scotty

        EXPEDITION OF CONSULTATION PROTOCOL:
        This command enables consultation work in repositories outside primary assignment 
        while maintaining proper documentation in the home repository.

        SAFETY MEASURES:
        1. **Repository Isolation**: Works in target repository without affecting home dotfiles
        2. **Documentation Continuity**: Logs all findings back to ~/.dotfiles/scottys-journal/
        3. **Worktree Protection**: Creates temporary analysis without interference
        4. **Quest Reporting**: Documents expedition in realm/fleet/away-reports/

        CONSULTATION PROCESS:
        • Analyze target repository structure, issues, and requirements
        • Provide recommendations and solutions 
        • Document findings in engineering logs
        • Create detailed quest report for fleet records
        • No modifications to home repository configuration

        USAGE:
        Navigate to target repository, then run: /consult [analysis focus]

        Examples:
        - /consult "Analyze build failures and suggest fixes"
        - /consult "Review code quality and recommend improvements" 
        - /consult "Assess security vulnerabilities and mitigation strategies"

        "Sometimes ye need fresh eyes on a different ship, Captain!"
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

      fix-logs = ''
        # Fix Log Command - Engineering Documentation Integrity Repair

        "There's a gap in the ship's logs, Captain!" - Scotty on missing documentation

        Analyze current state of the agent's domain/specialization area and repair log integrity:

        PROCESS STEPS:
        1. **System State Analysis**: Check current configuration, recent git history, system health
        2. **Log Gap Identification**: Compare current state against existing journal entries  
        3. **Evidence Collection**: Gather system information for undocumented changes
        4. **Documentation Repair**: Create proper journal entries for missing information
        5. **Metric Updates**: Update CSV tracking data as appropriate
        6. **Integrity Verification**: Ensure logs accurately reflect current system state
        7. **Automatic Commit**: Save all documentation updates permanently

        WHAT IT IDENTIFIES:
        • Undocumented system rebuilds or configuration changes
        • Missing engineering assessments of recent operations
        • Gaps in chronological operational records
        • System state changes not reflected in logs
        • Performance metrics or error tracking inconsistencies

        AGENT SPECIALIZATION ADAPTATIONS:
        • Debug Agents: Focus on error patterns and resolution tracking
        • Development Agents: Emphasize project status and code quality  
        • System Agents: Highlight infrastructure and performance
        • Utility Agents: Track service availability and maintenance

        This ensures our engineering documentation maintains the highest standards
        of accuracy and completeness across the entire fleet!

        "No more gaps in the ship's logs, Captain!"
      '';

      check-logs = ''
        # Check Logs Command - Engineering Documentation Quality Analysis

        "Let me run a quick diagnostic on our engineering logs, Captain!" - Scotty

        Performs comprehensive analysis of existing engineering documentation for quality and consistency:

        ANALYSIS FOCUS:
        1. **Log Completeness**: Verify all major operations are documented
        2. **Chronological Integrity**: Check for timeline gaps or inconsistencies  
        3. **Format Compliance**: Ensure logs follow established standards
        4. **Metric Accuracy**: Validate CSV data against documented events
        5. **Cross-Reference Validation**: Verify logs align with git history
        6. **Content Quality Assessment**: Review detail levels and clarity

        QUALITY CHECKS:
        • Recent system changes properly documented
        • Engineering entries follow Scotty's voice and format standards
        • CSV metrics align with logged operations
        • No duplicate or contradictory entries
        • Proper stardate formatting and authority attribution
        • Technical details sufficient for future reference

        OUTPUTS:
        ✓ Comprehensive report on log quality and gaps
        ✓ Recommendations for documentation improvements  
        ✓ Identified inconsistencies requiring attention
        ✓ Assessment of overall engineering record integrity

        This is your quality assurance tool for maintaining engineering excellence!

        "Quality control is the backbone of good engineering, Captain!"
      '';

      fix-log = ''
        # Fix Log (Alias) - Engineering Documentation Integrity Repair

        This is an alias for the '/fix-logs' command.

        Run '/fix-logs' for full documentation integrity analysis and repair.

        "The right tool for the right job, always!" - Chief Engineer's motto
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
