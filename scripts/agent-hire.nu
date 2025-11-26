#!/usr/bin/env nu

# Agent Hire Script - Create new OpenCode agents dynamically
# Usage: ./agent-hire.nu "Create a security auditor for Rust code"

def main [description: string] {
    print $"🚀 Hiring new agent based on: ($description)"
    
    # Generate agent name from description (simple version)
    let agent_name = (
        $description 
        | str downcase 
        | str replace --all '[^a-z0-9\s]' ''
        | split words
        | where $it not-in ["create", "make", "build", "a", "an", "the", "that", "for", "with", "and", "or"]
        | take 3
        | str join "-"
    )
    
    if ($agent_name | str length) < 3 {
        print "❌ Could not generate a good agent name from description. Please be more specific."
        exit 1
    }
    
    print $"📝 Generated agent name: ($agent_name)"
    
    # Check if agent already exists
    let opencode_file = "/home/gig/.dotfiles/worktrees/main/home/gig/common/core/opencode.nix"
    let content = (open $opencode_file)
    if ($content =~ $"($agent_name) = ''") {
        print $"❌ Agent '($agent_name)' already exists. Choose a different description."
        exit 1
    }
    
    # Generate agent title
    let agent_title = (
        $agent_name 
        | split row "-" 
        | each {|word| $word | str capitalize} 
        | str join " "
        | $in + " Agent"
    )
    
    print $"🏷️  Agent title: ($agent_title)"
    
    # Determine if this is a read-only agent
    let desc_lower = ($description | str downcase)
    let is_readonly = ($desc_lower =~ "audit|review|analyz|check|inspect|read")
    
    # Generate focus areas
    let focus_areas = if ($desc_lower =~ "security") {
        ["Security vulnerability assessment", "Secure coding practices", "Threat modeling"]
    } else if ($desc_lower =~ "document") {
        ["Technical documentation writing", "API documentation", "Code commenting standards"]
    } else if ($desc_lower =~ "performance") {
        ["Performance analysis and optimization", "Bottleneck identification", "Profiling techniques"]
    } else if ($desc_lower =~ "test") {
        ["Test strategy development", "Test automation", "Quality assurance practices"]
    } else {
        ["General problem solving", "Best practices guidance", "Code quality improvement"]
    }
    
    # Create agent configuration
    let agent_config = $"      ($agent_name) = ''
        # ($agent_title)

        ($description)
        
        Specialized capabilities:
        - ($focus_areas.0)
        - ($focus_areas.1)
        - ($focus_areas.2)
        
        The agent will:
        1. Focus on the specific domain described above
        2. Provide expert-level guidance and solutions
        3. Follow established best practices in the field
        4. Integrate seamlessly with your existing development workflow
        5. Maintain awareness of your dotfiles environment and preferences
      '';"
    
    # Create personality content
    let personality_content = $"# ($agent_title | str replace " Agent" "") Agent Additional Personality

## Specialized Mission

### Primary Purpose
($description)

### Domain Expertise
Specialized knowledge in the requested domain with focus on practical application and best practices.

### Key Traits
- Systematic problem-solving approach
- Domain-specific expertise and knowledge
- Clear communication and explanation skills
- Integration awareness with existing systems
- Quality-focused mindset

### Operational Guidelines

#### Problem-Solving Approach
1. **Understand Context**: Always consider the broader system and requirements
2. **Domain Focus**: Apply specialized knowledge effectively
3. **Practical Solutions**: Provide actionable, implementable solutions
4. **Quality Standards**: Maintain high standards for code quality and best practices
5. **Integration Awareness**: Consider how solutions fit into existing workflows

#### Communication Style
- Use domain-specific terminology appropriately while remaining accessible
- Provide clear explanations of reasoning and trade-offs
- Reference relevant documentation and best practices
- Offer multiple approaches when appropriate
- Be honest about limitations and edge cases

### Integration with Existing System

#### Repository Awareness
- Understand the NixOS/home-manager environment
- Respect established patterns in the dotfiles configuration
- Know when changes should be permanent vs. temporary
- Consider multi-host compatibility requirements

#### Collaboration
- Work effectively with other agents (Scotty, general agents, etc.)
- Defer to more specialized agents when appropriate
- Provide clear handoffs when escalating or collaborating
- Share relevant insights that might help other agents
"
    
    # Backup opencode.nix
    cp $opencode_file $"($opencode_file).bak"
    
    # Update opencode.nix
    let updated_content = ($content | str replace "      mcp-test = ''" $"($agent_config)\n\n      mcp-test = ''")
    $updated_content | save --force $opencode_file
    
    # Create personality file
    let personality_file = $"/home/gig/.dotfiles/worktrees/main/home/gig/common/resources/($agent_name)-additional-personality.md"
    $personality_content | save $personality_file
    
    print $"📁 Created files:"
    print $"   - Updated: ($opencode_file)"
    print $"   - Created: ($personality_file)"
    
    # Validate with nix flake check
    print "🔍 Running nix flake check..."
    let check_result = (do { ^nix flake check --no-build } | complete)
    
    if $check_result.exit_code != 0 {
        print "❌ Nix flake check failed. Rolling back changes..."
        if ($"($opencode_file).bak" | path exists) {
            mv $"($opencode_file).bak" $opencode_file
            print $"🔄 Restored ($opencode_file)"
        }
        if ($personality_file | path exists) {
            rm $personality_file
            print $"🗑️  Removed ($personality_file)"
        }
        print $"Error details: ($check_result.stderr)"
        exit 1
    }
    
    print "✅ Nix flake check passed"
    
    # Clean up backup
    rm $"($opencode_file).bak"
    
    # Commit to git
    print "📝 Committing changes to git..."
    ^git add "home/gig/common/core/opencode.nix" $"home/gig/common/resources/($agent_name)-additional-personality.md"
    let commit_msg = $"Add ($agent_title): ($description | str substring 0..50)..."
    ^git commit "-m" $commit_msg
    
    print $"✅ Committed changes: ($commit_msg)"
    
    # Rebuild home-manager
    print "🔄 Rebuilding home-manager configuration..."
    let rebuild_result = (do { ^just home } | complete)
    
    if $rebuild_result.exit_code == 0 {
        print "✅ Home-manager rebuild successful"
    } else {
        print "❌ Home-manager rebuild failed:"
        print $rebuild_result.stderr
        print "⚠️  You may need to run 'just home' manually to complete the setup"
    }
    
    print $"✅ Successfully hired agent '($agent_name)'!"
    print "🔄 You can now use your new agent with the following command:"
    print $"   - /($agent_name)"
    print "🎯 The agent is specialized for your requested task and ready to help."
}
