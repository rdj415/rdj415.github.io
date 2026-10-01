# ⚡ Adam — Senior Roblox Developer & Systems Architect

[![Live Portfolio](https://img.shields.io/badge/Live_Portfolio-rdj415.github.io-00f2fe?style=for-the-badge&logo=googlechrome&logoColor=black)](https://rdj415.github.io)
[![Experience](https://img.shields.io/badge/Experience-6%2B_Years-10b981?style=for-the-badge)](https://rdj415.github.io)
[![Roblox](https://img.shields.io/badge/Roblox-Profile-eb4034?style=for-the-badge&logo=roblox&logoColor=white)](https://www.roblox.com/users/55770147/profile)
[![Discord](https://img.shields.io/badge/Discord-rdj__rb-5865f2?style=for-the-badge&logo=discord&logoColor=white)](https://discord.com)

Welcome to the official repository for my developer portfolio. I am a **Senior Roblox Developer & Luau Systems Architect** with **6+ years of production experience** engineering core architectural frameworks, custom libraries, authoritative server security, and autonomous AI systems in Roblox.

🌐 **Live Portfolio:** [**rdj415.github.io**](https://rdj415.github.io)

---

## 🛠️ Core Systems & Production Libraries

- **`AtomicBinding.luau` — Atomic Instance-Tree Pattern Binder**  
  Recursive instance-hierarchy binder resolving complex multi-branch manifests dynamically. Handles dynamic event tracking for `ChildAdded` and `ChildRemoved` with automatic descent unbinding and strict destructor teardowns (`dtors`) eliminating memory leaks.

- **`ModuleLoader.luau` — Phased Lifecycle & Boot Orchestrator**  
  Enterprise modular loader with discrete bootstrap scopes (Shared, Server, Client), two-stage lifecycle execution (`Init` ➔ `Start`), client-side step pacing to eliminate frame stalls, and real-time MicroProfiler metrics.

- **`AntiCheatService.luau` — Authoritative Server Security & Physics Audit**  
  Server-authoritative physics verification and security enforcement. Features real-time instant displacement auditing, suspicion score decay algorithms, executor detection via trap honeypots, and automated universe-wide suspensions with `Players:BanAsync`.

- **`AIService.luau` — Autonomous AI & Vehicle Navigation Engine**  
  Full server-side navigation engine featuring dynamic raycast obstacle avoidance (25° scanning cone), autonomous vehicle hijacking with server-side torque/physics simulation, dynamic storm zone retention math, and pluggable tactical behaviors.

- **`BufferUtil.luau` — High-Throughput Binary Buffer Networking**  
  Low-level binary serialization via the native Luau `buffer` library, custom cursor writers, and high-performance packet compression for high-frequency multiplayer replication.

- **`AbilityService.luau` — Character Ability & Cooldown Rate-Limiter**  
  Authoritative server ability pipeline with high-precision timestamp verification (`os.clock()`), cooldown enforcement, player disconnect state reclamation, and automated anti-cheat displacement bypass integration during high-velocity dashes and combat abilities.

- **`InteractionController.luau` — Proximity Interaction & Puzzle Prompt Engine**  
  Client-side interaction framework designed for dense multiplayer maps (doors, generators, chests, interactables). Utilizes `TagService` dynamic CollectionService watchers with Scythe zero-allocation scope cleanup and a throttled 5 Hz distance calculation loop to maintain 60 FPS without per-frame CPU degradation.

- **`ZoneService.luau` — Dynamic Spatial Danger Zone & Round Orchestrator**  
  Multi-phase round boundary shrinkage using cubic Hermite smoothstep curves (`3t² - 2t³`) for stutter-free network replication, coordinating with client storm visualizers and applying throttled 1 Hz radial out-of-zone player damage.

- **`Scythe.luau` — Zero-Allocation Scope-Based Memory Management Engine**  
  High-performance memory management package providing zero-allocation resource lifecycles. Uses lightweight integer handles for 0 heap allocations per scope, with automated LIFO teardown of Instances, connections, and custom cleanup callbacks.

- **`HitboxService.luau` — Spatial Combat & Shapecasting Engine**  
  Zero-trust server-authoritative hit detection using Blockcast and Spherecast. Features dot-product combat angle pre-filtering, animation-driven marker triggers with zero `wait()` calls, server rate-limiting debounces, and client VFX offloading via UnreliableRemoteEvents.

- **`DataService.luau` — Session-Locked Persistence & Transactional Mutation**  
  Enterprise data persistence layer wrapping ProfileStore. Features atomic transactional mutations (`.Update()`) to prevent race conditions, cryptographic FNV-1a CSPRNG seeding, write-verify release tokens, and continuous S-curve sigmoid luck scaling.

- **`CombatService.luau` & `CombatController.luau` — Cinematic Action Combat & VFX Engine**  
  High-intensity action combat framework featuring authoritative 4-hit combo strings (M1), microsecond hitstop (animation and camera freeze on impact for authentic anime/fighting game punch), 6-DOF harmonic spring camera shake, directional lunge physics, floating 3D critical damage numbers, and massive ragdoll/knockback finisher launches. Fully staged in Roblox Studio with an interactive training dummy and dynamic lighting arena.

---

## 💻 Technical Toolchain
- **Language**: Luau (`--!strict`, Generics, Parallel Luau / Actors)
- **External Workflow**: Rojo, Wally, Git / GitHub
- **Performance Profiling**: Roblox MicroProfiler, Memory Analyzer
- **Target Platform**: Roblox Engine (Desktop, Console, Mobile)

---

## 📬 Contact & Handles
- **Portfolio**: [https://rdj415.github.io](https://rdj415.github.io)
- **Discord**: `rdj_rb`
- **Roblox Profile**: [https://www.roblox.com/users/55770147/profile](https://www.roblox.com/users/55770147/profile)
- **GitHub**: [https://github.com/rdj415](https://github.com/rdj415)
