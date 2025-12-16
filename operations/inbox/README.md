# Operations Inbox

## Purpose
This directory serves as Captain's operational inbox for items requiring review, approval, or action.

## Workflow (Planned)
1. **Agents**: File reports, recommendations, and items requiring attention here
2. **Captain**: Reviews items, adds notes/annotations as needed
3. **Captain**: Approves items by moving them to `../outbox/` 
4. **Agents**: Process approved items from outbox when directed

## Current Contents
- Engineering reports from away missions/consultations
- Strategic analyses requiring command review
- Administrative items pending decision

## File Naming Convention
- Use ISO date format: `YYYY-MM-DD_description.md`
- Keep descriptions concise but descriptive
- Maintain consistency with existing fleet documentation standards

## Status Tracking (Future)
- [ ] Implement status metadata in file headers
- [ ] Create review workflow automation
- [ ] Integrate with agent task queuing system
