/**
 * ══════════════════════════════════════════════════════════════
 * SCROLLY-LUAU-ENGINE.JS (v3.0 - Perfected Scale & Cinema Rig)
 * 3D Scrollytelling Exploded-View Assembly Engine (Three.js)
 * Features:
 *   - Balanced 3D Luau Emblem (Core, Crescent, Gyro Rings)
 *   - Perfectly Proportioned 3D Tokens (<T>, { }, Script Cubes, Buffers)
 *   - 140+ Dynamic Crystalline & Carbon Shards
 *   - Calibrated 3D Camera Spline (No clipping, pure cinematic framing)
 *   - Damped Inertia Lerp Loop (Fluid 60-120 FPS)
 *   - Cyberpunk Telemetry Speedometer & LED Gauge Sync
 *   - Synthesized Web Audio Sound Effects
 * ══════════════════════════════════════════════════════════════
 */

(function () {
  'use strict';

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
        try {
          const now = this.ctx.currentTime;
          const osc = this.ctx.createOscillator();
          const gain = this.ctx.createGain();
          osc.type = 'sine';
          osc.frequency.setValueAtTime(1200, now);
          osc.frequency.exponentialRampToValueAtTime(500, now + 0.04);
          gain.gain.setValueAtTime(0.05, now);
          gain.gain.exponentialRampToValueAtTime(0.001, now + 0.04);
          osc.connect(gain);
          gain.connect(this.ctx.destination);
          osc.start(now);
          osc.stop(now + 0.04);
        } catch (e) {}
      }

      playWhoosh(intensity = 1) {
        if (this.muted) return;
        const nowMs = Date.now();
        if (nowMs - this.lastPlayTime < 220) return;
        this.lastPlayTime = nowMs;
        this.init();
        if (!this.ctx) return;

        try {
          const now = this.ctx.currentTime;
          const bufferSize = Math.floor(this.ctx.sampleRate * 0.12);
          const buffer = this.ctx.createBuffer(1, bufferSize, this.ctx.sampleRate);
          const data = buffer.getChannelData(0);
          for (let i = 0; i < bufferSize; i++) {
            data[i] = Math.random() * 2 - 1;
          }

          const noise = this.ctx.createBufferSource();
          noise.buffer = buffer;

          const filter = this.ctx.createBiquadFilter();
          filter.type = 'bandpass';
          filter.frequency.setValueAtTime(320, now);
          filter.frequency.exponentialRampToValueAtTime(800, now + 0.1);
          filter.Q.value = 2.5;

          const gain = this.ctx.createGain();
          gain.gain.setValueAtTime(0.03 * Math.min(intensity, 2), now);
          gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.12);

          noise.connect(filter);
          filter.connect(gain);
          gain.connect(this.ctx.destination);

          noise.start(now);
          noise.stop(now + 0.12);
        } catch (e) {}
      }

      playAssembleChime() {
        if (this.muted) return;
        this.init();
        if (!this.ctx) return;

        try {
          const now = this.ctx.currentTime;
          const freqs = [523.25, 659.25, 783.99, 1046.5];
          freqs.forEach((freq, idx) => {
            const osc = this.ctx.createOscillator();
            const gain = this.ctx.createGain();
            osc.type = 'triangle';
            osc.frequency.setValueAtTime(freq, now + idx * 0.06);

            gain.gain.setValueAtTime(0.07, now + idx * 0.06);
            gain.gain.exponentialRampToValueAtTime(0.0001, now + idx * 0.06 + 0.45);

            osc.connect(gain);
            gain.connect(this.ctx.destination);

            osc.start(now + idx * 0.06);
            osc.stop(now + idx * 0.06 + 0.5);
          });
        } catch (e) {}
      }
    }

    const sfx = new SoundFX();

    // --- Three.js Scene Setup ---
    const scene = new THREE.Scene();
    scene.fog = new THREE.FogExp2(0x07090e, 0.022);

    const camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.1, 1000);
    camera.position.set(0, 2.0, 18);

    const renderer = new THREE.WebGLRenderer({
      canvas: stage,
      antialias: true,
      alpha: true,
      powerPreference: 'high-performance'
    });
    renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure = 1.2;

    // --- Lighting Rig ---
    const ambientLight = new THREE.AmbientLight(0x0e1422, 1.4);
    scene.add(ambientLight);

    const keyLight = new THREE.DirectionalLight(0x00f2fe, 2.4);
    keyLight.position.set(10, 15, 12);
    scene.add(keyLight);

    const rimLight = new THREE.DirectionalLight(0xa855f7, 2.8);
    rimLight.position.set(-12, -6, -10);
    scene.add(rimLight);

    const frontLight = new THREE.PointLight(0xffffff, 1.2, 35);
    frontLight.position.set(0, 3, 14);
    scene.add(frontLight);

    const coreLight = new THREE.PointLight(0x00f2fe, 3.2, 20);
    coreLight.position.set(0, 0.8, 0);
    scene.add(coreLight);

    // --- Floor Grid & Stage ---
    const gridHelper = new THREE.GridHelper(120, 60, 0x00f2fe, 0x111c2e);
    gridHelper.position.y = -4.5;
    scene.add(gridHelper);

    // Dark mirror ground plate
    const groundGeo = new THREE.PlaneGeometry(140, 140);
    const groundMat = new THREE.MeshStandardMaterial({
      color: 0x07090e,
      roughness: 0.18,
      metalness: 0.82
    });
    const ground = new THREE.Mesh(groundGeo, groundMat);
    ground.rotation.x = -Math.PI / 2;
    ground.position.y = -4.52;
    scene.add(ground);

    // --- Starfield & Cyber Dust ---
    const particleCount = 550;
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
      particlePos[i * 3] = (Math.random() - 0.5) * 60;
      particlePos[i * 3 + 1] = (Math.random() - 0.5) * 45;
      particlePos[i * 3 + 2] = (Math.random() - 0.5) * 55;

      const c = colorPalette[Math.floor(Math.random() * colorPalette.length)];
      particleColors[i * 3] = c.r;
      particleColors[i * 3 + 1] = c.g;
      particleColors[i * 3 + 2] = c.b;
    }

    particleGeo.setAttribute('position', new THREE.BufferAttribute(particlePos, 3));
    particleGeo.setAttribute('color', new THREE.BufferAttribute(particleColors, 3));

    const particleMat = new THREE.PointsMaterial({
      size: 0.22,
      vertexColors: true,
      transparent: true,
      opacity: 0.7,
      blending: THREE.AdditiveBlending
    });
    const starfield = new THREE.Points(particleGeo, particleMat);
    scene.add(starfield);

    // --- 3D Modular Assembly Core ---
    const mainGroup = new THREE.Group();
    mainGroup.position.set(0, 0.8, 0); // Elegantly centered in viewport
    scene.add(mainGroup);

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
        explodedRot: explodedRot.clone()
      });
    }

    // Material Library
    const mats = {
      carbonDark: new THREE.MeshStandardMaterial({
        color: 0x111622,
        roughness: 0.35,
        metalness: 0.9
      }),
      neonCyan: new THREE.MeshStandardMaterial({
        color: 0x00f2fe,
        emissive: 0x00c8d4,
        emissiveIntensity: 0.75,
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
        opacity: 0.6,
        roughness: 0.1,
        metalness: 0.1,
        transmission: 0.65,
        ior: 1.5
      }),
      chromeMetal: new THREE.MeshStandardMaterial({
        color: 0xdde8f6,
        roughness: 0.12,
        metalness: 0.95
      }),
      goldAccent: new THREE.MeshStandardMaterial({
        color: 0xf59e0b,
        emissive: 0xd97706,
        emissiveIntensity: 0.45,
        roughness: 0.2,
        metalness: 0.85
      })
    };

    // Helper: Texture Generator for Roblox Script Icons
    function createScriptTexture(type = 'script') {
      const cv = document.createElement('canvas');
      cv.width = 256;
      cv.height = 256;
      const c = cv.getContext('2d');

      c.fillStyle = type === 'module' ? '#0f172a' : '#090d16';
      c.fillRect(0, 0, 256, 256);

      c.strokeStyle = type === 'module' ? '#a855f7' : '#00f2fe';
      c.lineWidth = 10;
      c.strokeRect(5, 5, 246, 246);

      c.fillStyle = type === 'module' ? '#c084fc' : '#38bdf8';
      c.font = 'bold 34px monospace';
      c.textAlign = 'center';
      c.textBaseline = 'middle';
      c.fillText(type === 'module' ? 'MODULE' : 'LUAU', 128, 64);

      c.fillStyle = '#ffffff';
      c.font = 'bold 26px monospace';
      c.fillText(type === 'module' ? 'return Module' : 'local Service', 128, 128);

      c.fillStyle = type === 'module' ? '#a855f7' : '#00f2fe';
      c.font = '20px monospace';
      c.fillText(':: StrictType', 128, 192);

      return new THREE.CanvasTexture(cv);
    }

    const scriptTex = createScriptTexture('script');
    const moduleTex = createScriptTexture('module');

    const scriptMat = new THREE.MeshStandardMaterial({ map: scriptTex, roughness: 0.3, metalness: 0.7 });
    const moduleMat = new THREE.MeshStandardMaterial({ map: moduleTex, roughness: 0.3, metalness: 0.7 });

    // ─────────────────────────────────────────────────────────────
    // 1. CENTRAL LUAU CORE & CRESCENT MOON EMBLEM (Scale Refined)
    // ─────────────────────────────────────────────────────────────
    // A: Glowing Core Sphere
    const coreSphereGeo = new THREE.SphereGeometry(0.9, 32, 32);
    const coreSphere = new THREE.Mesh(coreSphereGeo, mats.neonCyan);
    registerPart(
      coreSphere,
      new THREE.Vector3(0, 0, 0),
      new THREE.Euler(0, 0, 0),
      new THREE.Vector3(0, 3.2, -4.5),
      new THREE.Euler(1.1, 0.6, 0)
    );

    // B: Luau Outer Crescent Arc (Torus segment)
    const crescentGeo = new THREE.TorusGeometry(1.5, 0.22, 20, 50, Math.PI * 1.55);
    const crescent = new THREE.Mesh(crescentGeo, mats.chromeMetal);
    registerPart(
      crescent,
      new THREE.Vector3(0, 0, 0),
      new THREE.Euler(0, 0, Math.PI * 0.25),
      new THREE.Vector3(-4.5, 4.2, 2.5),
      new THREE.Euler(-0.6, 1.2, 0.3)
    );

    // C: Luau Orbiting Satellite Node
    const satelliteGeo = new THREE.SphereGeometry(0.32, 20, 20);
    const satellite = new THREE.Mesh(satelliteGeo, mats.goldAccent);
    registerPart(
      satellite,
      new THREE.Vector3(1.6, 1.2, 0.2),
      new THREE.Euler(0, 0, 0),
      new THREE.Vector3(5.5, 4.5, -3.2),
      new THREE.Euler(0.4, -0.9, 0.6)
    );

    // D: Concentric Gimbal Ring 1
    const ring1Geo = new THREE.TorusGeometry(2.1, 0.04, 16, 64);
    const ring1 = new THREE.Mesh(ring1Geo, mats.neonCyan);
    registerPart(
      ring1,
      new THREE.Vector3(0, 0, 0),
      new THREE.Euler(Math.PI / 4, 0, 0),
      new THREE.Vector3(0, -5.2, 4.0),
      new THREE.Euler(1.2, -0.5, 0)
    );

    // E: Concentric Gimbal Ring 2
    const ring2Geo = new THREE.TorusGeometry(2.6, 0.04, 16, 64);
    const ring2 = new THREE.Mesh(ring2Geo, mats.neonPurple);
    registerPart(
      ring2,
      new THREE.Vector3(0, 0, 0),
      new THREE.Euler(0, Math.PI / 3, Math.PI / 6),
      new THREE.Vector3(4.2, -4.8, -3.8),
      new THREE.Euler(-0.9, 0.7, 1.1)
    );

    // ─────────────────────────────────────────────────────────────
    // 2. 3D TYPE SOLVER TOKENS (<T>, { })
    // ─────────────────────────────────────────────────────────────
    function createChevron(flip = false) {
      const group = new THREE.Group();
      const armGeo = new THREE.BoxGeometry(0.18, 1.0, 0.18);
      const topArm = new THREE.Mesh(armGeo, mats.neonCyan);
      topArm.position.set(flip ? 0.3 : -0.3, 0.32, 0);
      topArm.rotation.z = flip ? Math.PI / 4 : -Math.PI / 4;
      group.add(topArm);

      const btmArm = new THREE.Mesh(armGeo, mats.neonCyan);
      btmArm.position.set(flip ? 0.3 : -0.3, -0.32, 0);
      btmArm.rotation.z = flip ? -Math.PI / 4 : Math.PI / 4;
      group.add(btmArm);
      return group;
    }

    const chevronLeft = createChevron(false);
    registerPart(
      chevronLeft,
      new THREE.Vector3(-2.1, 0, 0.5),
      new THREE.Euler(0, 0.2, 0),
      new THREE.Vector3(-7.5, 2.5, 4.5),
      new THREE.Euler(0.6, -0.9, 0.4)
    );

    const chevronRight = createChevron(true);
    registerPart(
      chevronRight,
      new THREE.Vector3(2.1, 0, 0.5),
      new THREE.Euler(0, -0.2, 0),
      new THREE.Vector3(7.5, 2.8, 4.2),
      new THREE.Euler(-0.5, 1.0, -0.3)
    );

    // Central "T" Glyph
    const tGroup = new THREE.Group();
    const tBarH = new THREE.Mesh(new THREE.BoxGeometry(0.9, 0.18, 0.18), mats.chromeMetal);
    tBarH.position.y = 0.48;
    tGroup.add(tBarH);
    const tBarV = new THREE.Mesh(new THREE.BoxGeometry(0.2, 1.0, 0.18), mats.chromeMetal);
    tBarV.position.y = 0;
    tGroup.add(tBarV);
    registerPart(
      tGroup,
      new THREE.Vector3(0, 1.4, 0.6),
      new THREE.Euler(0, 0, 0),
      new THREE.Vector3(0, 6.5, 5.5),
      new THREE.Euler(1.1, 0.4, -0.5)
    );

    // Brackets "{" and "}"
    const bracketGeo = new THREE.TorusGeometry(0.75, 0.09, 14, 28, Math.PI);
    const bracketL = new THREE.Mesh(bracketGeo, mats.glassCyan);
    registerPart(
      bracketL,
      new THREE.Vector3(-1.8, -1.1, 0.3),
      new THREE.Euler(0, 0, Math.PI / 2),
      new THREE.Vector3(-6.2, -4.5, 3.2),
      new THREE.Euler(0.7, 0.3, 0.9)
    );

    const bracketR = new THREE.Mesh(bracketGeo, mats.glassCyan);
    registerPart(
      bracketR,
      new THREE.Vector3(1.8, -1.1, 0.3),
      new THREE.Euler(0, 0, -Math.PI / 2),
      new THREE.Vector3(6.2, -4.2, 3.5),
      new THREE.Euler(-0.6, -0.4, -0.8)
    );

    // ─────────────────────────────────────────────────────────────
    // 3. ROBLOX SCRIPT & MODULE BLOCKS
    // ─────────────────────────────────────────────────────────────
    const cubeGeo = new THREE.BoxGeometry(1.2, 1.2, 0.35);
    const studGeo = new THREE.CylinderGeometry(0.22, 0.22, 0.18, 14);

    const moduleCube = new THREE.Mesh(cubeGeo, moduleMat);
    const stud1 = new THREE.Mesh(studGeo, mats.neonPurple);
    stud1.position.y = 0.68;
    moduleCube.add(stud1);
    registerPart(
      moduleCube,
      new THREE.Vector3(-2.2, 1.2, -0.8),
      new THREE.Euler(0, 0.3, 0.1),
      new THREE.Vector3(-8.2, 5.5, -4.5),
      new THREE.Euler(1.4, -0.9, 0.2)
    );

    const scriptCube = new THREE.Mesh(cubeGeo, scriptMat);
    const stud2 = new THREE.Mesh(studGeo, mats.neonCyan);
    stud2.position.y = 0.68;
    scriptCube.add(stud2);
    registerPart(
      scriptCube,
      new THREE.Vector3(2.2, 1.2, -0.8),
      new THREE.Euler(0, -0.3, -0.1),
      new THREE.Vector3(8.5, 5.2, -5.0),
      new THREE.Euler(-1.2, 1.1, -0.3)
    );

    // Base Architectural Foundation Brick
    const baseBrickGeo = new THREE.BoxGeometry(4.4, 0.45, 2.0);
    const baseBrick = new THREE.Mesh(baseBrickGeo, mats.carbonDark);
    registerPart(
      baseBrick,
      new THREE.Vector3(0, -1.8, 0),
      new THREE.Euler(0, 0, 0),
      new THREE.Vector3(0, -7.5, -5.5),
      new THREE.Euler(0.5, 0, 0.15)
    );

    // ─────────────────────────────────────────────────────────────
    // 4. LOW-LEVEL VM MEMORY BUFFERS & SIMD HEX PRISMS
    // ─────────────────────────────────────────────────────────────
    const hexGeo = new THREE.CylinderGeometry(0.48, 0.48, 0.75, 6);
    for (let i = 0; i < 4; i++) {
      const angle = (i / 4) * Math.PI * 2;
      const hexMesh = new THREE.Mesh(hexGeo, i % 2 === 0 ? mats.glassCyan : mats.neonPurple);
      const assemP = new THREE.Vector3(Math.cos(angle) * 2.4, Math.sin(angle) * 1.4 - 0.2, -1.2);
      const assemR = new THREE.Euler(0.15, angle, 0.2);

      const expP = new THREE.Vector3(
        Math.cos(angle) * 9.5 + (Math.random() - 0.5) * 3,
        Math.sin(angle) * 7.0 + (Math.random() - 0.5) * 3,
        (Math.random() - 0.5) * 7
      );
      const expR = new THREE.Euler(Math.random() * 2.5, Math.random() * 2.5, Math.random() * 2.5);
      registerPart(hexMesh, assemP, assemR, expP, expR, 0.75);
    }

    // ─────────────────────────────────────────────────────────────
    // 5. 130+ CRYSTALLINE & CARBON SHARDS
    // ─────────────────────────────────────────────────────────────
    const shardGeos = [
      new THREE.ConeGeometry(0.25, 0.7, 4),
      new THREE.BoxGeometry(0.45, 0.15, 0.8),
      new THREE.TetrahedronGeometry(0.3, 0),
      new THREE.OctahedronGeometry(0.28, 0)
    ];

    const shardMaterials = [
      mats.carbonDark,
      mats.neonCyan,
      mats.chromeMetal,
      mats.neonPurple,
      mats.glassCyan
    ];

    const totalShards = 130;
    for (let i = 0; i < totalShards; i++) {
      const geo = shardGeos[i % shardGeos.length];
      const mat = shardMaterials[i % shardMaterials.length];
      const shardMesh = new THREE.Mesh(geo, mat);

      const theta = Math.random() * Math.PI * 2;
      const phi = (Math.random() - 0.5) * Math.PI;
      const radius = 1.8 + Math.random() * 1.5;

      const assemPos = new THREE.Vector3(
        radius * Math.cos(phi) * Math.cos(theta),
        radius * Math.sin(phi),
        radius * Math.cos(phi) * Math.sin(theta)
      );
      const assemRot = new THREE.Euler(Math.random() * Math.PI, Math.random() * Math.PI, 0);

      const expDist = 7.5 + Math.random() * 8.5;
      const expPos = new THREE.Vector3(
        assemPos.x * (expDist / radius) + (Math.random() - 0.5) * 4,
        assemPos.y * (expDist / radius) + (Math.random() - 0.5) * 4,
        assemPos.z * (expDist / radius) + (Math.random() - 0.5) * 4
      );
      const expRot = new THREE.Euler(Math.random() * 5, Math.random() * 5, Math.random() * 5);

      registerPart(shardMesh, assemPos, assemRot, expPos, expRot, 0.4 + Math.random() * 0.6);
    }

    // ─────────────────────────────────────────────────────────────
    // 6. SCROLL INTERPOLATION & CAMERA SPLINE
    // ─────────────────────────────────────────────────────────────
    let targetScroll = 0;
    let currentScroll = 0;
    let scrollVelocity = 0;

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

    // Camera Spline (Balanced focal distance)
    const cameraWaypoints = [
      { pos: new THREE.Vector3(0, 2.2, 17.5), lookAt: new THREE.Vector3(0, 0.8, 0) },
      { pos: new THREE.Vector3(-3.2, 1.4, 9.8), lookAt: new THREE.Vector3(-1.2, 0.6, 0) },
      { pos: new THREE.Vector3(3.6, 2.2, 9.2), lookAt: new THREE.Vector3(1.0, 0.5, -0.4) },
      { pos: new THREE.Vector3(0, 3.8, 11.5), lookAt: new THREE.Vector3(0, 0.4, 0) },
      { pos: new THREE.Vector3(-2.2, 1.8, 13.5), lookAt: new THREE.Vector3(0, 0.8, 0) },
      { pos: new THREE.Vector3(0, 1.5, 12.0), lookAt: new THREE.Vector3(0, 0.8, 0) }
    ];

    function getInterpolatedCamera(t) {
      const segCount = cameraWaypoints.length - 1;
      const scaled = t * segCount;
      const idx = Math.min(Math.floor(scaled), segCount - 1);
      const alpha = scaled - idx;
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
    // 7. HUD SYNCHRONIZATION
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
      const simulatedSpeed = Math.round(t * 360);
      if (speedEl) speedEl.textContent = String(simulatedSpeed).padStart(3, '0');

      const percent = Math.round(t * 100);
      if (tickerAssemblyVal) tickerAssemblyVal.textContent = `${percent}%`;
      if (progressFillEl) progressFillEl.style.width = `${percent}%`;

      if (ledBars && ledBars.length > 0) {
        const activeCount = Math.floor(t * ledBars.length);
        ledBars.forEach((bar, i) => {
          if (i <= activeCount) bar.classList.add('active');
          else bar.classList.remove('active');
        });
      }

      let stageIdx = 0;
      if (t < 0.15) stageIdx = 0;
      else if (t < 0.38) stageIdx = 1;
      else if (t < 0.62) stageIdx = 2;
      else if (t < 0.82) stageIdx = 3;
      else if (t < 0.94) stageIdx = 4;
      else stageIdx = 5;

      if (stageValEl) stageValEl.textContent = `0${stageIdx} // 05`;

      if (stageIdx !== currentStageIndex) {
        currentStageIndex = stageIdx;
        sfx.playWhoosh(1.0);

        stageCards.forEach((card) => {
          const cardStage = parseInt(card.getAttribute('data-stage'), 10);
          if (cardStage === stageIdx) {
            card.classList.add('active');
          } else {
            card.classList.remove('active');
          }
        });

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
        window.scrollTo({ top: container.offsetTop, behavior: 'smooth' });
      });
    }

    const inspectBtn = document.getElementById('btnInspectPortfolio');
    if (inspectBtn) {
      inspectBtn.addEventListener('click', (e) => {
        e.preventDefault();
        sfx.playClick();
        const heroSection = document.getElementById('hero');
        if (heroSection) heroSection.scrollIntoView({ behavior: 'smooth' });
      });
    }

    const audioToggleBtn = document.getElementById('hudAudioToggle');
    if (audioToggleBtn) {
      audioToggleBtn.addEventListener('click', () => {
        const isMuted = sfx.toggleMute();
        audioToggleBtn.classList.toggle('muted', isMuted);
        const icon = audioToggleBtn.querySelector('.audio-icon');
        if (icon) icon.textContent = isMuted ? '🔇' : '🔊';
      });
    }

    document.querySelectorAll('.hud-jump-link').forEach((link) => {
      link.addEventListener('click', (e) => {
        e.preventDefault();
        sfx.playClick();
        const targetPercent = parseFloat(link.getAttribute('data-jump') || '0');
        const scrollDistance = container.offsetHeight - window.innerHeight;
        const targetScrollY = container.offsetTop + targetPercent * scrollDistance;
        window.scrollTo({ top: targetScrollY, behavior: 'smooth' });
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

      const prevScroll = currentScroll;
      currentScroll += (targetScroll - currentScroll) * 0.075;
      scrollVelocity = Math.abs(currentScroll - prevScroll);

      if (scrollVelocity > 0.018) {
        sfx.playWhoosh(scrollVelocity * 35);
      }

      mouse.x += (mouse.targetX - mouse.x) * 0.05;
      mouse.y += (mouse.targetY - mouse.y) * 0.05;

      const camTarget = getInterpolatedCamera(currentScroll);
      camera.position.x = camTarget.pos.x + mouse.x * 0.45;
      camera.position.y = camTarget.pos.y - mouse.y * 0.3;
      camera.position.z = camTarget.pos.z;

      const lookTarget = new THREE.Vector3(
        camTarget.lookAt.x + mouse.x * 0.15,
        camTarget.lookAt.y - mouse.y * 0.15,
        camTarget.lookAt.z
      );
      camera.lookAt(lookTarget);

      // Morphing from exploded to assembled
      const assembleFactor = Math.min(Math.max((currentScroll - 0.08) / 0.84, 0), 1);
      const easeAssemble = 1 - Math.pow(1 - assembleFactor, 3);

      for (let i = 0; i < modularParts.length; i++) {
        const part = modularParts[i];
        part.mesh.position.lerpVectors(part.explodedPos, part.assembledPos, easeAssemble);

        part.mesh.rotation.x = THREE.MathUtils.lerp(part.explodedRot.x, part.assembledRot.x, easeAssemble);
        part.mesh.rotation.y = THREE.MathUtils.lerp(part.explodedRot.y, part.assembledRot.y, easeAssemble);
        part.mesh.rotation.z = THREE.MathUtils.lerp(part.explodedRot.z, part.assembledRot.z, easeAssemble);

        if (easeAssemble < 0.98) {
          const drift = Math.sin(elapsed * 1.5 + i * 0.25) * (1 - easeAssemble) * 0.008;
          part.mesh.position.y += drift;
          part.mesh.rotation.y += (1 - easeAssemble) * 0.004;
        }
      }

      if (ring1) ring1.rotation.z += 0.008;
      if (ring2) ring2.rotation.x += 0.01;
      if (crescent) crescent.rotation.y += 0.005;
      if (satellite) {
        const satAngle = elapsed * 1.6;
        satellite.position.x = Math.cos(satAngle) * 2.2;
        satellite.position.z = Math.sin(satAngle) * 2.2;
      }

      const positions = starfield.geometry.attributes.position.array;
      const speedMult = 1 + scrollVelocity * 45;
      for (let i = 2; i < positions.length; i += 3) {
        positions[i] += 0.025 * speedMult;
        if (positions[i] > 30) positions[i] = -30;
      }
      starfield.geometry.attributes.position.needsUpdate = true;
      starfield.rotation.y = elapsed * 0.015;

      coreLight.intensity = 2.6 + Math.sin(elapsed * 3) * 0.6;

      syncHUD(currentScroll);

      renderer.render(scene, camera);
    }

    renderLoop();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initEngine);
  } else {
    initEngine();
  }
})();
