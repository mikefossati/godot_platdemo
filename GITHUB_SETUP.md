# GitHub Setup Guide

This project is now configured with Git for version control. Follow these steps to push it to GitHub.

## Current Status

✅ Git repository initialized
✅ Main branch created
✅ .gitignore configured for Godot 4.5.1
✅ Initial commits created with organized history

## Git History

```
027bc2b docs: add comprehensive game documentation
0162a10 feat: create game scenes and level design
854cf69 feat: implement core game systems
8618f37 feat: initialize Godot 4.5.1 project
031e3ce chore: add .gitignore for Godot 4.5.1 project
```

## Step 1: Create GitHub Repository

1. Go to https://github.com/new
2. Repository name: `godot-3d-platformer` (or your preferred name)
3. Description: "3D platformer prototype built with Godot 4.5.1"
4. **DO NOT** initialize with README, .gitignore, or license (we already have these)
5. Click "Create repository"

## Step 2: Connect Local Repository to GitHub

After creating the repository, GitHub will show you commands. Use these:

```bash
# Add GitHub as remote origin
git remote add origin https://github.com/YOUR_USERNAME/REPO_NAME.git

# Or if using SSH:
git remote add origin git@github.com:YOUR_USERNAME/REPO_NAME.git

# Push all commits to GitHub
git push -u origin main
```

**Replace** `YOUR_USERNAME` and `REPO_NAME` with your actual values.

## Step 3: Verify Upload

1. Refresh your GitHub repository page
2. You should see all files and commit history
3. Check that the README displays properly

## Repository Structure on GitHub

Your repository will contain:

```
godot-3d-platformer/
├── .gitignore                 # Git ignore rules
├── README.md                  # Main documentation
├── GAME_DESIGN.md            # Game design document
├── QUICK_REFERENCE.md        # Quick reference guide
├── COMPATIBILITY.md          # Godot 4.5.1 compatibility
├── VISUAL_IMPROVEMENTS.md    # Visual design notes
├── COLOR_GUIDE.md            # Color reference
├── GITHUB_SETUP.md           # This file
├── project.godot             # Godot project config
├── icon.svg                  # Project icon
├── scripts/                  # Game scripts
│   ├── game_manager.gd
│   ├── player.gd
│   ├── collectible.gd
│   ├── camera_follow.gd
│   ├── game_ui.gd
│   ├── main_menu.gd
│   └── game_over.gd
└── scenes/                   # Game scenes
    ├── player/
    ├── collectibles/
    ├── level/
    └── ui/
```

## Git Workflow for Future Changes

### Making Changes

```bash
# 1. Check current status
git status

# 2. See what changed
git diff

# 3. Stage specific files
git add path/to/file

# Or stage all changes
git add .

# 4. Commit with descriptive message
git commit -m "type: brief description

Detailed explanation of what and why"

# 5. Push to GitHub
git push
```

### Commit Message Convention

We're using **Conventional Commits** format:

```
<type>: <short description>

[optional body]
[optional footer]
```

**Types:**
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation only
- `style:` - Code formatting (not visual style)
- `refactor:` - Code restructuring
- `perf:` - Performance improvement
- `test:` - Adding tests
- `chore:` - Maintenance tasks

**Examples:**

```bash
git commit -m "feat: add double jump mechanic

- Player can now jump twice before landing
- Added jump counter variable
- Updated physics in player.gd:35"

git commit -m "fix: collectibles not disappearing on collection

- Added queue_free() call in collectible.gd
- Fixes issue where items remained visible after pickup"

git commit -m "docs: update README with new controls"

git commit -m "refactor: extract camera logic into separate method"
```

### Creating Branches for Features

```bash
# Create and switch to new branch
git checkout -b feature/new-enemy-type

# Make changes and commit
git add .
git commit -m "feat: add flying enemy"

# Push branch to GitHub
git push -u origin feature/new-enemy-type

# Switch back to main
git checkout main

# Merge feature branch
git merge feature/new-enemy-type

# Delete branch after merging
git branch -d feature/new-enemy-type
```

### Viewing History

```bash
# One-line summary
git log --oneline

# Detailed view
git log

# Visual graph
git log --oneline --graph --all

# Last 5 commits
git log --oneline -5

# Changes by specific author
git log --author="Your Name"
```

### Undoing Changes

```bash
# Unstage file (keep changes)
git restore --staged path/to/file

# Discard local changes
git restore path/to/file

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes) - CAREFUL!
git reset --hard HEAD~1
```

## Collaborating with Others

### Cloning Your Repository

Others can clone your repo with:

```bash
git clone https://github.com/YOUR_USERNAME/REPO_NAME.git
cd REPO_NAME
```

### Pulling Updates

```bash
# Fetch and merge changes from GitHub
git pull

# Or fetch then merge separately
git fetch
git merge origin/main
```

### Handling Merge Conflicts

If two people edit the same file:

1. Git will mark conflicts in the file
2. Open the file and look for `<<<<<<<`, `=======`, `>>>>>>>` markers
3. Edit to keep the correct version
4. Remove conflict markers
5. Stage and commit:

```bash
git add conflicted-file.gd
git commit -m "fix: resolve merge conflict in player movement"
```

## GitHub Features to Enable

### 1. Issues

Good for tracking bugs and feature requests:
- Go to Settings → Features → Issues ✓

### 2. Wiki

For extended documentation:
- Go to Settings → Features → Wikis ✓

### 3. Discussions

For community questions:
- Go to Settings → Features → Discussions ✓

### 4. Topics

Add topics to help others find your project:
- Click "⚙️ Settings" near the top
- Add topics: `godot`, `godot-4`, `platformer`, `3d-game`, `game-development`

### 5. Repository Description

Add a short description:
- "3D platformer prototype built with Godot 4.5.1 featuring physics-based movement, collectibles, and color-coded visual design"

## Protecting the Main Branch

To prevent accidental direct commits to main:

1. Go to Settings → Branches
2. Add rule for `main`
3. Enable:
   - ✓ Require pull request reviews before merging
   - ✓ Require status checks to pass

Then always work in feature branches and use Pull Requests.

## README Badges (Optional)

Add badges to your README for a professional look:

```markdown
![Godot Version](https://img.shields.io/badge/Godot-4.5.1-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey)
```

## License

Consider adding a LICENSE file:

```bash
# MIT License (permissive)
# Create LICENSE file with MIT text

git add LICENSE
git commit -m "chore: add MIT license"
git push
```

## .github Folder (Advanced)

For automated workflows, create `.github/` folder:

```
.github/
├── workflows/           # GitHub Actions
│   └── export.yml      # Auto-export game on push
└── ISSUE_TEMPLATE/     # Issue templates
    └── bug_report.md
```

## Useful Git Commands Reference

```bash
# Show remote URLs
git remote -v

# Change remote URL
git remote set-url origin NEW_URL

# Create .gitattributes for line endings
echo "* text=auto" > .gitattributes

# View file history
git log --follow path/to/file

# Search commits
git log --grep="keyword"

# Show specific commit
git show COMMIT_HASH

# Compare branches
git diff main..feature-branch

# List all branches
git branch -a

# Delete remote branch
git push origin --delete branch-name

# Stash changes temporarily
git stash
git stash pop
```

## Troubleshooting

### "Permission denied (publickey)"

If using SSH and getting this error:
1. Use HTTPS instead: `https://github.com/USERNAME/REPO.git`
2. Or set up SSH keys: https://docs.github.com/en/authentication/connecting-to-github-with-ssh

### "rejected - non-fast-forward"

If push is rejected:
```bash
git pull --rebase
git push
```

### Large files

Godot projects can have large files. If you hit GitHub's 100MB limit:
- Make sure `.godot/` is in `.gitignore` (it is)
- Avoid committing export builds
- Use Git LFS for large assets if needed

## Next Steps

1. ✅ Create GitHub repository
2. ✅ Push code
3. ⬜ Add topics and description
4. ⬜ Enable Issues/Wiki if desired
5. ⬜ Invite collaborators (if any)
6. ⬜ Set up branch protection (optional)
7. ⬜ Add LICENSE file
8. ⬜ Share with community!

## Resources

- **Git Documentation**: https://git-scm.com/doc
- **GitHub Guides**: https://guides.github.com/
- **Conventional Commits**: https://www.conventionalcommits.org/
- **Git Cheat Sheet**: https://education.github.com/git-cheat-sheet-education.pdf
- **Godot on GitHub**: https://github.com/godotengine/godot

---

**Your project is ready for version control!** 🎉

Just create the GitHub repository and push to start tracking your changes in the cloud.
