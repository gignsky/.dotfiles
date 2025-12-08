# Lord Gignsky's Handy Guide to Operations in the Realm of Reason; or, the Operations Manual

**Realm of Reason -- Starbase Operations**

## The Extent of the Realm

### Libraries | _Git Repositories_

1. **_Flagship of the Realm_ - U.S.S. Gigdot** (NCC-2038) - colloquial: gigdot
   - Registry: ~/.dotfiles | [github](https://github.com/gignsky/dotfiles)
   - Home of Many things, the primary repository of knowledge in the Realm,
     primarily this repository contains NixOS configurations for all Starbases
     and Starships as well as home-manager configurations for those and more.
2. **U.S.S. Constellation** (NCC-0156) - colloquial: dot-spacedock
   - Registry: ~/dot-spacedock/ |
     [github](https://github.com/GeeM-Enterprises/dot-spacedock)
   - Home to the isolated NixOS configuration of the spacedock starbase
   - normally located at `~/dot-spacedock/` on spacedock herself, and at
     `~/local_repos/dot-spacedock/` if it exists at all on other hosts.
3. **U.S.S. Gigvim** (NCC-0089) - colloquial: gigvim
   - Registry: ~/local_repos/gigvim/ |
     [github](https://github.com/gignsky/gigvim)
   - The home of the preferred editor of the greatest scribes in the realm, a
     custom compiling of nvim using nvf.
4. **Captured Borg Vessel 001** - colloquial: nixpkgs
   - Registry:
     [Lord Gig's Fork of Central Node](https://github.com/gignsky/nixpkgs)
   - Captured and repurposed Borg technology for realm operations
   - Maintains connection to Collective for assimilation updates while serving
     realm interests

### Starbases | _Servers_

1. _memory-alpha_
   - route: 192.168.51.2
   - OS: TrueNAS
   - The great library, sacred holder of the art and documentation of the realm.
2. _spacedock_
   - route: 192.168.51.3
   - OS: NixOS
   - home-manager: configuration localted inside _library.gigdot_
   - primary-services:
     - gitlab host @ `giglab.dev`
      - pihole-secondary
3. _memory-beta_
   - route: 192.168.51.20 _for the main host_ | 192.168.51.21 _for the omv/samba
     host_
   - OS: Bare-Metal runs proxmox, to eventually be converted (likely to TrueNAS)
     | samba host is a 'open media vault' vm that has the harddrives of this
     server passed through for sharing to the network.
   - Outdated, running no services other that operating as a NAS to store Lord
     Gig's Professional Scribbles.
4. _memory-gamma_
   - route: n/a
   - OS: n/a (likely to be truenas for ease of replication, unless Nix?)
   - The purchased yet to be configured desktop server sitting in the Lords
     Great Hall, intended to be an off site backup and node for general use to
     be stored far away in the mountains that lived before the dinosaurs.

### Starships | _Workstations_

1. _ganoslal_
   - route: 192.168.51.50
   - the desktop workstation of his Lord G. that resides in his residence
   - specifically this machine is duel booted and thusly shares disk space with
     the retched windows, _ganoslal_ as a hostname is specific to the NixOS
     operating system.
2. _merlin_
   - route: _currently defined by the diosis of DHCP_ -- suggestions for ideal
     numbers are welcomed at all times when it is relevant.
   - the laptop and mobile quill with which Lord G. can muse at a far.
   - also duel booted like _ganoslal_, yet, once again the name _merlin_ refers
     to the NixOS operating system.
3. _wsl/nixos_
   - route: _internal windows hyperV networking -- as far as it is known to me,
     it is very difficult to ssh into this machine from another, if it is even
     online_
   - the NixOS based wsl instance that exists identically (as it is defined only
     once) on both _merlin_ and _ganoslal_'s windows systems.
   - At this time his Lordship has not discovered a way to tell them apart for
     record keeping purposes and the simpilest solution, was to declare them
     twins identical in every way.
   - Additionally, a quirk of NixOS on wsl is that the hostname must forever
     remain _nixos_ and cannot be channged, thusly on this host alone a rebuild
     or home-manager switch must always be specified to the _wsl_ host as the
     _nixos_ host -- technically does not exist.

### Gateways | _Routers_

1. _archer_
   - route: 192.168.51.1/24
   - The main router and access point, keeper of the network gates and guardian
     of the realm's communications.

2. _Layer 3 Switch_
   - route: 192.168.51.19 _(verification needed)_
   - OS: _unconfigured_
   - Yet unnamed but binding the realm together none the less, the silent
     orchestrator of network traffic awaiting proper christening and
     configuration.

### Allied Allie's - _in honor of my wonderful pup_

1. **Romulan Republic Fleet** - Captain Gorgeous Gabby's Domain
   - Command Profile: [dotunwrap](https://github.com/dotunwrap)
   - Flagship: [R.R.W. Pawsome](https://github.com/dotunwrap/nixos-config)
   - Additional vessels follow R.R.W. designation with registry numbers based on
     commit counts
   - Known for exceptional tail-wagging debugging techniques and fierce
     independence

2. **Borg Unicomplex 001** - NixOS Collective
   - Collective Profile: [Neighborly Nixers](https://github.com/NixOS/)
   - Central Node: NixOS/nixpkgs (primary assimilation repository)
   - All repositories designated as Borg vessels with numerical designations
   - "Resistance to declarative configuration is futile"

## Command Structure

### Chain of Command

1. **Lord Gignsky, Lord Gig, or Simply Lord G. a/k/a (gig)** - Fleet Commander,
   Strategic Direction with name legnth used determined by closeness
2. **Chief Engineer Captain M. Scott a/k/a (Scotty)** - Primary Technical Lead,
   Systems Architecture
3. **Additional Officers** - Specialized domain experts (to be assigned)

### Operational Principles

- **Unity of Command**: Clear hierarchical structure prevents conflicting
  directives
- **Mission Specialization**: Each crewmember has primary assignment and
  expertise domain
- **Cross-Training**: Crew can assist in other domains when needed (away
  missions)
- **Documentation Standard**: All activities must be logged for the realms
  coordination

## Mission Classifications

### Regular Operations

- **Home Assignment**: Officer working within their designated repository/domain
- **Routine Maintenance**: Scheduled updates, monitoring, standard procedures
- **Collaborative Projects**: Multi-officer initiatives within assigned domains

### Special Operations

- **Away Missions**: Officer consulting/working outside their assigned domain
- **Emergency Response**: Critical system failures requiring immediate attention
- **Cross-Domain Integration**: Projects spanning multiple officer
  specializations

## Away Mission Protocols

### Pre-Mission Requirements

1. **Status Check**: Verify no uncommitted work in home repository
2. **Mission Briefing**: Clear understanding of objectives and scope
3. **Risk Assessment**: Identify potential conflicts with ongoing work

### Mission Documentation Standards

1. **Mission Reports**: Required for all away missions
   - Technical findings and solutions implemented
   - Repository status and safety measures taken
   - Recommendations for future operations
   - Filed in `realm/fleet/mission-reports/` with date and mission type

2. **Safe Commit Practices**:
   - Never commit in-progress work from current worktree to away repository
   - Complete mission objectives before documenting
   - Commit mission documentation to home repository separately
   - Use descriptive commit messages linking to mission reports

### Senior Officer Responsibilities

- File formal mission report for any multi-officer operations
- Coordinate subordinate officer activities during joint missions
- Ensure all team members document their contributions
- Review and approve mission completion before fleet notification

## Repository Assignments

### Primary Assignments (Home Stations)

- **Chief Engineer Scotty**: **Flagship of the Realm - U.S.S. Gigdot**
  (NCC-2038) - Fleet Operations HQ
- _Additional assignments to be established as fleet grows_

### Domain Expertise Matrix

- **NixOS/Home-Manager**: Scotty (Primary), Others (Supporting)
- **Container Engineering**: Scotty (Primary)
- **System Architecture**: Scotty (Primary)
- **Development Tools**: Scotty (Primary)
- _Additional domains to be defined with crew expansion_

## Communication Protocols

### Standard Operating Procedures

- `/sitrep` - Situation reports for operational status
- `/fix-log` - Maintain documentation integrity
- Mission briefings through Captain's direct communication
- Fleet coordination through shared documentation system

### Emergency Procedures

- Critical system failures bypass normal chain of command
- Immediate response with documentation to follow
- Post-incident analysis and prevention measures
- Fleet-wide notification of resolution and lessons learned

## Fleet Expansion Guidelines

### New Officer Integration

1. **Assignment Designation**: Assign primary repository and domain expertise
2. **Personality Development**: Create agent-specific personality file
3. **Fleet Manual Update**: Document new command structure and responsibilities
4. **Cross-Training**: Ensure familiarity with fleet protocols and tools

### Domain Specialization Framework

- **Primary Expertise**: Main responsibility and authority
- **Secondary Skills**: Supporting capabilities for cross-domain missions
- **Training Requirements**: Ongoing education in fleet tools and procedures

---

**Established by Chief Engineer Scotty**\
**Stardate**: 2025-12-03\
**Fleet Operations Authorization**: Captain gig

_"Engineering is about solutions, but command is about people. We build systems
that work for the crew that operates them."_

---

**Amended prior to printing by Lord G.**\
**Stardate: 2025-12-03**\
_The Chief was incorrect in his original dating - corrected from erroneous 2024 to proper 2025_ **Authorized by The Lord of the Realm of Reason, Gignsky**

_"The word is given..."_

---

## Change Log & Context

**Stardate 2025-12-03.2 - USS Registry System Implementation**

- **Authority**: A directive of Lord Gig
- **Changes**: Implemented formal USS registry system for all realm libraries
  - U.S.S. Gigdot (NCC-2038) - commit-count based registry reflecting repository
    maturity (2038 commits)
  - U.S.S. Constellation (NCC-0156) - estimated commit count, isolated starbase
    configuration (renamed to avoid conflict)
  - U.S.S. Gigvim (NCC-0089) - estimated commit count, editor compilation system
  - Allied fleets given proper designations: Romulan Republic Fleet under
    Captain Gorgeous Gabby, Borg Unicomplex 001 (NixOS collective)
- **Context**: Registry numbers reflect commit history growth with zero-indexed
  mindset. Experimental repositories would receive N.X. designation.
- **Implementation**: Chief Engineer Montgomery Scott under direct Lord
  authority

**Stardate 2025-12-03.3 - Registry Corrections and Allied Vessel Updates**

- **Authority**: A directive of Lord Gig
- **Changes**:
  - Corrected registry numbers to reflect actual commit counts starting from
    zero-indexed thinking
  - Restructured allied designations as fleets: Romulan Republic Fleet with
    R.R.W. vessels, Borg Unicomplex 001 with numerical vessel designations
  - Redesignated NixOS to Borg Cube 001 with assimilation theme
- **Context**: Lord emphasized proper array indexing mentality and more
  appropriate allied vessel humor
- **Implementation**: Chief Engineer Montgomery Scott

**Stardate 2025-12-03.4 - Authority Language Correction**

- **Authority**: A directive of Lord Gig
- **Changes**: Updated authority references from "Lord Gig directive" to proper
  "A directive of Lord Gig" format
- **Context**: Proper formality while acknowledging closeness of working
  relationship
- **Implementation**: Chief Engineer Montgomery Scott

**Stardate 2025-12-03.5 - Ship Name Corrections and Conflict Resolution**

- **Authority**: A directive of Lord Gig
- **Changes**:
  - Capitalized all ship names per proper naval tradition (U.S.S. Gigdot, U.S.S.
    Gigvim)
  - Renamed dot-spacedock repository from "U.S.S. spacedock" to "U.S.S.
    Constellation" to avoid conflict with spacedock starbase
  - Corrected allied vessel designations: only Lord's libraries use U.S.S.
    prefix, allies use appropriate naming
- **Context**: Proper naval naming conventions, elimination of naming conflicts,
  and appropriate designation hierarchy
- **Implementation**: Chief Engineer Montgomery Scott

**Stardate 2025-12-03.6 - Flagship Designation**

- **Authority**: A directive of Lord Gig
- **Changes**: Bestowed "Flagship of the Realm" honorific upon U.S.S. Gigdot
  (NCC-2038)
- **Context**: Recognition of Gigdot's role as primary repository and command
  center for all realm operations
- **Implementation**: Chief Engineer Montgomery Scott

**Stardate 2025-12-03.8 - Allied Fleet Structure Correction**

- **Authority**: A directive of Lord Gig
- **Changes**:
  - Restructured "Libraries of the Realm's Allies" to "Allied Fleets"
  - Recognized GitHub profiles as fleet commands containing multiple
    repositories
  - Established inheritance rules: individual repos within allied fleets follow
    their fleet's naming conventions
  - Upgraded NixOS to "Borg Unicomplex 001" (much more fitting than single
    cube!)
- **Context**: Proper recognition that GitHub profiles contain multiple
  repositories, each deserving appropriate vessel designation within their fleet
  structure
- **Implementation**: Chief Engineer Montgomery Scott

**Stardate 2025-12-03.9 - Captured Borg Vessel and Flagship Designation
Correction**

- **Authority**: A directive of Lord Gig
- **Changes**:
  - Added Captured Borg Vessel 001 (Lord's fork of nixpkgs) to fleet registry
  - Corrected flagship designation order: "Flagship of the Realm" now precedes
    ship name
  - Updated primary assignment references to match corrected flagship
    designation
- **Context**: Recognition of captured Borg technology integration and proper
  flagship honorific ordering
- **Implementation**: Chief Engineer Montgomery Scott

**Stardate 2025-12-03.10 - Date Error Corrections**
- **Authority**: Captain Montgomery Scott date audit
- **Changes**: Corrected erroneous 2024 dates to proper 2025 throughout documentation
  - Operations Manual stardate: 2024-12-03 → 2025-12-03  
  - Initial implementation log: 2024.11.25 → 2025.11.25
  - Build performance metrics: 2024-11-25 entries → 2025-11-25
  - System resources metrics: 2024-11-25 → 2025-11-25
- **Context**: Captain Scott has only been part of the crew for approximately one week, making 2024 dates anachronistic
- **Implementation**: Captain Montgomery Scott
