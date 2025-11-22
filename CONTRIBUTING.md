# Contributing to Dakota Phone Automation System

Thank you for your interest in contributing to the Dakota Phone Automation System! This document provides guidelines for contributing to this project.

## How to Contribute

### Reporting Bugs

If you find a bug, please open an issue with:
- A clear, descriptive title
- Steps to reproduce the issue
- Expected behavior
- Actual behavior
- Environment details (OS, Docker version, etc.)
- Relevant logs or error messages

### Suggesting Enhancements

For feature requests or enhancements:
- Check if the feature has already been requested
- Provide a clear description of the enhancement
- Explain why this enhancement would be useful
- Include examples of how it would work

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Make your changes** following the code style guidelines
3. **Test your changes** thoroughly
4. **Update documentation** if needed
5. **Submit a pull request** with a clear description

## Development Setup

1. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/sc9-dakota-system.git
   cd sc9-dakota-system
   ```

2. Set up the development environment:
   ```bash
   cp .env.example .env
   # Edit .env with your credentials
   ./scripts/setup.sh
   ```

3. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Code Style Guidelines

### Shell Scripts
- Use `#!/bin/bash` shebang
- Set `set -e` for error handling
- Add comments for complex logic
- Use meaningful variable names
- Include error messages with emoji indicators (✅, ❌, ⚠️)

### n8n Workflows
- Use descriptive node names
- Add comments in Function nodes
- Follow consistent naming conventions
- Include error handling nodes
- Test workflows before committing

### Documentation
- Use clear, concise language
- Include code examples where applicable
- Update relevant docs when changing functionality
- Follow markdown formatting standards

### Docker Configuration
- Use official base images
- Include health checks
- Set proper resource limits
- Document environment variables

## Testing

Before submitting a PR:

1. **Test locally**:
   ```bash
   docker-compose up -d
   # Test workflows manually
   ```

2. **Verify JSON syntax**:
   ```bash
   for file in n8n/workflows/*.json; do
     python3 -m json.tool "$file" > /dev/null
   done
   ```

3. **Test scripts**:
   ```bash
   bash -n scripts/*.sh  # Syntax check
   ./scripts/setup.sh    # Full test
   ```

4. **Check documentation links**:
   - Ensure all internal links work
   - Verify code examples are accurate

## Commit Message Guidelines

Use clear, descriptive commit messages:

```
Add feature to automatically retry failed calls

- Implement exponential backoff for call retries
- Add retry counter to call logs table
- Update documentation with retry configuration
```

### Commit Message Format
- Use present tense ("Add feature" not "Added feature")
- Use imperative mood ("Move cursor to..." not "Moves cursor to...")
- First line should be 50 characters or less
- Include detailed description if needed

## Workflow Changes

When modifying n8n workflows:

1. **Export from n8n UI** after making changes
2. **Pretty-print JSON** for readability:
   ```bash
   python3 -m json.tool workflow.json > workflow-formatted.json
   mv workflow-formatted.json workflow.json
   ```
3. **Test thoroughly** in n8n UI before committing
4. **Update documentation** if workflow behavior changes

## Documentation Updates

When updating documentation:
- Keep README.md as a high-level overview
- Put detailed information in docs/ directory
- Update version numbers if applicable
- Check for broken links

## Security

### Reporting Security Issues

**DO NOT** open public issues for security vulnerabilities.

Instead, email security@surfingcloud9.com with:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### Security Guidelines

When contributing:
- Never commit credentials or API keys
- Use environment variables for secrets
- Validate all external input
- Follow the principle of least privilege
- Document security considerations

## Code Review Process

All submissions require review:

1. **Automated checks** must pass
2. **Documentation** must be updated
3. **Code style** must be consistent
4. **Tests** must pass
5. **Security** considerations must be addressed

Reviewers will check for:
- Code quality and clarity
- Documentation completeness
- Test coverage
- Security implications
- Breaking changes

## Release Process

For maintainers:

1. Update version numbers
2. Update CHANGELOG.md
3. Create release branch
4. Tag release
5. Deploy to staging
6. Test thoroughly
7. Deploy to production
8. Announce release

## Community

- Be respectful and inclusive
- Provide constructive feedback
- Help others learn and grow
- Follow the Code of Conduct

## Questions?

If you have questions about contributing:
- Check the documentation in docs/
- Open a discussion on GitHub
- Email support@surfingcloud9.com

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to the Dakota Phone Automation System! 🎉
