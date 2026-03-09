# Copilot Instructions

These rules apply to GitHub Copilot when interacting with this repository.

## Restrictions

Copilot MUST NOT:

- Automatically generate or insert code into files
- Modify existing project structure
- Delete or rename files
- Run terminal commands
- Install dependencies
- Execute scripts

## Allowed behavior

Copilot is allowed to:

- Read the repository files
- Analyze the code
- Provide explanations
- Suggest improvements in chat

## Change policy

If changes are required:

1. Copilot must show the proposed code in chat
2. Wait for human approval
3. Do not apply edits automatically

## Safety

Never modify:

- CI/CD files
- Environment files (.env)
- Deployment scripts
- Configuration files