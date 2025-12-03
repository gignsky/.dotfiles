# Lord Gignsky's Handy Guide to Operations in the Realm of Reason; or, the Operations Manual

**Realm of Reason -- Starbase Operations**

## The Extent of the Realm

### Libraries | _Git Repositories_

1. [gigdot](~/.dotfiles) or on [github](https://github.com/gignsky/dotfiles)
   - Home of Many things, the primary repository of knowledge in the Realm,
     primarily this repository contains NixOS configurations for all Starbases
     and Starships as well as home-manager configurations for those and more.
2. [dot-spacedock](~/dot-spacedock/) or on
   [github](https://github.com/GeeM-Enterprises/dot-spacedock)
   - Home to the isolated NixOS configuration of the spacedock starbase
   - normally located at `~/dot-spacedock/` on spacedock herself, and at
     `~/local_repos/dot-spacedock/` if it exists at all on other hosts.
3. [gigvim](~/local_repos/gigvim/) or on
   [github](https://github.com/gignsky/gigvim)
   - The home of the preferred editor of the greatest scribes in the realm, a
     custom compiling of nvim using nvf.

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
     - pihole-slave
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

### Libraries of the Realm's Allies

1. [Gorgeous Gabby](https://github.com/dotunwrap)

2. [Neighborly Nixers](https://github.com/NixOS/)

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
   - Filed in `fleet/mission-reports/` with date and mission type

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

- **Chief Engineer Scotty**: `libraries.gigdot` (Fleet Operations HQ)
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
**Stardate**: 2024-12-03\
**Fleet Operations Authorization**: Captain gig

_"Engineering is about solutions, but command is about people. We build systems
that work for the crew that operates them."_

---

**Amended prior to printing by Lord G.**\
**Stardate: 2025-12-03**\
_The Chief is incorrect in his prior dating he edited this file in the year
2024_ **Authorized by The Lord of the Realm of Reason, Gignsky**

_"The word is given..."_

