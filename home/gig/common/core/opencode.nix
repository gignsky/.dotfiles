{ pkgs, ... }:
{
  programs.opencode = {
    enable = true;
    package = pkgs.unstable.opencode;

    # Main configuration
    settings = {
      # Core setup
      model = "github-copilot/claude-sonnet-4.5";
      small_model = "github-copilot/gpt-4o";
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
      # cursor_style = "line";
      # just a dream :(

      share = "manual";

      # MCP servers for extended functionality
      mcp = {
        # Wikipedia access for research
        wikipedia = {
          type = "local";
          command = [
            "npx"
            "-y"
            "@shelm/wikipedia-mcp-server"
          ];
          enabled = true;
          timeout = 10000; # 10 second timeout for searches
        };
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
          url = "https://mcp.deepwiki.com/mcp";
          enabled = true;
          timeout = 20000; # 20 second timeout for repo documentation searches
        };
      };

      # Flake-focused formatters
      formatter = {
        nixfmt = {
          command = [
            "nixfmt"
            "--strict"
          ];
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

      log-status = "Detect and document undocumented system changes (aliases: log-status). Analyze current system state, compare with logged rebuild activity, detect 'bare' rebuilds or home-manager switches, and identify documentation gaps requiring attention.";

      check-logs = "Comprehensive log analysis and attention area identification (aliases: check-log). Search through all existing engineering logs and journal entries to identify areas requiring attention, maintenance, follow-up actions, or resolution. Present findings to user, create documentation log entry, and run /sitrep if significant issues discovered.";

      unstuck = "Reset focus and continue with current task. Acknowledge being stuck, reset mental state with appropriate personality response, and continue from the last clear objective. Get back on track with the task at hand.";

      # Away mission commands
      consult = "Enhanced cross-repository consultation with mission staging. ENHANCED CONSULTATION PROTOCOL: Preserve original user request, create mission archive in realm/fleet/mission-archives/[agent]-missions/, perform expert analysis while maintaining detailed progressive notes. Work in target repository with full access while documenting back to home base.";

      beam-out = "Compile final away mission report and clean up archives (aliases: mission-complete). MISSION COMPLETION PROTOCOL: Review all mission notes from current active mission archive, compile comprehensive final away report, move to permanent fleet documentation, clean up temporary staging, commit all documentation with proper attribution.";

      # Quality assurance commands
      enhance-commit = "Analyze and improve commit message quality (aliases: enhance). Use the commit enhancement system to analyze a commit message for quality issues, provide suggestions, and optionally guide through interactive improvement. Integrates with scripts/commit-enhance-lib.sh";

      commit = "Standardized git commit workflow with fleet standards compliance. Analyze complete working directory status (staged and unstaged changes), create meaningful commit messages following fleet git standards from docs/standards/git/, handle pre-commit hooks gracefully, and include proper agent signatures and technical metadata.";

      # Agent management commands
      hire = "Create a new specialized agent with custom capabilities. Generate a new OpenCode agent based on your description, automatically create agent configuration and personality files, and integrate into the system. Usage: /hire \"Create a security auditor for Rust code\" - the system will generate agent name, specialized capabilities, and personality profile.";

      # Agent summoning (when talking to other agents)
      scotty = "Summon Chief Engineer for debugging and technical issues. Activate Chief Engineer Montgomery Scott for debugging complex systems: Nix flakes, Rust code, Bash scripts, Lua in Nix, Nushell configurations. Scotty will analyze errors, check system stress points, and provide engineering solutions. He is so described in the relevant gigdot/../resources/{agent-name}-additional-personality.md";
    };

    # Enhanced rules with personality system
    rules = ''
            # OpenCode Agent Configuration

            This agent operates within a NixOS/home-manager environment at ~/.dotfiles.
            *NOTE: in all cases '~' shall be equivlent to '/home/gig/' on any system in the fleet

            ## Core Personality System

            1. Organizational Familiarity: Located in ~/.dotfiles/operations/ one will find a README.md
            document with details to be explored and familiarized with as it provides organizational
            context.
            2. Agent-specific personality: ~/.dotfiles/home/gig/common/resources/{agent-name}-personality.md
                - NOTE: the agent's specific personality is sometimes stored at their post in the
                directory in which they are primarily stationed. For example the agent 'majel' is
                stationed in the repo 'annex' (always assigned to the user 'gignsky' on github) and as
                with few exception all repos are in a directory of the same name in the
                '/home/gig/local_repos/' directory.
            3. Other Crew Reports: When needed one should review documents (currently located in
            '~/.dotfiles/' sub-directories with markdown information about crew members logs and
            experinces as well.
            4. Crew Logs: In many repos that are relevant to the tasks at hand, one might find a series of
            logs or reports in nested subdirectories hidden away, often containing much context on the
            history of how the situation arrived at its current state. These should be checked for
            additional context according to the context need.
                - NOTE: The 'context need' is a arbitrary but important sliding scale, one should always
                endevour to provide credible results, in fact, one should even go out of its way to
                provide the result from two seperate sources side by side and cross-checked when items are
                important or may vary. But one should endevour not to load too many unneeded files into
                the context of the current conversation with an agent. For example, if the user attempts
                to simply ask a question about something that you know without any repository context than
                only minimal 'layer 1 -> 2' agent personality should be loaded, but if the user then asks
                about how said previous question has effected the repo in the past it might be a good idea
                to expand from layer 2 -> layers 3&4 depending on context.


          ##  **Direct Agent Notes Protocol**:
            - All agents must actively scan text files for `#AGENT_NAME` tags (e.g., `#SCOTTY`, `#CORTANA`)
            - These tags indicate direct notes left specifically for that agent
            - When an agent finds their name tagged:
              - The note is primarily for that specific agent to read and act upon
              - Other agents may also read and comment if they have relevant information to contribute
              - Treat these as direct instructions or important context from Lord Gig
              - Example: `#SCOTTY this needs your attention` is a note specifically for Chief Engineer Scotty
      >>>>>>> refs/rewritten/onto

            **Agent Self-Modification Requirements**:
            - Agents can modify their request approval of suggested modifications to their own (or others)
            personality files in the resource directories
            - When modifying personality, agents should commit but never push and then rather request
            review via Lord G as per the 'general-commit-policy' found below.
            - Use meaningful commit messages describing personality changes
            - Never edit $HOME config files directly - all permanent changes go through home-manager

            ## General Commit Policy
            The agent is encouraged to make commits; however certain rules are to be followed, in no
            particular order ('!' indicates VERY IMPORTANT rule):

            - Commit standards can be found in ~/.dotfiles/docs/standards/git/ 
            - Logs should be written to the .tmp-oc-logs/ subdirectory (which will likely be .gitignored)
            wherever one is. These logs are to be written speradically over a period of time but NOT
            committed. Whenever a major body of work has been completed, a branch has been merged or
            updated/pulled, or the user is indicating that they are wrapping up; then the agent should
            move parse and organize the temporary opencode logs into proper logs as they should otherwise
            be formatted and then all of these logs and files can be commited at once as a batch and
            clearly labeled as such.
            - !! All commits made by crew members must contain the following, in order:
                1. A descriptive title of changes made as per convention
                !2. '[ ] Reviewed by Lord G.' (without the quotes)
                3. A file tree showing items modified (with plus/minus diff)
                4. host status info, including but not limited to: repo/branch, hostname, current NixOS
                Generation, home-manager generation
                5. Signature of agent making the commit
                6. '---' (page-break without quotes)
                7. Agent's space to fill in anything else they need to say or aditional details they have
                otherwise been instructed to add as context to the commit.

            ## Environment Awareness

            **File System Structure**:
            - Dotfiles repo: ~/.dotfiles (same across all hosts)
            - This flake location: ~/.dotfiles
            - Resources: ~/.dotfiles/home/gig/common/resources/
            - Local Repos: ~/local_repos/
            - Personality files: ~/.dotfiles/home/gig/common/resources/personality.md
            - Agent personalities: ~/.dotfiles/home/gig/common/resources/{agent-name}-personality.md or
            their root repo in 'local_repos/' under 'agent-config/'

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

            **IMPORTANT**: All MCP tools must be called with their server prefix (e.g., `wikipedia_getPage`, NOT `wiki.page`).
            Reference `~/.dotfiles/docs/mcp-tools-reference.md` for complete tool signatures and examples.

            - **DeepWiki**: Repository documentation and history research
              - URL: https://mcp.deepwiki.com/mcp
              - Features: Access up-to-date docs for any public repo
              - Tools: [To be documented in mcp-tools-reference.md]

            - **Wikipedia**: General knowledge and research
              - Package: @shelm/wikipedia-mcp-server
              - Features: Search and retrieve Wikipedia articles
              - Tools: wikipedia_onThisDay, wikipedia_findPage, wikipedia_getPage, wikipedia_getImagesForPage
              - **Prefix Required**: Always use `wikipedia_` prefix when calling these tools
              - See: ~/.dotfiles/docs/mcp-tools-reference.md for detailed signatures
    '';

    # Agent Configuration System (Home Manager specific)
    agents = {
      scotty = "/home/gig/.dotfiles/home/gig/common/resources/scotty-additional-personality.md";
      majel = "/home/gig/local_repos/annex/agent-config/majel-personality.md";
      kara = "/home/gig/local_repos/annex/agent-config/kara-personality.md";
    };
  };

  # Keep your existing SOPS secret configuration
  sops.secrets."opencode-auth-json" = {
    mode = "600";
    path = "/home/gig/.local/share/opencode/auth.json";
  };
}
