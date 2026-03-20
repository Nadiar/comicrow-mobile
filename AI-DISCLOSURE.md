# AI Disclosure

This project was developed with significant assistance from AI tools.

## Tools Used

- **Claude Code** (Anthropic) — Architecture design, code generation, refactoring, test writing, and code review
- **GitHub Copilot** — Inline code suggestions during development

## What This Means

- The majority of source code, tests, and documentation was generated or substantially shaped by AI
- A human developer reviewed, directed, and approved all changes
- AI-generated code has been analyzed (`flutter analyze`) and tested (`flutter test`) but may still contain issues typical of AI-assisted codebases

## Why Disclose This

Transparency about AI involvement helps contributors and users:

- **Set expectations** — AI-generated code can have patterns that differ from hand-written code (e.g., over-documentation, structural duplication, unnecessary abstractions)
- **Inform review** — Reviewers should apply the same scrutiny as any other code, knowing that AI can produce plausible-looking but subtly incorrect logic
- **Respect attribution** — AI tools are a meaningful part of how this code was produced

## Contributing

Contributions are welcome regardless of whether they are written by hand, with AI assistance, or a mix of both. All contributions go through the same review process.
