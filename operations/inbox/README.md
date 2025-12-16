# Operations Inbox

## Purpose
This directory serves as Captain's operational inbox for items requiring review, approval, or action.

## Priority Levels
Files should include priority in their content:
- **URGENT**: Immediate attention required (billing, security, critical failures)
- **HIGH**: Important but not blocking operations 
- **MEDIUM**: Standard operational decisions
- **LOW**: Optimization, cleanup, future planning

## Workflow
1. **Agents**: File reports, recommendations, and items requiring attention here
2. **Captain**: Reviews items, adds notes/annotations as needed  
3. **Captain**: Approves by moving to `../outbox/` OR creates response files
4. **Agents**: Process approved items from outbox when directed

## File Naming Convention
- `YYYY-MM-DD_brief-description.md`
- Include priority in content header
- Keep descriptions concise but descriptive

## Quick Commands (Future)
- `just inbox` - List current inbox items with priorities
- `just inbox-status` - Show count by priority level
- `just outbox-process` - Process approved items from outbox

## Status Indicators
- Items can be annotated with Captain's notes inline
- Create `.captain-notes` files for longer commentary
- Move to outbox when ready for implementation
- Delete if no action needed (document decision in file)
