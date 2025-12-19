# Starship Configuration Enhancement Notes

*Chief Engineer's technical documentation for improving Starship prompt configurations across the fleet*

## Overview & Purpose

These notes capture planned enhancements to Starship prompt configuration, with particular focus on improving battery information display and other useful status indicators for laptop hosts like merlin.

**PRIORITY**: Medium - Quality of life improvement for mobile engineering workstations  
**SCOPE**: Fleet-wide Starship configuration improvements  
**TARGET HOSTS**: All hosts, with special attention to laptop configurations (merlin)

---

## Current Configuration Analysis

### Existing Starship Setup
- **Location**: `home/gig/common/resources/starship.toml`
- **Integration**: Managed through home-manager configuration
- **Current Features**: Basic git status, command duration, directory display
- **Missing Elements**: Battery status, system performance indicators, enhanced mobile context

### Fleet Context Requirements
- **ganoslal**: Desktop workstation - power status less critical
- **merlin**: Laptop system - battery status CRITICAL for mobile operations
- **mganos**: Test configuration - should mirror ganoslal setup
- **wsl**: Windows subsystem - battery status may not be available/relevant

---

## Planned Battery Information Enhancements

### Primary Battery Module Configuration
```toml
[battery]
full_symbol = "🔋 "
charging_symbol = "⚡️ "
discharging_symbol = "💀 "
unknown_symbol = "❓ "
empty_symbol = "💀 "

# Display battery percentage and status
format = "[$symbol$percentage]($style) "

# Color coding based on battery level
[[battery.display]]
threshold = 15
style = "bold red"

[[battery.display]]
threshold = 30
style = "bold yellow"

[[battery.display]]
threshold = 50
style = "yellow"

[[battery.display]]
threshold = 100
style = "green"
```

### Alternative Battery Indicators
- **Discrete Symbols**: Use subtle Unicode battery symbols for minimal visual impact
- **Percentage Display**: Show exact percentage for precision engineering
- **Time Remaining**: Consider adding estimated time remaining when discharging
- **Charging Rate**: Display charging status with appropriate indicators

---

## Additional System Status Enhancements

### Performance Monitoring
```toml
# System load indicator
[memory_usage]
disabled = false
threshold = 75
symbol = "🐏 "
format = "via $symbol[$ram]($style) "
style = "bold dimmed white"

# CPU usage when available
[custom.cpu]
command = "grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$3+$4)} END {print usage\"%\"}"
when = "[ -r /proc/stat ]"
format = "[$output]($style) "
style = "bold blue"
```

### Network Status
```toml
# WiFi connection indicator for mobile hosts
[custom.wifi]
command = "iwgetid -r"
when = "command -v iwgetid"
format = "📶[$output]($style) "
style = "bold cyan"
```

### Temperature Monitoring
```toml
# CPU temperature for thermal management awareness
[custom.temp]
command = "sensors | grep 'Core 0' | awk '{print $3}' | cut -c2-3"
when = "command -v sensors"
format = "🌡️[$output°C]($style) "
style = "bold red"
```

---

## Host-Specific Configuration Strategy

### Conditional Module Loading
Implement host-detection logic to enable appropriate modules:

```toml
# Battery module enabled only on laptop hosts
[battery]
disabled = false
# Override disabled = true for desktop hosts via host-specific config

# Performance monitoring more aggressive on workstations
[memory_usage]
threshold = 85  # Higher threshold for desktop hosts
# threshold = 60 for laptop hosts where memory conservation matters
```

### Mobile vs Desktop Optimization
- **Mobile Hosts (merlin)**: Battery, WiFi, thermal monitoring, conservative memory thresholds
- **Desktop Hosts (ganoslal)**: Performance monitoring, higher resource thresholds, additional developer tools
- **Test Hosts (mganos)**: Mirror primary host configurations for consistency testing
- **WSL Environment**: Network status, performance monitoring, Windows-specific adaptations

---

## Time & Date Enhancements

### Enhanced Time Display
```toml
[time]
disabled = false
format = "🕐[$time]($style) "
time_format = "%H:%M:%S"
style = "bold white"
utc_time_offset = "local"
```

### Date Information
```toml
[custom.date]
command = "date '+%Y-%m-%d'"
when = "true"
format = "📅[$output]($style) "
style = "bold cyan"
```

---

## Git & Development Environment Improvements

### Enhanced Git Status
```toml
[git_status]
# More detailed git status information
ahead = "⇡${count}"
diverged = "⇕⇡${ahead_count}⇣${behind_count}"
behind = "⇣${count}"
deleted = "🗑"
modified = "📝"
staged = '[++\($count\)](green)'
renamed = "👅"
untracked = "🤷"
```

### Development Context
```toml
# Enhanced language version display
[rust]
symbol = "🦀 "
format = "via [$symbol($version)]($style) "

[nix_shell]
symbol = "❄️ "
format = 'via [$symbol$state( \($name\))]($style) '
```

---

## Implementation Planning

### Phase 1: Battery Essentials
1. **Basic Battery Module**: Implement simple battery percentage and charging status
2. **Color Coding**: Add appropriate color schemes for battery levels
3. **Host Detection**: Ensure battery module only activates on laptop hosts
4. **Testing**: Verify battery status accuracy on merlin

### Phase 2: System Monitoring
1. **Memory Usage**: Add memory monitoring with appropriate thresholds
2. **Temperature**: Implement thermal monitoring for mobile thermal management
3. **Network Status**: Add WiFi connection status for mobile awareness
4. **Performance Tuning**: Optimize update frequencies and resource usage

### Phase 3: Enhanced Information
1. **Time/Date Display**: Add comprehensive time and date information
2. **Git Improvements**: Enhance git status display with additional context
3. **Development Tools**: Improve language version and environment indicators
4. **Custom Modules**: Implement any additional custom status modules

### Phase 4: Fleet Optimization
1. **Host-Specific Tuning**: Optimize configurations for each host's role
2. **Performance Testing**: Verify prompt performance across all systems
3. **Documentation**: Create comprehensive configuration documentation
4. **Maintenance**: Establish update and maintenance procedures

---

## Technical Implementation Notes

### Configuration Management
- **File Location**: Continue using `home/gig/common/resources/starship.toml`
- **Home Manager Integration**: Leverage existing home-manager starship module
- **Host Overrides**: Implement host-specific overrides where necessary
- **Testing Strategy**: Use mganos for configuration testing before fleet deployment

### Performance Considerations
- **Update Intervals**: Balance information freshness with system performance
- **Command Execution**: Minimize expensive shell command executions in prompt
- **Resource Monitoring**: Ensure prompt enhancements don't impact system performance
- **Battery Impact**: Optimize for minimal battery drain on mobile hosts

### Compatibility Requirements
- **Cross-Platform**: Ensure configurations work across Linux distributions
- **Tool Dependencies**: Document any required tools (sensors, iwgetid, etc.)
- **Graceful Degradation**: Handle missing tools gracefully
- **Version Compatibility**: Maintain compatibility with current Starship versions

---

## Future Enhancement Opportunities

### Advanced Battery Features
- **Battery Health Monitoring**: Track battery capacity degradation over time
- **Power Profile Integration**: Display current power management profile
- **Charging Speed**: Show charging rate when connected to power
- **Battery History**: Maintain usage patterns and optimization suggestions

### System Integration
- **Systemd Status**: Monitor critical service status
- **Disk Usage**: Alert when storage space becomes critical
- **Network Performance**: Monitor connection quality and speed
- **Security Status**: Display system security posture indicators

### Development Workflow
- **Build Status**: Integration with ongoing build processes
- **Git Workflow**: Enhanced branch and merge status information
- **Container Status**: Docker/Podman container status when relevant
- **Package Updates**: Available system and package updates

---

## Engineering Recommendations

### Implementation Priority
1. **IMMEDIATE**: Basic battery status for mobile operations
2. **SHORT-TERM**: System monitoring and performance indicators  
3. **MEDIUM-TERM**: Enhanced development environment integration
4. **LONG-TERM**: Advanced monitoring and fleet optimization

### Quality Assurance
- **Testing Protocol**: Test all configurations on each host before deployment
- **Performance Monitoring**: Track prompt response times during implementation
- **User Experience**: Ensure enhancements improve rather than clutter interface
- **Documentation**: Maintain comprehensive configuration documentation

### Maintenance Planning
- **Regular Updates**: Keep Starship version current for new features
- **Configuration Audits**: Periodically review and optimize configurations
- **Performance Tuning**: Monitor and optimize prompt performance
- **Feature Evolution**: Adapt configurations as tools and workflows evolve

---

*These notes provide the foundation for systematic Starship enhancement across the fleet. Implementation should proceed methodically with thorough testing at each phase.*

---

**ENGINEERING AUTHORITY**: Chief Engineer Montgomery Scott  
**DOCUMENTATION DATE**: 2025-12-19  
**FLEET STATUS**: Planning Phase - Implementation Pending Captain Authorization  
**TECHNICAL CLASSIFICATION**: System Enhancement - Quality of Life Improvement
