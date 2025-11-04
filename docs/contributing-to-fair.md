# Contributing to FAIR Plugin

This guide explains how to develop and contribute changes back to the FAIR plugin from this CloudFest hackathon environment.

## Development Setup

The FAIR plugin is automatically cloned to `plugins/fair/` when you run `npm run dev:start` for the first time. The plugin is then loaded directly by wp-env, giving you full source access for debugging, modifications, and contributions.

**Note**: If you cloned this repo fresh, you don't need to manually clone the FAIR plugin - it will be cloned automatically on first startup.

### Directory Structure

```
cloudfest-usa-2025-local-env/
├── plugins/
│   └── fair/              # Local FAIR plugin clone (not tracked in git)
├── .wp-env.json           # WordPress config (uses ./plugins/fair)
└── config/
    └── fair-config.php    # FAIR auto-configuration (mu-plugin)
```

### How It Works

1. **Local Source**: WordPress loads FAIR from `plugins/fair/` instead of downloading a ZIP
2. **Independent Git Repo**: `plugins/fair/` is its own git repository (separate from the hackathon repo)
3. **Hot Reload**: Changes to FAIR source require WordPress restart: `npm run wp:stop && npm run wp:start`
4. **Auto-Config**: `config/fair-config.php` automatically configures FAIR to use local AspireCloud

## Making Changes to FAIR

### 1. Create a Development Branch

Always work in a feature branch, never directly on `main`:

```bash
cd plugins/fair
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-description
```

### 2. Make Your Changes

Edit files in `plugins/fair/` as needed. Common files:

- `plugin.php` - Main plugin file, hooks, initialization
- `inc/` - Core functionality classes
- `assets/` - JavaScript, CSS, images
- `docs/` - Documentation

### 3. Test Your Changes

Restart WordPress to see your changes:

```bash
# From the project root
npm run wp:stop && npm run wp:start
```

Check WordPress logs for errors:
```bash
docker logs $(docker ps -qf 'name=.*-wordpress-1') -f
```

### 4. Commit Your Changes with Signoff

**IMPORTANT**: All commits to FAIR repositories **must** include a signoff line.

#### What is Code Signoff?

Code signoff is a way to certify that you have the right to submit the code under the project's license. It's **not** a cryptographic signature, just a text line in your commit message.

#### How to Sign Off Commits

**Option 1: Automatic Signoff (Recommended)**

Configure git to always sign off your commits:

```bash
cd plugins/fair
git config user.name "Your Name"
git config user.email "your.email@example.com"

# Use -s flag with every commit
git commit -s -m "Add feature description"
```

The `-s` flag automatically adds:
```
Signed-off-by: Your Name <your.email@example.com>
```

**Option 2: Manual Signoff**

Add the signoff line manually to your commit message:

```bash
git commit -m "Add feature description

Signed-off-by: Your Name <your.email@example.com>"
```

#### Example Commit

```bash
cd plugins/fair
git add .
git commit -s -m "Add PatchStack vulnerability badge to plugin listings

- Query PatchStack API for plugin vulnerabilities
- Display security badge in WordPress admin
- Cache vulnerability data for 24 hours

Fixes: #123"
```

### 5. Prepare for Pull Request

Before submitting a PR, ensure your branch is up-to-date:

```bash
cd plugins/fair

# Fetch latest changes from upstream
git fetch origin main

# Rebase your branch onto main
git rebase origin/main

# Resolve any conflicts if needed
```

## Contributing Back to FAIR

### Setup: Fork and Remotes

If you plan to submit pull requests, you should fork the FAIR plugin and set up remotes:

#### 1. Fork on GitHub

1. Visit https://github.com/fairpm/fair-plugin
2. Click "Fork" button (top-right)
3. This creates `https://github.com/YOUR_USERNAME/fair-plugin`

#### 2. Configure Remotes

```bash
cd plugins/fair

# Check current remote (should be 'origin' pointing to fairpm/fair-plugin)
git remote -v

# If you cloned from fairpm/fair-plugin, rename it to 'upstream'
git remote rename origin upstream

# Add your fork as 'origin'
git remote add origin https://github.com/YOUR_USERNAME/fair-plugin.git

# Verify remotes
git remote -v
# Should show:
# origin    https://github.com/YOUR_USERNAME/fair-plugin.git (fetch)
# origin    https://github.com/YOUR_USERNAME/fair-plugin.git (push)
# upstream  https://github.com/fairpm/fair-plugin.git (fetch)
# upstream  https://github.com/fairpm/fair-plugin.git (push)
```

### Submitting a Pull Request

#### 1. Push to Your Fork

```bash
cd plugins/fair

# Push your feature branch to your fork
git push origin feature/your-feature-name
```

#### 2. Create Pull Request on GitHub

1. Visit your fork: `https://github.com/YOUR_USERNAME/fair-plugin`
2. Click "Compare & pull request" button
3. Fill out the PR template:
   - **Title**: Clear, concise description (e.g., "Add PatchStack vulnerability scanning")
   - **Description**:
     - What changes you made
     - Why you made them
     - How to test them
     - Reference any related issues
   - **Base**: `fairpm/fair-plugin` `main` branch
   - **Compare**: `YOUR_USERNAME/fair-plugin` `feature/your-feature-name` branch

#### 3. Verify Signoff

GitHub will check that all commits include the signoff line. If any commits are missing signoff:

```bash
# Amend the last commit
git commit --amend -s --no-edit
git push origin feature/your-feature-name --force-with-lease

# Or rebase and sign off all commits
git rebase origin/main --signoff
git push origin feature/your-feature-name --force-with-lease
```

#### 4. Respond to Review Feedback

Maintainers may request changes. To update your PR:

```bash
cd plugins/fair

# Make requested changes
# Commit with signoff
git add .
git commit -s -m "Address review feedback: update error handling"

# Push to update the PR
git push origin feature/your-feature-name
```

## Syncing with Upstream

Keep your local clone up-to-date with the upstream FAIR repository:

```bash
cd plugins/fair

# Fetch latest changes from upstream
git fetch upstream

# Update your main branch
git checkout main
git merge upstream/main

# Update your fork on GitHub (optional)
git push origin main
```

If working on a long-running feature branch:

```bash
cd plugins/fair

# Update main first
git checkout main
git fetch upstream
git merge upstream/main

# Rebase your feature branch onto updated main
git checkout feature/your-feature-name
git rebase main

# If you already pushed, force-push (be careful!)
git push origin feature/your-feature-name --force-with-lease
```

## Best Practices

### Code Quality

- **Follow existing code style** - Match the plugin's coding standards
- **Write meaningful commit messages** - Explain *why*, not just *what*
- **Keep commits atomic** - One logical change per commit
- **Test thoroughly** - Verify your changes work in different scenarios

### Branch Naming

- `feature/descriptive-name` - New functionality
- `fix/issue-description` - Bug fixes
- `docs/what-changed` - Documentation updates
- `refactor/what-changed` - Code refactoring

### Commit Message Format

```
Short summary (50 chars or less)

More detailed explanation if needed. Wrap at 72 characters.
Explain the problem this commit solves and why this approach
was chosen.

- Bullet points for multiple changes
- Reference issues: Fixes #123, Relates to #456

Signed-off-by: Your Name <your.email@example.com>
```

### Testing Checklist

Before submitting a PR, verify:

- [ ] Changes work in WordPress admin
- [ ] No PHP errors in WordPress logs
- [ ] FAIR plugin still communicates with AspireCloud
- [ ] Configuration via `fair-config.php` still works
- [ ] All commits include signoff
- [ ] Branch is rebased onto latest main
- [ ] Code follows existing style

## Troubleshooting

### "Your commit is missing Signed-off-by"

```bash
# Amend last commit to add signoff
git commit --amend -s --no-edit

# Sign off all commits in your branch
git rebase origin/main --signoff

# Force-push to update your PR
git push origin feature/your-feature-name --force-with-lease
```

### Changes Not Appearing in WordPress

```bash
# Restart WordPress to reload PHP files
npm run wp:stop && npm run wp:start

# Check WordPress is running
docker ps | grep wordpress

# Check WordPress logs
docker logs $(docker ps -qf 'name=.*-wordpress-1') -f
```

### Merge Conflicts

```bash
cd plugins/fair

# Fetch latest upstream
git fetch upstream

# Attempt rebase
git rebase upstream/main

# Git will pause at conflicts
# Edit conflicted files, then:
git add .
git rebase --continue

# Repeat until rebase completes
```

### Reset to Clean State

If you need to start over:

```bash
cd plugins/fair

# Discard all local changes
git reset --hard origin/main
git clean -fd

# Delete your branch and start fresh
git checkout main
git branch -D feature/your-feature-name
git checkout -b feature/your-feature-name
```

## Resources

- **FAIR Plugin Repo**: https://github.com/fairpm/fair-plugin
- **Contributing Guide**: https://github.com/fairpm/tsc/blob/main/contributing.md
- **Code Signoff Info**: https://github.com/fairpm/tsc/blob/main/contributing.md#code-signoff
- **FAIR Protocol Spec**: https://github.com/fairpm/fair-protocol
- **FAIR Website**: https://fair.pm

## Getting Help

- **GitHub Issues**: https://github.com/fairpm/fair-plugin/issues
- **Pull Request Process**: Comment on your PR if you need guidance
- **Code Signoff Questions**: See resources above or ask a maintainer

---

**Happy Contributing!** Your improvements to FAIR help make WordPress plugin distribution more secure and decentralized.
