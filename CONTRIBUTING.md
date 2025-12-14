# Contributing to Strength Tracker

Thank you for your interest in contributing to Strength Tracker! This document provides guidelines and instructions for contributing.

## Getting Started

### Prerequisites

- Xcode 15 or later
- iOS 17+ SDK
- Swift 5.9+
- macOS Ventura or later

### Setting Up the Development Environment

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/strength-tracker.git
   cd strength-tracker
   ```
3. Open the project in Xcode:
   ```bash
   open StrengthTracker/StrengthTracker.xcodeproj
   ```
4. Build and run the project (Cmd+R)

## Development Guidelines

### Code Style

- Follow Swift API Design Guidelines
- Use Swift's native naming conventions (camelCase for variables/functions, PascalCase for types)
- Keep functions focused and single-purpose
- Use meaningful variable and function names
- Add documentation comments for public APIs

### Architecture

This project follows the MVVM (Model-View-ViewModel) pattern with SwiftData:

- **Models**: SwiftData entities in `/Models`
- **Views**: SwiftUI views organized by feature in `/Views`
- **Services**: Business logic and data services in `/Services`
- **Agent**: AI coaching system in `/Agent`
- **Utilities**: Helper functions in `/Utilities`

### Commit Messages

Use clear, descriptive commit messages:

```
feat: Add new exercise substitution logic
fix: Correct e1RM calculation for high rep ranges
docs: Update README with API key setup
refactor: Simplify workout template generation
test: Add unit tests for PlateMathCalculator
```

### Pull Request Process

1. Create a feature branch from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes and commit them with descriptive messages

3. Push to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```

4. Open a Pull Request against the `main` branch

5. Ensure your PR:
   - Has a clear title and description
   - Includes any necessary documentation updates
   - Passes all CI checks (if configured)
   - Has been tested on iOS Simulator

## Areas for Contribution

### High Priority

- Bug fixes
- Performance improvements
- Accessibility enhancements
- Test coverage

### Feature Ideas

- Additional workout split templates
- More exercise variations
- Enhanced analytics and visualizations
- Watch app companion
- Widget support

### Documentation

- Code documentation improvements
- README enhancements
- Tutorial content
- Example usage

## Testing

### Running Tests

```bash
# In Xcode
Cmd+U

# Or via command line
xcodebuild test -scheme StrengthTracker -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Writing Tests

- Add tests for new functionality
- Maintain existing test coverage
- Use descriptive test names
- Test edge cases

## Reporting Issues

When reporting issues, please include:

1. A clear, descriptive title
2. Steps to reproduce the problem
3. Expected behavior
4. Actual behavior
5. iOS version and device/simulator used
6. Screenshots if applicable

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on the code, not the person
- Help others learn and grow

## Questions?

If you have questions about contributing, feel free to:

- Open a GitHub Discussion
- Create an issue with the "question" label

Thank you for contributing to Strength Tracker!
