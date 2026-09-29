# 🚀 Roblox Luau Systems Architect Portfolio (GitHub Pages)

A modern, high-performance portfolio website built specifically for a **Roblox Luau Systems Architect**, pre-configured for instant and free hosting on **GitHub Pages** (identical platform to `physic2952.github.io`).

---

## 🛠️ Highlights & Architecture:

1. **Clean, Grounded Engineering Focus**:
   - Zero selling, zero pricing calculators, zero commercial packages.
   - Highlights your exact verified experience: **`6+ Years of Development Experience`**.
   - Showcases real, substantial production-grade codebase modules and architectural libraries.

2. **Featured Systems & Real Project Libraries**:
   - **Atomic Tree Pattern Binding Library** (`src/shared/SharedModules/AtomicBinding.luau`):
     - Recursive instance hierarchy binder resolving complex multi-branch manifests dynamically.
     - Dynamic event tracking for `ChildAdded` and `ChildRemoved` with automatic descent unbinding.
     - Strict destructor teardowns (`dtors`) eliminating dangling connections and memory leaks.
   - **Phased Lifecycle & Boot Orchestrator** (`src/shared/ModuleLoader.luau`):
     - Enterprise modular loader with discrete bootstrap scopes (Shared, Server, Client).
     - Phased lifecycle execution (`Init` ➔ `Start`) with dependency ordering and client step pacing.
     - Real-time boot progress tracking percentages and MicroProfiler performance metrics.
   - **Authoritative Anti-Cheat & Combat Core** (`src/server/ServerModules/AntiCheatService.luau`):
     - Instant displacement checking, suspicion score decaying, executor detection via trap honeypots, and universe-wide bans with `Players:BanAsync`.
   - **Autonomous AI & Vehicle Navigation Core** (`src/server/ServerModules/AIService.luau`):
     - 25° raycast obstacle avoidance vectors, autonomous vehicle physics & torque simulation, storm zone containment math, and tactical behavior states.
   - **Binary Buffer Networking** (`src/shared/Packages/BufferUtil.luau`):
     - Low-level binary serialization via `buffer.create`, `WriteVector3`, and cursor-based `CreateWriter`.

3. **Visual Assets**:
   - High-tech cyberpunk schematics saved locally in `assets/images/`:
     - `ai_system_banner.jpg` (Autonomous AI Neural Grid & Navigation)
     - `combat_system_banner.jpg` (3D Raycasting & Hitbox Lag Compensation)

---

## 🌐 How to Publish to GitHub Pages in 2 Minutes:

To get your own free URL like `https://rdj415.github.io`:

### Option A: Browser Drag-and-Drop (No Terminal Needed)
1. Go to [github.com/new](https://github.com/new) and create a repository.
2. Name the repository:
   - `rdj415.github.io` (for a clean root address `https://rdj415.github.io`)
   - OR `portfolio` (for address `https://rdj415.github.io/portfolio`).
3. Ensure it is set to **Public** and click **Create repository**.
4. Click **uploading an existing file**.
5. Drag and drop the files and `assets` folder:
   - `index.html`
   - `style.css`
   - `script.js`
   - `assets/` (with images inside)
6. Click **Commit changes**.
7. Go to **Settings** ➔ **Pages** (on the left menu) ➔ Under **Branch**, select `main` (or `master`) ➔ Click **Save**.
8. Within 60 seconds, your portfolio will be live worldwide with free SSL!

---

### Option B: Via Git CLI
```bash
git init
git add .
git commit -m "Deploy Roblox Luau Systems Architect Portfolio"
git branch -M main
git remote add origin https://github.com/rdj415/rdj415.github.io.git
git push -u origin main
```
Then enable Pages in **Settings ➔ Pages**.

---

## ✏️ Configured Profiles & Contacts:

All contacts are fully wired into [`index.html`](file:///C:/Users/Adam/.gemini/antigravity/scratch/roblox-luau-portfolio/index.html):
- **GitHub**: [`https://github.com/rdj415`](https://github.com/rdj415) (in navbar, contact cards, and footer)
- **Discord Tag**: `rdj_rb` (with 1-click copy button and toast notifications)
- **Roblox Profile**: [`https://www.roblox.com/users/55770147/profile`](https://www.roblox.com/users/55770147/profile)
- **Crypto Wallet**: TRON (TRC-20) address `TNaavXhoj6iadhgPjAqBmJna1Lnwv4Jvjb` (with 1-click copy button)


