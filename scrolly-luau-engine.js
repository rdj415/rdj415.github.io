/**
 * ══════════════════════════════════════════════════════════════
 * SCROLLY-LUAU-ENGINE.JS
 * 3D Scrollytelling Exploded-View Assembly Engine (Three.js)
 * Features:
 *   - 3D Luau Emblem & Orbiting Nodes
 *   - 3D Roblox Script & ModuleScript Bricks
 *   - 3D Luau Type Solver Tokens (<T>, { }, buffer, vector)
 *   - 140+ Exploded Shards & Carbon Composite Plates
 *   - Dynamic Camera Spline Path & Damped Lerp Inertia
 *   - F1 / Cyberpunk Live HUD & Telemetry Speedometer
 *   - Synthesized Web Audio Cyber Sound FX
 * ══════════════════════════════════════════════════════════════
 */

(function () {
  'use strict';

  // Wait for Three.js to be available
  function initEngine() {
    if (typeof THREE === 'undefined') {
      setTimeout(initEngine, 50);
      return;
    }

    const container = document.getElementById('scrolly-luau-container');
    const stage = document.getElementById('webgl-stage');
    if (!container || !stage) return;

    // --- Web Audio FX Engine (Synthesized, zero external audio assets) ---
    class SoundFX {
      constructor() {
        this.ctx = null;
        this.muted = false;
        this.lastPlayTime = 0;
      }

      init() {
        if (!this.ctx && (window.AudioContext || window.webkitAudioContext)) {
          const AudioCtx = window.AudioContext || window.webkitAudioContext;
          this.ctx = new AudioCtx();
        }
        if (this.ctx && this.ctx.state === 'suspended') {
          this.ctx.resume();
        }
      }

      toggleMute() {
        this.muted = !this.muted;
        return this.muted;
      }

      playClick() {
        if (this.muted) return;
        this.init();
        if (!this.ctx) return;
        const now = this.ctx.currentTime;
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(1400, now);
        osc.frequency.exponentialRampToValueAtTime(600, now + 0.04);
        gain.gain.setValueAtTime(0.06, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.04);
        osc.connect(gain);
        gain.connect(this.ctx.destination);
        osc.start(now);
        osc.stop(now + 0.04);
      }

      playWhoosh(intensity = 1) {
        if (this.muted) return;
        const nowMs = Date.now();
        if (nowMs - this.lastPlayTime < 180) return;
        this.lastPlayTime = nowMs;
        this.init();
        if (!this.ctx) return;

        const now = this.ctx.currentTime;
        const bufferSize = this.ctx.sampleRate * 0.15;
        const buffer = this.ctx.createBuffer(1, bufferSize, this.ctx.sampleRate);
        const data = buffer.getChannelData(0);
        for (let i = 0; i < bufferSize; i++) {
          data[i] = Math.random() * 2 - 1;
        }

        const noise = this.ctx.createBufferSource();
        noise.buffer = buffer;

        const filter = this.ctx.createBiquadFilter();
        filter.type = 'bandpass';
        filter.frequency.setValueAtTime(350, now);
        filter.frequency.exponentialRampToValueAtTime(950, now + 0.12);
        filter.Q.value = 3.0;

        const gain = this.ctx.createGain();
        gain.gain.setValueAtTime(0.04 * Math.min(intensity, 2), now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.15);

        noise.connect(filter);
        filter.connect(gain);
        gain.connect(this.ctx.destination);

        noise.start(now);
        noise.stop(now + 0.15);
      }

      playAssembleChime() {
        if (this.muted) return;
        this.init();
        if (!this.ctx) return;

        const now = this.ctx.currentTime;
        const freqs = [523.25, 659.25, 783.99, 1046.5]; // C5, E5, G5, C6 arpeggio
        freqs.forEach((freq, idx) => {
          const osc = this.ctx.createOscillator();
          const gain = this.ctx.createGain();
          osc.type = 'triangle';
          osc.frequency.setValueAtTime(freq, now + idx * 0.06);

          gain.gain.setValueAtTime(0.08, now + idx * 0.06);
          gain.gain.exponentialRampToValueAtTime(0.0001, now + idx * 0.06 + 0.5);

          osc.connect(gain);
          gain.connect(this.ctx.destination);

          osc.start(now + idx * 0.06);
          osc.stop(now + idx * 0.06 + 0.55);
        });
      }
    }

    const sfx = new SoundFX();

    // --- Three.js Setup ---
    const scene = new THREE.Scene();
    scene.fog = new THREE.FogExp2(0x07090e, 0.016);

    const camera = new THREE.PerspectiveCamera(46, window.innerWidth / window.innerHeight, 0.1, 1000);
    camera.position.set(0, 3, 24);

    const renderer = new THREE.WebGLRenderer({
      canvas: stage,
      antialias: true,
      alpha: true,
      powerPreference: 'high-performance'
    });
    renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure = 1.15;

    // --- Lighting Rig ---
    const ambientLight = new THREE.AmbientLight(0x131a2c, 1.2);
    scene.add(ambientLight);

    const keyLight = new THREE.DirectionalLight(0x00f2fe, 2.2);
    keyLight.position.set(12, 18, 14);
    scene.add(keyLight);

    const rimLight = new THREE.DirectionalLight(0xa855f7, 2.6);
    rimLight.position.set(-14, -8, -12);
    scene.add(rimLight);

    const frontLight = new THREE.PointLight(0xffffff, 1.4, 40);
    frontLight.position.set(0, 4, 18);
    scene.add(frontLight);

    const coreLight = new THREE.PointLight(0x00f2fe, 3.5, 25);
    coreLight.position.set(0, 0, 0);
    scene.add(coreLight);

    // --- Floor Grid & Reflection Stage ---
    const gridHelper = new THREE.GridHelper(160, 64, 0x00f2fe, 0x142035);
    gridHelper.position.y = -6.5;
    scene.add(gridHelper);

    // Secondary subtle cyan floor line accents
    const gridHelper2 = new THREE.GridHelper(160, 16, 0x00f2fe, 0x0a1424);
    gridHelper2.position.y = -6.48;
    scene.add(gridHelper2);

    // Dark mirror ground plate
    const groundGeo = new THREE.PlaneGeometry(180, 180);
    const groundMat = new THREE.MeshStandardMaterial({
      color: 0x07090e,
      roughness: 0.15,
      metalness: 0.85
    });
    const ground = new THREE.Mesh(groundGeo, groundMat);
    ground.rotation.x = -Math.PI / 2;
    ground.position.y = -6.52;
    scene.add(ground);

    // --- Starfield & Cyber Dust ---
    const particleCount = 650;
    const particleGeo = new THREE.BufferGeometry();
    const particlePos = new Float32Array(particleCount * 3);
    const particleColors = new Float32Array(particleCount * 3);

    const colorPalette = [
      new THREE.Color(0x00f2fe),
      new THREE.Color(0x38bdf8),
      new THREE.Color(0xa855f7),
      new THREE.Color(0xffffff)
    ];

    for (let i = 0; i < particleCount; i++) {
      particlePos[i * 3] = (Math.random() - 0.5) * 80;
      particlePos[i * 3 + 1] = (Math.random() - 0.5) * 60;
      particlePos[i * 3 + 2] = (Math.random() - 0.5) * 70;

      const c = colorPalette[Math.floor(Math.random() * colorPalette.length)];
      particleColors[i * 3] = c.r;
      particleColors[i * 3 + 1] = c.g;
      particleColors[i * 3 + 2] = c.b;
    }

    particleGeo.setAttribute('position', new THREE.BufferAttribute(particlePos, 3));
    particleGeo.setAttribute('color', new THREE.BufferAttribute(particleColors, 3));

    const particleMat = new THREE.PointsMaterial({
      size: 0.28,
      vertexColors: true,
      transparent: true,
      opacity: 0.75,
      blending: THREE.AdditiveBlending
    });
    const starfield = new THREE.Points(particleGeo, particleMat);
    scene.add(starfield);

    // --- 3D Modular Assembly Core ---
    const mainGroup = new THREE.Group();
    scene.add(mainGroup);

    // All parts will be tracked for exploded-view interpolation
    const modularParts = [];

    function registerPart(mesh, assembledPos, assembledRot, explodedPos, explodedRot, scale = 1) {
      mesh.position.copy(explodedPos);
      mesh.rotation.copy(explodedRot);
      mesh.scale.set(scale, scale, scale);
      mainGroup.add(mesh);

      modularParts.push({
        mesh,
        assembledPos: assembledPos.clone(),
        assembledRot: assembledRot.clone(),
        explodedPos: explodedPos.clone(),
        explodedRot: explodedRot.clone(),
        currentPos: explodedPos.clone(),
        currentRot: explodedRot.clone()
      });
    }

    // Material Library
    const mats = {
      carbonDark: new THREE.MeshStandardMaterial({
        color: 0x121620,
        roughness: 0.35,
        metalness: 0.9,
        wireframe: false
      }),
      neonCyan: new THREE.MeshStandardMaterial({
        color: 0x00f2fe,
        emissive: 0x00d2de,
        emissiveIntensity: 0.8,
        roughness: 0.2,
        metalness: 0.8
      }),
      neonPurple: new THREE.MeshStandardMaterial({
        color: 0xa855f7,
        emissive: 0x7e22ce,
        emissiveIntensity: 0.7,
        roughness: 0.2,
        metalness: 0.8
      }),
      glassCyan: new THREE.MeshPhysicalMaterial({
        color: 0x00f2fe,
        transparent: true,
        opacity: 0.65,
        roughness: 0.1,
        metalness: 0.1,
        transmission: 0.7,
        ior: 1.5
      }),
      chromeMetal: new THREE.MeshStandardMaterial({
        color: 0xd8e8f8,
        roughness: 0.1,
        metalness: 0.95
      }),
      goldAccent: new THREE.MeshStandardMaterial({
        color: 0xf59e0b,
        emissive: 0xd97706,
        emissiveIntensity: 0.4,
        roughness: 0.25,
        metalness: 0.85
      })
    };

    // Helper: Texture Generator for Roblox Script Icons
    function createScriptTexture(type = 'script') {
      const cv = document.createElement('canvas');
      cv.width = 256;
      cv.height = 256;
      const c = cv.getContext('2d');

      // Background
      c.fillStyle = type === 'module' ? '#0f172a' : '#090d16';
      c.fillRect(0, 0, 256, 256);

      // Border
      c.strokeStyle = type === 'module' ? '#a855f7' : '#00f2fe';
      c.lineWidth = 12;
      c.strokeRect(6, 6, 244, 244);

      // Inner glow lines
      c.fillStyle = type === 'module' ? '#c084fc' : '#38bdf8';
      c.font = 'bold 36px monospace';
      c.textAlign = 'center';
      c.textBaseline = 'middle';
      c.fillText(type === 'module' ? 'MODULE' : 'LUAU', 128, 64);

      c.fillStyle = '#ffffff';
      c.font = 'bold 28px monospace';
      c.fillText(type === 'module' ? 'return Module' : 'local Service', 128, 128);

      c.fillStyle = type === 'module' ? '#a855f7' : '#00f2fe';
      c.font = '22px monospace';
      c.fillText(':: StrictType', 128, 192);

      const tex = new THREE.CanvasTexture(cv);
      return tex;
    }

    const scriptTex = createScriptTexture('script');
    const moduleTex = createScriptTexture('module');

    const scriptMat = new THREE.MeshStandardMaterial({
      map: scriptTex,
      roughness: 0.3,
      metalness: 0.7
    });

    const moduleMat = new THREE.MeshStandardMaterial({
      map: moduleTex,
      roughness: 0.3,
      metalness: 0.7
    });

    // ─────────────────────────────────────────────────────────────
    // 1. CENTRAL LUAU CORE & CRESCENT MOON EMBLEM
    // ─────────────────────────────────────────────────────────────
    // A: Glowing Core Sphere
    const coreSphereGeo = new THREE.SphereGeometry(1.6, 32, 32);
    const coreSphere = new THREE.Mesh(coreSphereGeo, mats.neonCyan);
    registerPart(
      coreSphere,
      new THREE.Vector3(0, 0, 0),
      new THREE.Euler(0, 0, 0),
      new THREE.Vector3(0, 5, -8),
      new THREE.Euler(1.2, 0.8, 0)
    );

    // B: Luau Outer Crescent Arc (Torus segment)
    const crescentGeo = new THREE.TorusGeometry(2.5, 0.45, 24, 64, Math.PI * 1.55);
    const crescent = new THREE.Mesh(crescentGeo, mats.chromeMetal);
    registerPart(
      crescent,
      new THREE.Vector3(0, 0, 0),
      new THREE.Euler(0, 0, Math.PI * 0.25),
      new THREE.Vector3(-8, 7, 5),
      new THREE.Euler(-0.8, 1.5, 0.4)
    );

    // C: Luau Orbiting Satellite Node
    const satelliteGeo = new THREE.SphereGeometry(0.55, 24, 24);
    const satellite = new THREE.Mesh(satelliteGeo, mats.goldAccent);
    registerPart(
      satellite,
      new THREE.Vector3(2.4, 2.0, 0.3),
      new THREE.Euler(0, 0, 0),
      new THREE.Vector3(10, 8, -6),
      new THREE.Euler(0.5, -1.2, 0.8)
    );

    // D: Concentric Gimbal Ring 1 (Astrolabe Ring)
    const ring1Geo = new THREE.TorusGeometry(3.6, 0.08, 16, 80);
    const ring1 = new THREE.Mesh(ring1Geo, mats.neonCyan);
    registerPart(
      ring1,
      new THREE.Vector3(0, 0, 0),
      new THREE.Euler(Math.PI / 4, 0, 0),
      new THREE.Vector3(0, -9, 8),
      new THREE.Euler(1.5, -0.7, 0)
    );

    // E: Concentric Gimbal Ring 2
    const ring2Geo = new THREE.TorusGeometry(4.2, 0.08, 16, 80);
    const ring2 = new THREE.Mesh(ring2Geo, mats.neonPurple);
    registerPart(
      ring2,
      new THREE.Vector3(0, 0, 0),
      new THREE.Euler(0, Math.PI / 3, Math.PI / 6),
      new THREE.Vector3(7, -8, -7),
      new THREE.Euler(-1.1, 0.9, 1.4)
    );

    // ─────────────────────────────────────────────────────────────
    // 2. 3D TYPE SOLVER TOKENS (<T>, { }, ::)
    // ─────────────────────────────────────────────────────────────
    // Token: Left Bracket "<"
    function createChevron(flip = false) {
      const group = new THREE.Group();
      const armGeo = new THREE.BoxGeometry(0.3, 1.6, 0.3);
      const topArm = new THREE.Mesh(armGeo, mats.neonCyan);
      topArm.position.set(flip ? 0.45 : -0.45, 0.5, 0);
      topArm.rotation.z = flip ? Math.PI / 4 : -Math.PI / 4;
      group.add(topArm);

      const btmArm = new THREE.Mesh(armGeo, mats.neonCyan);
      btmArm.position.set(flip ? 0.45 : -0.45, -0.5, 0);
      btmArm.rotation.z = flip ? -Math.PI / 4 : Math.PI / 4;
      group.add(btmArm);
      return group;
    }

    const chevronLeft = createChevron(false);
    registerPart(
      chevronLeft,
      new THREE.Vector3(-3.2, 0, 0.8),
      new THREE.Euler(0, 0.2, 0),
      new THREE.Vector3(-14, 4, 10),
      new THREE.Euler(0.8, -1.1, 0.5)
    );

    const chevronRight = createChevron(true);
    registerPart(
      chevronRight,
      new THREE.Vector3(3.2, 0, 0.8),
      new THREE.Euler(0, -0.2, 0),
      new THREE.Vector3(14, 5, 9),
      new THREE.Euler(-0.6, 1.3, -0.4)
    );

    // Token: Central "T" Glyph
    const tGroup = new THREE.Group();
    const tBarH = new THREE.Mesh(new THREE.BoxGeometry(1.5, 0.3, 0.3), mats.chromeMetal);
    tBarH.position.y = 0.8;
    tGroup.add(tBarH);
    const tBarV = new THREE.Mesh(new THREE.BoxGeometry(0.35, 1.7, 0.3), mats.chromeMetal);
    tBarV.position.y = 0;
    tGroup.add(tBarV);
    registerPart(
      tGroup,
      new THREE.Vector3(0, 2.2, 1.0),
      new THREE.Euler(0, 0, 0),
      new THREE.Vector3(0, 12, 12),
      new THREE.Euler(1.4, 0.5, -0.7)
    );

    // Token: Bracket Pairs "{" and "}"
    const bracketGeo = new THREE.TorusGeometry(1.2, 0.15, 16, 32, Math.PI);
    const bracketL = new THREE.Mesh(bracketGeo, mats.glassCyan);
    registerPart(
      bracketL,
      new THREE.Vector3(-2.8, -1.8, 0.5),
      new THREE.Euler(0, 0, Math.PI / 2),
      new THREE.Vector3(-11, -8, 6),
      new THREE.Euler(0.9, 0.4, 1.2)
    );

    const bracketR = new THREE.Mesh(bracketGeo, mats.glassCyan);
    registerPart(
      bracketR,
      new THREE.Vector3(2.8, -1.8, 0.5),
      new THREE.Euler(0, 0, -Math.PI / 2),
      new THREE.Vector3(11, -7, 7),
      new THREE.Euler(-0.8, -0.6, -1.1)
    );

    // ─────────────────────────────────────────────────────────────
    // 3. ROBLOX SCRIPT & MODULE BLOCKS
    // ─────────────────────────────────────────────────────────────
    // ModuleScript Beveled Cube (Left)
    const cubeGeo = new THREE.BoxGeometry(2.0, 2.0, 0.6);
    const moduleCube = new THREE.Mesh(cubeGeo, moduleMat);
    // Add small stud on top like Roblox brick
    const studGeo = new THREE.CylinderGeometry(0.35, 0.35, 0.3, 16);
    const stud = new THREE.Mesh(studGeo, mats.neonPurple);
    stud.position.y = 1.1;
    moduleCube.add(stud);
    registerPart(
      moduleCube,
      new THREE.Vector3(-3.5, 1.8, -1.2),
      new THREE.Euler(0, 0.4, 0.1),
      new THREE.Vector3(-15, 10, -8),
      new THREE.Euler(1.8, -1.2, 0.3)
    );

    // Production Script Cube (Right)
    const scriptCube = new THREE.Mesh(cubeGeo, scriptMat);
    const stud2 = new THREE.Mesh(studGeo, mats.neonCyan);
    stud2.position.y = 1.1;
    scriptCube.add(stud2);
    registerPart(
      scriptCube,
      new THREE.Vector3(3.5, 1.8, -1.2),
      new THREE.Euler(0, -0.4, -0.1),
      new THREE.Vector3(16, 9, -9),
      new THREE.Euler(-1.5, 1.4, -0.4)
    );

    // Lower Architecture Base Brick
    const baseBrickGeo = new THREE.BoxGeometry(7.0, 0.8, 3.2);
    const baseBrick = new THREE.Mesh(baseBrickGeo, mats.carbonDark);
    registerPart(
      baseBrick,
      new THREE.Vector3(0, -3.2, 0),
      new THREE.Euler(0, 0, 0),
      new THREE.Vector3(0, -14, -10),
      new THREE.Euler(0.7, 0, 0.2)
    );

    // ─────────────────────────────────────────────────────────────
    // 4. LOW-LEVEL VM MEMORY BUFFERS & SIMD HEX PRISMS
    // ─────────────────────────────────────────────────────────────
    const hexGeo = new THREE.CylinderGeometry(0.8, 0.8, 1.2, 6);
    for (let i = 0; i < 4; i++) {
      const angle = (i / 4) * Math.PI * 2;
      const hexMesh = new THREE.Mesh(hexGeo, i % 2 === 0 ? mats.glassCyan : mats.neonPurple);
      const assemP = new THREE.Vector3(Math.cos(angle) * 3.8, Math.sin(angle) * 2.2 - 0.5, -2.0);
      const assemR = new THREE.Euler(0.2, angle, 0.3);

      const expP = new THREE.Vector3(
        Math.cos(angle) * 16 + (Math.random() - 0.5) * 6,
        Math.sin(angle) * 12 + (Math.random() - 0.5) * 6,
        (Math.random() - 0.5) * 14
      );
      const expR = new THREE.Euler(Math.random() * 3, Math.random() * 3, Math.random() * 3);
      registerPart(hexMesh, assemP, assemR, expP, expR, 0.85);
    }

    // ─────────────────────────────────────────────────────────────
    // 5. 120+ EXPLODED CARBON SHARDS & NEON CRYSTAL FRAGMENTS
    // ─────────────────────────────────────────────────────────────
    const shardGeos = [
      new THREE.ConeGeometry(0.4, 1.2, 4),
      new THREE.BoxGeometry(0.8, 0.25, 1.4),
      new THREE.TetrahedronGeometry(0.5, 0),
      new THREE.OctahedronGeometry(0.45, 0)
    ];

    const shardMaterials = [
      mats.carbonDark,
      mats.neonCyan,
      mats.chromeMetal,
      mats.neonPurple,
      mats.glassCyan
    ];

    const totalShards = 120;
    for (let i = 0; i < totalShards; i++) {
      const geo = shardGeos[i % shardGeos.length];
      const mat = shardMaterials[i % shardMaterials.length];
      const shardMesh = new THREE.Mesh(geo, mat);

      // Assembled: tight halo around the Luau Core and base
      const theta = Math.random() * Math.PI * 2;
      const phi = (Math.random() - 0.5) * Math.PI;
      const radius = 2.8 + Math.random() * 2.5;

      const assemPos = new THREE.Vector3(
        radius * Math.cos(phi) * Math.cos(theta),
        radius * Math.sin(phi),
        radius * Math.cos(phi) * Math.sin(theta)
      );
      const assemRot = new THREE.Euler(Math.random() * Math.PI, Math.random() * Math.PI, 0);

      // Exploded: scattered far out across space
      const expDist = 14 + Math.random() * 18;
      const expPos = new THREE.Vector3(
        assemPos.x * (expDist / radius) + (Math.random() - 0.5) * 8,
        assemPos.y * (expDist / radius) + (Math.random() - 0.5) * 8,
        assemPos.z * (expDist / radius) + (Math.random() - 0.5) * 8
      );
      const expRot = new THREE.Euler(Math.random() * 6, Math.random() * 6, Math.random() * 6);

      registerPart(shardMesh, assemPos, assemRot, expPos, expRot, 0.4 + Math.random() * 0.7);
    }

    // ─────────────────────────────────────────────────────────────
    // 6. SCROLL INTERPOLATION & CAMERA SPLINE
    // ─────────────────────────────────────────────────────────────
    let targetScroll = 0;
    let currentScroll = 0;
    let scrollVelocity = 0;
    let lastScroll = 0;

    function updateScrollProgress() {
      const rect = container.getBoundingClientRect();
      const scrollHeight = container.offsetHeight - window.innerHeight;
      if (scrollHeight <= 0) return;

      const progress = -rect.top / scrollHeight;
      targetScroll = Math.max(0, Math.min(1, progress));
    }

    window.addEventListener('scroll', updateScrollProgress, { passive: true });
    window.addEventListener('resize', () => {
      camera.aspect = window.innerWidth / window.innerHeight;
      camera.updateProjectionMatrix();
      renderer.setSize(window.innerWidth, window.innerHeight);
      updateScrollProgress();
    });
    updateScrollProgress();

    // Mouse Parallax Rig
    const mouse = { x: 0, y: 0, targetX: 0, targetY: 0 };
    window.addEventListener('mousemove', (e) => {
      mouse.targetX = (e.clientX / window.innerWidth - 0.5) * 2;
      mouse.targetY = (e.clientY / window.innerHeight - 0.5) * 2;
    });

    // Camera Spline Waypoints corresponding to the 5 stages
    const cameraWaypoints = [
      // Stage 0: Intro / Wide Exploded Chaos (t = 0.0)
      {
        pos: new THREE.Vector3(0, 3.5, 24),
        lookAt: new THREE.Vector3(0, 0, 0)
      },
      // Stage 1: Focus on Type Solver (<T>, strict) (t = 0.22)
      {
        pos: new THREE.Vector3(-4.5, 1.8, 12),
        lookAt: new THREE.Vector3(-1.8, 0.8, 0)
      },
      // Stage 2: Focus on VM & Bytecode (t = 0.48)
      {
        pos: new THREE.Vector3(5.2, 3.2, 10.5),
        lookAt: new THREE.Vector3(1.5, 0.5, -0.5)
      },
      // Stage 3: Focus on Architecture & Modules (t = 0.72)
      {
        pos: new THREE.Vector3(0, 5.5, 14),
        lookAt: new THREE.Vector3(0, -0.5, 0)
      },
      // Stage 4: Telemetry Benchmarks Overview (t = 0.88)
      {
        pos: new THREE.Vector3(-3.5, 2.5, 17),
        lookAt: new THREE.Vector3(0, 0, 0)
      },
      // Stage 5: Final Radiant Assembly "ПОЕХАЛИ" (t = 1.0)
      {
        pos: new THREE.Vector3(0, 2.0, 15.5),
        lookAt: new THREE.Vector3(0, 0, 0)
      }
    ];

    function getInterpolatedCamera(t) {
      const segCount = cameraWaypoints.length - 1;
      const scaled = t * segCount;
      const idx = Math.min(Math.floor(scaled), segCount - 1);
      const alpha = scaled - idx;

      // Smooth step
      const smoothAlpha = alpha * alpha * (3 - 2 * alpha);

      const p1 = cameraWaypoints[idx].pos;
      const p2 = cameraWaypoints[idx + 1].pos;
      const l1 = cameraWaypoints[idx].lookAt;
      const l2 = cameraWaypoints[idx + 1].lookAt;

      const pos = new THREE.Vector3().lerpVectors(p1, p2, smoothAlpha);
      const lookAt = new THREE.Vector3().lerpVectors(l1, l2, smoothAlpha);

      return { pos, lookAt };
    }

    // ─────────────────────────────────────────────────────────────
    // 7. HUD SYNCHRONIZATION (DOM Elements)
    // ─────────────────────────────────────────────────────────────
    const speedEl = document.getElementById('f1SpeedVal');
    const stageValEl = document.getElementById('f1StageVal');
    const progressFillEl = document.getElementById('f1ProgressFill');
    const ledBars = document.querySelectorAll('.led-segment');
    const stageCards = document.querySelectorAll('.luau-stage-card');
    const tickerAssemblyVal = document.getElementById('tickerAssemblyVal');

    let currentStageIndex = -1;
    let assembledSoundTriggered = false;

    function syncHUD(t) {
      // 1. Dynamic Speed / Tickrate readout (000 to 060 FPS or 360 Units)
      const simulatedSpeed = Math.round(t * 360);
      if (speedEl) {
        speedEl.textContent = String(simulatedSpeed).padStart(3, '0');
      }

      const percent = Math.round(t * 100);
      if (tickerAssemblyVal) {
        tickerAssemblyVal.textContent = `${percent}%`;
      }
      if (progressFillEl) {
        progressFillEl.style.width = `${percent}%`;
      }

      // 2. LED Segment Bar Fill
      if (ledBars && ledBars.length > 0) {
        const activeCount = Math.floor(t * ledBars.length);
        ledBars.forEach((bar, i) => {
          if (i <= activeCount) {
            bar.classList.add('active');
          } else {
            bar.classList.remove('active');
          }
        });
      }

      // 3. Stage Determination (0 to 5)
      let stageIdx = 0;
      if (t < 0.15) stageIdx = 0;
      else if (t < 0.38) stageIdx = 1;
      else if (t < 0.62) stageIdx = 2;
      else if (t < 0.82) stageIdx = 3;
      else if (t < 0.94) stageIdx = 4;
      else stageIdx = 5;

      if (stageValEl) {
        stageValEl.textContent = `0${stageIdx} // 05`;
      }

      if (stageIdx !== currentStageIndex) {
        currentStageIndex = stageIdx;
        sfx.playWhoosh(1.2);

        stageCards.forEach((card) => {
          const cardStage = parseInt(card.getAttribute('data-stage'), 10);
          if (cardStage === stageIdx) {
            card.classList.add('active');
          } else {
            card.classList.remove('active');
          }
        });

        // Trigger finish chime
        if (stageIdx === 5 && !assembledSoundTriggered) {
          assembledSoundTriggered = true;
          sfx.playAssembleChime();
        } else if (stageIdx < 5) {
          assembledSoundTriggered = false;
        }
      }
    }

    // ─────────────────────────────────────────────────────────────
    // 8. INTERACTIVE BUTTON CONTROLS
    // ─────────────────────────────────────────────────────────────
    const resetBtn = document.getElementById('btnAssembleReset');
    if (resetBtn) {
      resetBtn.addEventListener('click', (e) => {
        e.preventDefault();
        sfx.playClick();
        window.scrollTo({
          top: container.offsetTop,
          behavior: 'smooth'
        });
      });
    }

    const inspectBtn = document.getElementById('btnInspectPortfolio');
    if (inspectBtn) {
      inspectBtn.addEventListener('click', (e) => {
        e.preventDefault();
        sfx.playClick();
        const heroSection = document.getElementById('hero');
        if (heroSection) {
          heroSection.scrollIntoView({ behavior: 'smooth' });
        }
      });
    }

    // Audio Mute Toggle Button
    const audioToggleBtn = document.getElementById('hudAudioToggle');
    if (audioToggleBtn) {
      audioToggleBtn.addEventListener('click', () => {
        const isMuted = sfx.toggleMute();
        audioToggleBtn.classList.toggle('muted', isMuted);
        const icon = audioToggleBtn.querySelector('.audio-icon');
        if (icon) {
          icon.textContent = isMuted ? '🔇' : '🔊';
        }
      });
    }

    // Top HUD Navigation Jump Anchors
    document.querySelectorAll('.hud-jump-link').forEach((link) => {
      link.addEventListener('click', (e) => {
        e.preventDefault();
        sfx.playClick();
        const targetPercent = parseFloat(link.getAttribute('data-jump') || '0');
        const scrollDistance = container.offsetHeight - window.innerHeight;
        const targetScrollY = container.offsetTop + targetPercent * scrollDistance;
        window.scrollTo({
          top: targetScrollY,
          behavior: 'smooth'
        });
      });
    });

    // ─────────────────────────────────────────────────────────────
    // 9. ANIMATION & RENDER LOOP
    // ─────────────────────────────────────────────────────────────
    let clock = new THREE.Clock();

    function renderLoop() {
      requestAnimationFrame(renderLoop);

      const delta = clock.getDelta();
      const elapsed = clock.getElapsedTime();

      // Damped smooth scroll interpolation (Inertia loop)
      const prevScroll = currentScroll;
      currentScroll += (targetScroll - currentScroll) * 0.075;
      scrollVelocity = Math.abs(currentScroll - prevScroll);

      // Play subtle whoosh on energetic scroll flick
      if (scrollVelocity > 0.015) {
        sfx.playWhoosh(scrollVelocity * 40);
      }

      // Smooth mouse parallax
      mouse.x += (mouse.targetX - mouse.x) * 0.05;
      mouse.y += (mouse.targetY - mouse.y) * 0.05;

      // 1. Camera trajectory along spline
      const camTarget = getInterpolatedCamera(currentScroll);
      camera.position.x = camTarget.pos.x + mouse.x * 0.6;
      camera.position.y = camTarget.pos.y - mouse.y * 0.4;
      camera.position.z = camTarget.pos.z;

      const lookTarget = new THREE.Vector3(
        camTarget.lookAt.x + mouse.x * 0.2,
        camTarget.lookAt.y - mouse.y * 0.2,
        camTarget.lookAt.z
      );
      camera.lookAt(lookTarget);

      // 2. Linear morphing of all 3D modular components
      // When currentScroll = 0 (exploded); when currentScroll = 1 (fully assembled)
      const assembleFactor = Math.min(Math.max((currentScroll - 0.08) / 0.84, 0), 1);
      // Non-linear ease out for snap
      const easeAssemble = 1 - Math.pow(1 - assembleFactor, 3);

      for (let i = 0; i < modularParts.length; i++) {
        const part = modularParts[i];
        // Interpolate position from exploded to assembled
        part.mesh.position.lerpVectors(part.explodedPos, part.assembledPos, easeAssemble);

        // Rotation interpolation
        part.mesh.rotation.x = THREE.MathUtils.lerp(part.explodedRot.x, part.assembledRot.x, easeAssemble);
        part.mesh.rotation.y = THREE.MathUtils.lerp(part.explodedRot.y, part.assembledRot.y, easeAssemble);
        part.mesh.rotation.z = THREE.MathUtils.lerp(part.explodedRot.z, part.assembledRot.z, easeAssemble);

        // Subtle ambient floating drift when exploded
        if (easeAssemble < 0.98) {
          const drift = Math.sin(elapsed * 1.5 + i * 0.3) * (1 - easeAssemble) * 0.012;
          part.mesh.position.y += drift;
          part.mesh.rotation.y += (1 - easeAssemble) * 0.005;
        }
      }

      // 3. Continuous rotation of rings and core when assembled
      if (ring1) ring1.rotation.z += 0.01;
      if (ring2) ring2.rotation.x += 0.012;
      if (crescent) crescent.rotation.y += 0.006;
      if (satellite) {
        const satAngle = elapsed * 1.8;
        satellite.position.x = Math.cos(satAngle) * 3.2;
        satellite.position.z = Math.sin(satAngle) * 3.2;
      }

      // 4. Starfield subtle drift + acceleration streak
      const positions = starfield.geometry.attributes.position.array;
      const speedMult = 1 + scrollVelocity * 50;
      for (let i = 2; i < positions.length; i += 3) {
        positions[i] += 0.03 * speedMult;
        if (positions[i] > 35) positions[i] = -35;
      }
      starfield.geometry.attributes.position.needsUpdate = true;
      starfield.rotation.y = elapsed * 0.02;

      // 5. Light pulse
      coreLight.intensity = 2.8 + Math.sin(elapsed * 3) * 0.7;

      // 6. Update HUD telemetry
      syncHUD(currentScroll);

      renderer.render(scene, camera);
    }

    renderLoop();
  }

  // Initialize once DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initEngine);
  } else {
    initEngine();
  }
})();
