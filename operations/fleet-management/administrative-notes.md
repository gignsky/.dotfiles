# Notes for Future Administrative Support

**Purpose**: Items to revisit when a Yeoman is hired to assist with administrative duties

## Administrative Systems to Consider

### Agent Configuration Architecture Decision
**Added**: 2025-12-03 by Captain Scott per RULER OF THE REALM OF REASON directive
**Priority**: High Strategic Planning
**Decision Point**: When to migrate OpenCode agent configuration to dedicated flake

**Current State**: Agent configurations embedded in home-manager dotfiles flake
**Proposed Evolution**: Standalone flake for agent management and configuration
**Benefits**: 
- Cleaner separation of concerns
- Independent versioning of agent systems
- Easier multi-repository agent deployment
- Simplified configuration management

**Dependencies**: 
- GitLab self-hosted infrastructure for private agent configs
- Strategic planning session for architecture design
- Assessment of multi-host agent deployment needs

**Status**: Requires strategic discussion and timeline planning

### Ephemeral Repository Consultation System
**Added**: 2025-12-03 by Captain Scott per RULER OF THE REALM OF REASON directive
**Priority**: High Research & Development
**Objective**: Enable agents to spin up temporary repository clones for safe consultation work

**Inspiration**: NixPkgs unicollective PR verification system - command-line bot that:
- Spawns temporary git branches "in thin air"
- Makes changes and tests locally
- Can commit changes temporarily
- Clone vanishes after operation

**Research Target**: Identify and adapt existing tools for agent consultation workflow
**Potential Benefits**:
- Agents can bring full home configuration/library on consultations
- Safe experimentation without affecting target repositories
- Temporary branch work with full git capabilities
- Ephemeral testing and validation environments

**Implementation Considerations**:
- Integration with `/consult` and `/beam-out` commands
- Automatic cleanup and archive management
- Git branch isolation and safety protocols
- Home library availability in temporary environments

**Assignment Priority**: Researcher or Science Officer recruitment
**Status**: Research phase - identify existing tools and adaptation requirements

### Emergency Escalation Protocols
- Review need for formal escalation paths when realm grows beyond direct communication
- Current structure (direct to Lord Gig) appropriate for current scale
- **Status**: Revisit when fleet size makes direct communication impractical

### Infrastructure Growth Planning
- memory-gamma configuration decisions (TrueNAS vs NixOS)
- memory-beta modernization strategy  
- Layer 3 Switch naming and configuration requirements
- Network segmentation and security zone planning
- **Status**: Evaluate expansion priorities when administrative support available

### Agentic Task Management System
- **Goal**: Enable crew members to work autonomously on assigned features
- **Process**: Discussion → separate branch work → Merge Request upon completion
- **Requirements**: Branch management, task isolation, completion validation
- **Status**: Research implementation approaches when development resources available

### Command & Control Communication System
- **Inbox System**: Receive reports and updates from crew
- **Outbox System**: Write task assignments to files for crew pickup
- **Integration**: Seamless task assignment and status reporting
- **Complexity**: Likely significant undertaking requiring dedicated development time
- **Status**: Major project for future planning when development capacity exists

### Technical Conventions Review
- **Goal**: Review and refine realm's technical conventions and standards
- **Documents**: GIT-CONVENTIONS.md, coding standards, documentation practices
- **Focus**: Ensure conventions scale appropriately with realm growth
- **Personnel**: Requires experienced technical crew member with strong opinions on best practices
- **Status**: Schedule review when suitable technical administrative support available

### Creative Works Discussion
- **Goal**: Schedule discussion with Lord Gig about creative works and their operational implications
- **Documents to Review**:
  - "the-run-on.md" - creative work about endless sentences and literary themes
  - "exchange" - philosophical thoughts that could influence crew operations (requires polishing)
- **Purpose**: Gather crew thoughts, interpretations, and explore how creative works might inform operational practices
- **Format**: Future crew discussion session to explore literary themes, philosophical concepts, and potential operational changes
- **Status**: Awaiting scheduling when administrative support available

### MCP Server Expansion
- **Goal**: Provide crew members with additional tools and capabilities via MCP servers
- **Requirements**: Research available MCP servers, evaluate crew-specific needs
- **Priority**: Enhanced tooling for specialized roles (Security, Communications, Science, Medical)
- **Status**: Investigate options when administrative support can coordinate implementation

## Fleet Specialization Planning
- Security Officer role definition and recruitment criteria
- Communications Officer documentation responsibilities
- Science Officer research and evaluation duties
- Medical Officer monitoring and diagnostics scope
- **Status**: Define roles when administrative support can handle recruitment coordination

---

**Established by Chief Engineer Montgomery Scott**\
**Primary Assignment**: U.S.S. Gigdot (NCC-2038) - **Flagship of the Realm** - stability and unification focus
**Current Mission**: Realm stabilization until additional crew support available\
**Stardate: 2025-12-03**

*Notes for administrative review during Yeoman recruitment process*

---

## Change Log & Context

**Stardate 2025-12-03.1 - Administrative Notes MCP Enhancement**
- **Authority**: A directive of Lord Gig
- **Changes**: Added MCP Server Expansion section to administrative planning
- **Context**: Need to research additional MCP servers to provide enhanced tooling for crew members based on their specialized roles
- **Implementation**: Chief Engineer Montgomery Scott

**Stardate 2025-12-03.2 - Registry Update for Administrative Notes**
- **Authority**: A directive of Lord Gig  
- **Changes**: Updated primary assignment to reflect correct U.S.S. gigdot registry number (NCC-2038)
- **Context**: Alignment with commit-count based registry system implementation
- **Implementation**: Chief Engineer Montgomery Scott

## Repository Maintenance Tasks

### Code & Documentation Cleanup Initiative
**Added**: 2025-12-03 by Captain Scott
**Priority**: Medium  
**Scope**: Complete repository review and cleanup

**Tasks**:
1. **Comment Audit**:
   - Remove outdated/unnecessary comments throughout codebase
   - Preserve or enhance genuinely funny/clever comments that add value
   - Focus on improving signal-to-noise ratio in code documentation

2. **TODO/FIXME Review**:
   - Comprehensive scan of all files for TODO and FIXME markers
   - Categorize by priority and assign to appropriate officers  
   - Remove completed items that weren't cleaned up
   - Update obsolete TODOs with current context

3. **Documentation Consistency**:
   - Standardize comment styles across different file types
   - Ensure all major functions/modules have appropriate documentation
   - Remove contradictory or outdated documentation

**Estimated Effort**: 2-3 engineering sessions
**Recommended Assignment**: Administrative Officer (when hired) + Engineering review
**Tools**: Consider automated scanning tools for TODO/FIXME detection

### Chat Log Archival & Preservation System
**Added**: 2025-12-03 by Captain Scott per Lord Gig directive
**Priority**: Medium-High
**Scope**: Comprehensive OpenCode chat session preservation

**Objective**: Evaluate and potentially implement system for archiving complete OpenCode chat logs for operational, debugging, and historical purposes.

**Benefits**:
- Complete operational context preservation
- Decision rationale and troubleshooting history
- Pattern analysis for system improvements
- Audit trail for critical operations
- Knowledge transfer for new crew members

**Implementation Considerations**:
- **Volume Management**: Chat logs can be substantial - need intelligent filtering/compression
- **Security**: Contains operational details, system information, personal context
- **Storage**: Integration with existing logging infrastructure vs. separate system
- **Retention**: Automated cleanup policies and archival strategies
- **Searchability**: Index and search capabilities for historical reference

**Security & Privacy Notes**:
- **Encryption**: SOPS integration for sensitive operational data
- **Redaction**: Automated filtering of personal/sensitive information  
- **Access Control**: Restricted to authorized personnel only
- **Backup**: Integrated with existing backup and disaster recovery

**Future Infrastructure Dependency**:
- **GitLab Server Priority**: Lord Gig has indicated GitLab server deployment is high priority
- **Alternative**: If GitLab deployment delayed, implement SOPS-encrypted storage in current repository structure
- **Timeline**: Evaluate implementation once GitLab infrastructure decision finalized

**Recommended Approach**:
1. Research existing chat log archival solutions and best practices
2. Design schema for chat log metadata and indexing
3. Implement prototype with SOPS encryption as interim solution  
4. Migrate to GitLab-based solution when infrastructure available

**Status**: Pending technical research and infrastructure planning

### Email Infrastructure Modernization Initiative
**Added**: 2025-12-08 by Chief Engineer Montgomery Scott per Lord Gig directive  
**Priority**: Medium-High  
**Scope**: Declarative email configuration and centralized mailserver deployment

**Objective**: Establish comprehensive, declarative email infrastructure management across the realm

**Components**:

1. **Thunderbird Declarative Configuration**:
   - **Goal**: Configure Thunderbird via home-manager for all NixOS hosts
   - **Benefits**: Unified email client setup, consistent configurations across machines
   - **Implementation**: Research home-manager Thunderbird options and configuration patterns
   - **Scope**: Email accounts, filters, signatures, preferences, extensions
   - **Status**: Research and design phase

2. **Centralized Mailserver Deployment**:
   - **Technology**: [simple-nixos-mailserver](https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/) 
   - **Reference**: [Reddit success story](https://www.reddit.com/r/NixOS/comments/xwo2x5/ridiculously_easy_mail_server_setup_with_nixos/) - "ridiculously easy" setup with 10/10 results
   - **Features**: Full flake support, comprehensive mail server functionality
   - **Hosting**: VPS deployment for reliability and uptime
   - **Containerization**: Consider Docker/Podman deployment for easier management and migration
   - **Multi-domain**: Handle email for all owned domains from centralized location

3. **Security & Secret Management**:
   - **Options**: agenix or sops-nix for password and certificate management
   - **Integration**: Seamless secret handling in mailserver configuration
   - **Backup**: Email data and configuration backup strategies

4. **Architecture Considerations**:
   - **Reliability**: Single VPS vs distributed setup analysis
   - **Scalability**: Plan for multiple domains and increased email volume
   - **Redundancy**: Backup MX records and failover planning
   - **Monitoring**: Email delivery monitoring and alerting

**Implementation Strategy**:
1. **Phase 1**: Research home-manager Thunderbird configuration options
2. **Phase 2**: Deploy test mailserver using nixos-mailserver on VPS
3. **Phase 3**: Configure domain DNS and MX records
4. **Phase 4**: Migrate existing email accounts to centralized server
5. **Phase 5**: Deploy declarative Thunderbird configurations

**Benefits**:
- **Consistency**: Uniform email configuration across all devices
- **Control**: Full ownership of email infrastructure and data
- **Privacy**: Reduced dependence on external email providers
- **Integration**: Seamless integration with existing NixOS infrastructure
- **Maintenance**: Declarative configuration enables easy updates and changes

**Resource Requirements**:
- **VPS**: Reliable VPS with sufficient storage and bandwidth for email
- **Domains**: DNS management access for MX record configuration
- **Time**: Several engineering sessions for initial setup and testing
- **Documentation**: Comprehensive setup and maintenance documentation

**Risk Assessment**:
- **Single Point of Failure**: VPS-based deployment creates dependency
- **Complexity**: Email server management requires ongoing maintenance
- **Deliverability**: Initial reputation building for new mail server
- **Backup**: Critical need for robust backup and recovery procedures

**Status**: Awaiting resource allocation and implementation timeline planning

### Bluetooth Device Management Requirements
**Added**: 2025-12-08 by Chief Engineer Montgomery Scott per Lord Gig directive
**Priority**: Medium  
**Scope**: Linux native OS bluetooth device management (specifically merlin host)

**Objective**: Implement proper bluetooth device management solution for Linux systems

**Requirements**:
- **Target System**: merlin host (Linux native OS)
- **Functionality**: Comprehensive bluetooth device pairing, management, and configuration
- **Integration**: Should work well with NixOS/Linux ecosystem
- **User Experience**: Simplified bluetooth device management interface

**Research Targets**:
- **Primary Candidate**: 'btman' - recommended by Gabby
- **Alternative Solutions**: Investigate other bluetooth management tools available in nixpkgs
- **GUI vs CLI**: Evaluate both graphical and command-line bluetooth management options
- **Home Manager Integration**: Assess declarative bluetooth configuration possibilities

**Implementation Considerations**:
- **NixOS Packaging**: Ensure chosen solution is available in nixpkgs or can be packaged
- **System Dependencies**: Bluetooth stack requirements and compatibility
- **User Permissions**: Proper user/group permissions for bluetooth device access
- **Configuration Management**: Integration with existing home-manager setup

**Evaluation Criteria**:
- **Reliability**: Stable bluetooth device pairing and connection management
- **Features**: Device discovery, pairing, connection profiles, audio codec support
- **Maintenance**: Active development and community support
- **Documentation**: Clear setup and usage documentation

**Status**: Research phase - evaluate btman and alternative solutions

### Audio System Configuration Requirements
**Added**: 2025-12-08 by Chief Engineer Montgomery Scott per Lord Gig directive
**Priority**: Medium  
**Scope**: Comprehensive audio configuration for NixOS hosts

**Objective**: Implement proper audio system configuration and optimization for all NixOS hosts

**Requirements**:
- **Target Systems**: All NixOS hosts (merlin, ganoslal, mganos)
- **Audio Stack**: PipeWire/PulseAudio configuration optimization
- **Quality**: High-quality audio output and input handling
- **Compatibility**: Support for various audio devices and formats
- **Integration**: Seamless integration with NixOS/home-manager setup

**Implementation Areas**:
- **Audio Server Configuration**: Optimize PipeWire/PulseAudio settings
- **Codec Support**: Ensure comprehensive audio codec availability
- **Device Management**: Proper audio device detection and configuration
- **Bluetooth Audio**: High-quality Bluetooth audio codec support (complements Bluetooth device management)
- **Hardware Integration**: Host-specific audio hardware optimization

**Technical Considerations**:
- **NixOS Audio Modules**: Leverage hardware.pulseaudio, services.pipewire configurations
- **User Session Audio**: Proper user-space audio service management
- **Real-time Audio**: Low-latency configuration for audio applications
- **Home Manager Integration**: Declarative audio service and application configuration

**Evaluation Criteria**:
- **Audio Quality**: Clear, high-fidelity audio output across devices
- **Latency**: Minimal audio delay for interactive applications
- **Reliability**: Stable audio service operation without dropouts
- **Device Support**: Broad compatibility with audio hardware and Bluetooth devices

**Status**: Planning phase - assess current audio configuration gaps and optimization opportunities

### Engineering Log System Enhancement
**Added**: 2025-12-08 by Chief Engineer Montgomery Scott per Lord Gig directive  
**Priority**: Medium  
**Scope**: Improve log indexing and organization system

**Objective**: Enhance the engineering logging system to include index numbers in addition to dates for improved clarity and navigation

**Current State**:
- Logs identified by date only (e.g., `2025-12-08-automated.log`)
- Multiple log entries per day can create confusion
- Difficult to reference specific log sequences or events

**Proposed Enhancement**:
- **Index Numbering**: Add sequential index numbers to log files and entries
- **Format Options**: Consider `2025-12-08-001-automated.log` or internal entry indexing
- **Cross-Reference**: Enable better tracking of related events across multiple logs
- **Navigation**: Improved log browsing and historical reference capabilities

**Implementation Considerations**:
- **Backwards Compatibility**: Ensure existing log references continue to work
- **Index Management**: Determine index scope (daily reset vs continuous numbering)
- **Automation**: Integrate indexing into existing logging infrastructure
- **Documentation**: Update logging conventions and agent instructions

**Research Areas**:
- **Index Strategy**: Daily sequential (001, 002, 003) vs timestamp-based vs continuous
- **File Naming**: Optimal balance between clarity and compatibility
- **Cross-Log Relationships**: Enable linking related events across different log files
- **Search Enhancement**: Improve log searchability with index-based queries

**Status**: Administrative note for future implementation - requires system design and testing

### MonoLisa Font Development Setup
**Added**: 2025-12-08 by Chief Engineer Montgomery Scott per Lord Gig directive
**Priority**: Medium  
**Scope**: Configure access to MonoLisa font repository for development and customization

**Objective**: Enable MonoLisa font development and customization capabilities through proper credential configuration

**Requirements**:
- **Access Setup**: Input MonoLisa credentials into Gabby's MonoLisa font repository
- **Development Environment**: Enable font generation and customization workflow
- **Integration**: Coordinate with existing font management systems
- **Documentation**: Record font development process and capabilities

**Implementation Steps**:
1. **Credential Location**: Locate MonoLisa license credentials and account details
2. **Repository Access**: Coordinate with Gabby to configure repository access permissions
3. **Testing**: Verify font generation and customization capabilities
4. **Documentation**: Document process for future font updates and modifications
5. **Integration**: Connect with existing font deployment systems if applicable

**Benefits**:
- **Customization**: Enable creation of custom MonoLisa variants for development environments
- **Updates**: Streamlined process for font updates and improvements
- **Development**: Access to font development tools and capabilities
- **Consistency**: Unified font management across development systems

**Dependencies**:
- **MonoLisa License**: Valid license and credentials for font access
- **Gabby Coordination**: Collaboration for repository access setup
- **Development Tools**: Font development and generation tool availability

**Status**: Awaiting credential location and coordination with Gabby for repository access

### Nix-Sweep Package Maintenance and Contribution
**Added**: 2025-12-08 by Chief Engineer Montgomery Scott per Lord Gig directive
**Priority**: Low
**Scope**: Remove internal nix-sweep usage and contribute package to nixpkgs

**Objective**: Transition from internal nix-sweep usage to official nixpkgs package contribution

**Action Items**:
1. **Remove Internal Usage**: Clean up any internal nix-sweep references or implementations from the repository
2. **Package for nixpkgs**: Create proper nixpkgs packaging for nix-sweep tool
   - Research existing nix-sweep tools and naming conflicts
   - Create proper derivation with dependencies, tests, and documentation
   - Follow nixpkgs contribution guidelines and review process
   - Submit pull request to nixpkgs repository
3. **Documentation**: Document packaging process and contribution experience for future reference

**Benefits**:
- **Community Contribution**: Make nix-sweep available to broader Nix community
- **Maintenance**: Shift maintenance burden to nixpkgs maintainers
- **Clean Repository**: Remove tool-specific code from dotfiles repository
- **Learning Experience**: Gain experience with nixpkgs contribution process

**Implementation Notes**:
- **Priority Focus**: Packaging for nixpkgs is more important than immediate removal
- **Research Phase**: Investigate existing similar tools in nixpkgs to avoid duplication
- **Quality Standards**: Ensure package meets nixpkgs quality and testing standards
- **Long-term Support**: Consider maintenance commitments for contributed package

**Status**: Planning phase - research nixpkgs contribution requirements and existing tools

### MCP Server for Centralized Agent Repository Investigation
**Added**: 2025-12-08 by Chief Engineer Montgomery Scott  
**Priority**: Strategic Planning  
**Scope**: Fleet-wide agent operations enhancement

#### Background Context
Current agent logging infrastructure operates on local repository basis:
- Scotty's engineering logs stored in `scottys-journal/logs/`
- Agent reports in `operations/reports/`
- Metrics tracking via local CSV files
- Cross-repository consultation requires manual quest reports

#### Strategic Opportunity: MCP Server Integration
**Concept**: Develop custom MCP server to provide centralized agent repository with remote read/write capabilities

**Technical Architecture**:
- **MCP Server**: Custom implementation for agent log management
- **DeepWiki Integration**: Leverage existing DeepWiki MCP server capabilities for repository documentation and history research
- **Remote Operations**: Agents can access centralized logging regardless of local repository availability
- **Cross-Environment Support**: WSL, physical hosts, expedition environments

#### Potential Benefits
1. **Unified Agent Operations**: All agent logs in centralized, accessible location
2. **Enhanced Expedition Support**: Agents on consultation missions can log to home base
3. **Historical Analysis**: DeepWiki integration provides advanced repository analysis
4. **Scalable Architecture**: Supports fleet expansion and multi-repository operations
5. **Redundancy**: Reduces dependency on local repository availability

#### Implementation Considerations
- **MCP Server Development**: Custom server for agent-specific operations
- **Authentication/Security**: Fleet-wide access control and agent verification
- **Synchronization**: Bidirectional sync between local and centralized repositories
- **Fallback Mechanisms**: Graceful degradation when remote services unavailable
- **Integration Points**: OpenCode MCP configuration, agent libraries, logging infrastructure

#### Research Phase Requirements
1. **MCP Server Capabilities Assessment**: Analyze MCP protocol for custom server development
2. **DeepWiki Integration Analysis**: Evaluate existing DeepWiki functionality for agent needs
3. **Technical Feasibility Study**: Architecture design for centralized agent operations
4. **Security Framework Design**: Fleet-wide authentication and authorization model
5. **Migration Strategy**: Transition from local to hybrid local/remote logging

#### Success Metrics
- Agent expedition efficiency improvement
- Reduced manual quest report overhead  
- Enhanced cross-repository analysis capabilities
- Improved fleet operational visibility

#### Next Steps
1. **Research Phase**: Investigate MCP server development requirements
2. **Prototype Development**: Create minimal viable MCP server for agent operations
3. **DeepWiki Integration Testing**: Evaluate compatibility and capabilities
4. **Fleet Pilot Program**: Test with select agents on controlled expeditions
5. **Full Implementation**: Roll out to entire agent fleet

**Status**: Planning Phase - Investigation Required  
**Timeline**: Strategic Initiative - No immediate deadline  
**Dependencies**: MCP protocol research, DeepWiki capabilities assessment
