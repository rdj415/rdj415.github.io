/**
 * ══════════════════════════════════════════════════════════════
 * SCROLLY-LUAU-ENGINE.JS (v5.0 - Master Luau Monument)
 * 3D Scrollytelling Exploded-View Assembly Engine (Three.js)
 * 
 * Features:
 *   - Iconic 3D Luau Celestial Core (Dual-Shell Planet, Quantum Icosahedron,
 *     High-Refraction Optical Mantle with Circuit Traces)
 *   - Sculpted 3D Extruded Crescent Moon with Cyan Neon Edge Piping
 *   - Orbiting Polished Gold Celestial Moon with Dual Gimbal Rings & Orbit Track
 *   - Sculpted 3D Type System Glyphs: Beveled < T > & Parametric Curly Braces { }
 *   - Authentic 3D Roblox Architectural Blocks with Real Cylindrical Studs &
 *     512x512 Hi-Res Luau Syntax Textures (ServerScript, ModuleScript, Parallel Actor)
 *   - Low-Level VM Memory Hex Prisms (buffer.create / SIMD) & Vector3 RGB Axis Gizmo
 *   - Dynamic Laser Blueprint Alignment Rays (Exploded CAD Engineering Schematic)
 *   - 150+ Holographic Shards & 550 Starfield Particles
 *   - Calibrated 3D Camera Spline (Balanced Focal Length, Zero Clipping)
 *   - Damped Inertia Lerp Loop (Fluid 60-120 FPS)
 *   - Cyberpunk Telemetry Speedometer & LED Gauge Sync
 *   - PURE SILENT OPERATION (Zero Audio / Sound Effects)
 * ══════════════════════════════════════════════════════════════
 */

(function () {
  'use strict';

  function initEngine() {
    if (typeof THREE === 'undefined') {
      setTimeout(initEngine, 50);
      return;
    }

    try {
      console.log('[Luau Engine] Initializing 3D Solar System & Assembly Engine...');
      const container = document.getElementById('scrolly-luau-container');
      const stage = document.getElementById('webgl-stage');
      if (!container || !stage) return;

    // --- Three.js Scene Setup ---
    const scene = new THREE.Scene();
    scene.fog = new THREE.FogExp2(0x07090e, 0.012);

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
    renderer.toneMappingExposure = 1.25;

    // --- Lighting Rig ---
    const ambientLight = new THREE.AmbientLight(0x0e1422, 1.5);
    scene.add(ambientLight);

    const keyLight = new THREE.DirectionalLight(0x00f2fe, 2.6);
    keyLight.position.set(12, 16, 14);
    scene.add(keyLight);

    const rimLight = new THREE.DirectionalLight(0xa855f7, 3.0);
    rimLight.position.set(-14, -8, -12);
    scene.add(rimLight);

    const frontFillLight = new THREE.PointLight(0xffffff, 1.3, 40);
    frontFillLight.position.set(0, 3, 15);
    scene.add(frontFillLight);

    const coreLight = new THREE.PointLight(0x00f2fe, 3.5, 22);
    coreLight.position.set(0, 0.9, 0);
    scene.add(coreLight);

    // --- Floor Grid & Dark Stage Plate ---
    const gridHelper = new THREE.GridHelper(120, 60, 0x00f2fe, 0x111c2e);
    gridHelper.position.y = -4.5;
    scene.add(gridHelper);

    const groundGeo = new THREE.PlaneGeometry(140, 140);
    const groundMat = new THREE.MeshStandardMaterial({
      color: 0x07090e,
      roughness: 0.18,
      metalness: 0.85
    });
    const ground = new THREE.Mesh(groundGeo, groundMat);
    ground.rotation.x = -Math.PI / 2;
    ground.position.y = -4.52;
    scene.add(ground);

    // --- Starfield & Cyber Dust Particles ---
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
      particlePos[i * 3] = (Math.random() - 0.5) * 65;
      particlePos[i * 3 + 1] = (Math.random() - 0.5) * 50;
      particlePos[i * 3 + 2] = (Math.random() - 0.5) * 60;

      const c = colorPalette[Math.floor(Math.random() * colorPalette.length)];
      particleColors[i * 3] = c.r;
      particleColors[i * 3 + 1] = c.g;
      particleColors[i * 3 + 2] = c.b;
    }

    particleGeo.setAttribute('position', new THREE.BufferAttribute(particlePos, 3));
    particleGeo.setAttribute('color', new THREE.BufferAttribute(particleColors, 3));

    // Soft Circular Glow Texture for Starfield & Dust Sprites
    function createPointSpriteTexture() {
      const cv = document.createElement('canvas');
      cv.width = 64;
      cv.height = 64;
      const c = cv.getContext('2d');
      const g = c.createRadialGradient(32, 32, 0, 32, 32, 32);
      g.addColorStop(0.0, 'rgba(255, 255, 255, 1.0)');
      g.addColorStop(0.25, 'rgba(255, 255, 255, 0.75)');
      g.addColorStop(0.60, 'rgba(255, 255, 255, 0.2)');
      g.addColorStop(1.0, 'rgba(255, 255, 255, 0)');
      c.fillStyle = g;
      c.beginPath();
      c.arc(32, 32, 32, 0, Math.PI * 2);
      c.fill();
      return new THREE.CanvasTexture(cv);
    }
    const pointSpriteTexture = createPointSpriteTexture();

    const particleMat = new THREE.PointsMaterial({
      size: 0.28,
      map: pointSpriteTexture,
      vertexColors: true,
      transparent: true,
      opacity: 0.85,
      blending: THREE.AdditiveBlending,
      depthWrite: false
    });
    const starfield = new THREE.Points(particleGeo, particleMat);
    scene.add(starfield);

    // ═════════════════════════════════════════════════════════════
    // COSMIC SOLAR SYSTEM ENGINE (Background Celestial System)
    // ═════════════════════════════════════════════════════════════
    const solarSystemGroup = new THREE.Group();
    // Positioned in deep celestial background for panoramic framing behind typography
    solarSystemGroup.position.set(0, 3.2, -25);
    solarSystemGroup.rotation.x = 0.38;
    solarSystemGroup.rotation.y = -0.05;
    solarSystemGroup.rotation.z = 0.03;
    scene.add(solarSystemGroup);

    // --- PROCEDURAL PLANETARY TEXTURE GENERATORS ---

    // 1. Procedural Sun Texture (Granulation, Plasma Turbulence, Sunspots)
    function createSunTexture() {
      const cv = document.createElement('canvas');
      cv.width = 512;
      cv.height = 256;
      const c = cv.getContext('2d');

      const grad = c.createLinearGradient(0, 0, 512, 256);
      grad.addColorStop(0.0, '#fffbeb');
      grad.addColorStop(0.2, '#fef08a');
      grad.addColorStop(0.45, '#f59e0b');
      grad.addColorStop(0.75, '#ea580c');
      grad.addColorStop(1.0, '#991b1b');
      c.fillStyle = grad;
      c.fillRect(0, 0, 512, 256);

      // Convective granules and plasma filaments
      for (let i = 0; i < 140; i++) {
        const x = Math.random() * 512;
        const y = Math.random() * 256;
        const rad = 6 + Math.random() * 20;
        const g2 = c.createRadialGradient(x, y, 0, x, y, rad);
        g2.addColorStop(0, 'rgba(255, 255, 255, 0.4)');
        g2.addColorStop(0.5, 'rgba(254, 240, 138, 0.2)');
        g2.addColorStop(1, 'rgba(234, 88, 12, 0)');
        c.fillStyle = g2;
        c.beginPath();
        c.arc(x, y, rad, 0, Math.PI * 2);
        c.fill();
      }

      // Dark Sunspots with glowing penumbra
      for (let s = 0; s < 7; s++) {
        const sx = 60 + Math.random() * 390;
        const sy = 40 + Math.random() * 175;
        const sRad = 4 + Math.random() * 7;
        c.fillStyle = 'rgba(180, 83, 9, 0.65)';
        c.beginPath();
        c.arc(sx, sy, sRad * 1.8, 0, Math.PI * 2);
        c.fill();
        c.fillStyle = '#450a0a';
        c.beginPath();
        c.arc(sx, sy, sRad, 0, Math.PI * 2);
        c.fill();
      }
      return new THREE.CanvasTexture(cv);
    }

    // 2. Procedural Sun Rays & Coronal Streamers Texture
    function createSunRaysTexture() {
      const cv = document.createElement('canvas');
      cv.width = 512;
      cv.height = 512;
      const c = cv.getContext('2d');
      const cx = 256, cy = 256;

      const grad = c.createRadialGradient(cx, cy, 30, cx, cy, 250);
      grad.addColorStop(0.0, 'rgba(255, 237, 213, 0.95)');
      grad.addColorStop(0.25, 'rgba(251, 191, 36, 0.55)');
      grad.addColorStop(0.55, 'rgba(249, 115, 22, 0.22)');
      grad.addColorStop(0.85, 'rgba(220, 38, 38, 0.05)');
      grad.addColorStop(1.0, 'rgba(0, 0, 0, 0)');
      c.fillStyle = grad;
      c.beginPath();
      c.arc(cx, cy, 250, 0, Math.PI * 2);
      c.fill();

      // 12 Coronal Streamer Rays
      for (let r = 0; r < 12; r++) {
        const ang = (r / 12) * Math.PI * 2;
        const len = 150 + (r % 3) * 60;
        const w = (r % 2 === 0) ? 0.08 : 0.045;
        c.fillStyle = 'rgba(254, 240, 138, 0.22)';
        c.beginPath();
        c.moveTo(cx, cy);
        c.lineTo(cx + Math.cos(ang - w) * len, cy + Math.sin(ang - w) * len);
        c.lineTo(cx + Math.cos(ang + w) * len, cy + Math.sin(ang + w) * len);
        c.closePath();
        c.fill();
      }
      return new THREE.CanvasTexture(cv);
    }

    // 3. Mercury Cratered Texture
    function createMercuryTexture() {
      const cv = document.createElement('canvas');
      cv.width = 256;
      cv.height = 128;
      const c = cv.getContext('2d');
      c.fillStyle = '#78716c';
      c.fillRect(0, 0, 256, 128);

      for (let i = 0; i < 45; i++) {
        const x = Math.random() * 256;
        const y = Math.random() * 128;
        const r = 2 + Math.random() * 6;
        c.fillStyle = '#44403c';
        c.beginPath();
        c.arc(x, y, r, 0, Math.PI * 2);
        c.fill();
        c.strokeStyle = '#d6d3d1';
        c.lineWidth = 0.8;
        c.stroke();
      }
      return new THREE.CanvasTexture(cv);
    }

    // 4. Venus Atmosphere Texture
    function createVenusTexture() {
      const cv = document.createElement('canvas');
      cv.width = 256;
      cv.height = 128;
      const c = cv.getContext('2d');
      for (let y = 0; y < 128; y++) {
        const n = Math.sin(y * 0.12) * 0.5 + 0.5;
        const r = Math.round(235 + n * 20);
        const g = Math.round(185 + n * 40);
        const b = Math.round(85 + n * 35);
        c.fillStyle = `rgb(${r}, ${g}, ${b})`;
        c.fillRect(0, y, 256, 1);
      }
      for (let i = 0; i < 20; i++) {
        c.fillStyle = 'rgba(254, 240, 138, 0.2)';
        c.beginPath();
        c.ellipse(Math.random() * 256, Math.random() * 128, 40, 8, Math.PI * 0.1, 0, Math.PI * 2);
        c.fill();
      }
      return new THREE.CanvasTexture(cv);
    }

    // 5. Earth Surface & Clouds Textures
    function createEarthTexture() {
      const cv = document.createElement('canvas');
      cv.width = 512;
      cv.height = 256;
      const c = cv.getContext('2d');
      c.fillStyle = '#0369a1'; // Deep Blue Oceans
      c.fillRect(0, 0, 512, 256);

      // Continents
      c.fillStyle = '#15803d';
      c.beginPath();
      c.ellipse(120, 75, 45, 30, -0.2, 0, Math.PI * 2);
      c.fill();
      c.beginPath();
      c.ellipse(150, 165, 25, 45, 0.2, 0, Math.PI * 2);
      c.fill();
      c.beginPath();
      c.ellipse(320, 70, 70, 35, 0.1, 0, Math.PI * 2);
      c.fill();
      c.beginPath();
      c.ellipse(275, 140, 35, 45, 0, 0, Math.PI * 2);
      c.fill();
      c.beginPath();
      c.ellipse(410, 175, 25, 18, -0.1, 0, Math.PI * 2);
      c.fill();

      // Deserts
      c.fillStyle = '#ca8a04';
      c.beginPath();
      c.ellipse(270, 115, 28, 14, 0, 0, Math.PI * 2);
      c.fill();

      // Ice caps
      c.fillStyle = '#f8fafc';
      c.fillRect(0, 0, 512, 14);
      c.fillRect(0, 242, 512, 14);

      return new THREE.CanvasTexture(cv);
    }

    function createEarthCloudsTexture() {
      const cv = document.createElement('canvas');
      cv.width = 512;
      cv.height = 256;
      const c = cv.getContext('2d');
      c.clearRect(0, 0, 512, 256);

      c.fillStyle = 'rgba(255, 255, 255, 0.72)';
      for (let i = 0; i < 40; i++) {
        const x = Math.random() * 512;
        const y = 30 + Math.random() * 196;
        c.beginPath();
        c.ellipse(x, y, 35 + Math.random() * 45, 6 + Math.random() * 10, Math.sin(x * 0.05) * 0.3, 0, Math.PI * 2);
        c.fill();
      }
      return new THREE.CanvasTexture(cv);
    }

    // 6. Moon Texture
    function createMoonTexture() {
      const cv = document.createElement('canvas');
      cv.width = 128;
      cv.height = 64;
      const c = cv.getContext('2d');
      c.fillStyle = '#cbd5e1';
      c.fillRect(0, 0, 128, 64);
      c.fillStyle = '#475569';
      c.beginPath();
      c.arc(40, 25, 12, 0, Math.PI * 2);
      c.arc(75, 38, 16, 0, Math.PI * 2);
      c.fill();
      return new THREE.CanvasTexture(cv);
    }

    // 7. Mars Texture
    function createMarsTexture() {
      const cv = document.createElement('canvas');
      cv.width = 256;
      cv.height = 128;
      const c = cv.getContext('2d');
      c.fillStyle = '#c2410c'; // Rust Red
      c.fillRect(0, 0, 256, 128);

      // Dark volcanic highlands
      c.fillStyle = '#7c2d12';
      c.beginPath();
      c.ellipse(120, 64, 45, 22, -0.15, 0, Math.PI * 2);
      c.ellipse(200, 80, 28, 16, 0.2, 0, Math.PI * 2);
      c.fill();

      // White polar ice caps
      c.fillStyle = '#ffffff';
      c.fillRect(0, 0, 256, 7);
      c.fillRect(0, 121, 256, 7);

      return new THREE.CanvasTexture(cv);
    }

    // 8. Jupiter Banded Atmosphere with Great Red Spot
    function createJupiterTexture() {
      const cv = document.createElement('canvas');
      cv.width = 512;
      cv.height = 256;
      const c = cv.getContext('2d');

      const colors = ['#78350f', '#d97706', '#fef3c7', '#b45309', '#fde68a', '#9a3412', '#fef3c7', '#b45309'];
      for (let y = 0; y < 256; y++) {
        const band = Math.floor((y / 256) * colors.length);
        c.fillStyle = colors[band];
        c.fillRect(0, y, 512, 1);
      }

      // Turbulent cloud swirls
      for (let i = 0; i < 30; i++) {
        c.fillStyle = 'rgba(254, 243, 199, 0.35)';
        c.beginPath();
        c.ellipse(Math.random() * 512, Math.random() * 256, 45, 7, 0, 0, Math.PI * 2);
        c.fill();
      }

      // The Great Red Spot
      c.fillStyle = '#991b1b';
      c.beginPath();
      c.ellipse(360, 168, 38, 20, -0.08, 0, Math.PI * 2);
      c.fill();
      c.fillStyle = '#ea580c';
      c.beginPath();
      c.ellipse(360, 168, 22, 11, -0.08, 0, Math.PI * 2);
      c.fill();

      return new THREE.CanvasTexture(cv);
    }

    // 9. Saturn Ring Texture (Cassini Division, Multi-Ringlets)
    function createSaturnRingTexture() {
      const cv = document.createElement('canvas');
      cv.width = 512;
      cv.height = 16;
      const c = cv.getContext('2d');
      const grad = c.createLinearGradient(0, 0, 512, 0);
      grad.addColorStop(0.00, 'rgba(120, 53, 15, 0)');
      grad.addColorStop(0.12, 'rgba(217, 119, 6, 0.45)');   // C Ring
      grad.addColorStop(0.32, 'rgba(254, 240, 138, 0.88)');  // B Ring Inner
      grad.addColorStop(0.60, 'rgba(253, 230, 138, 0.98)');  // B Ring Bright
      grad.addColorStop(0.66, 'rgba(7, 9, 14, 0.08)');       // Cassini Division
      grad.addColorStop(0.72, 'rgba(254, 243, 199, 0.85)');  // A Ring
      grad.addColorStop(0.85, 'rgba(245, 158, 11, 0.75)');  // A Ring Outer
      grad.addColorStop(0.94, 'rgba(217, 119, 6, 0.35)');   // F Ring
      grad.addColorStop(1.00, 'rgba(120, 53, 15, 0)');
      c.fillStyle = grad;
      c.fillRect(0, 0, 512, 16);
      return new THREE.CanvasTexture(cv);
    }

    // 10. Uranus & Neptune Textures
    function createUranusTexture() {
      const cv = document.createElement('canvas');
      cv.width = 256;
      cv.height = 128;
      const c = cv.getContext('2d');
      const grad = c.createLinearGradient(0, 0, 0, 128);
      grad.addColorStop(0.0, '#a5f3fc');
      grad.addColorStop(0.5, '#67e8f9');
      grad.addColorStop(1.0, '#22d3ee');
      c.fillStyle = grad;
      c.fillRect(0, 0, 256, 128);
      return new THREE.CanvasTexture(cv);
    }

    function createNeptuneTexture() {
      const cv = document.createElement('canvas');
      cv.width = 256;
      cv.height = 128;
      const c = cv.getContext('2d');
      const grad = c.createLinearGradient(0, 0, 0, 128);
      grad.addColorStop(0.0, '#1e3a8a');
      grad.addColorStop(0.5, '#1d4ed8');
      grad.addColorStop(1.0, '#2563eb');
      c.fillStyle = grad;
      c.fillRect(0, 0, 256, 128);
      c.fillStyle = 'rgba(147, 197, 253, 0.4)';
      c.fillRect(40, 45, 120, 3);
      c.fillRect(110, 75, 90, 2);
      c.fillStyle = '#0f172a';
      c.beginPath();
      c.ellipse(180, 55, 16, 9, 0, 0, Math.PI * 2);
      c.fill();
      return new THREE.CanvasTexture(cv);
    }

    // --- CELESTIAL ASSETS & MESHES ---

    // 1. The Sun (Central Radiant Star)
    const sunGroup = new THREE.Group();
    const sunTexture = createSunTexture();
    const sunRaysTexture = createSunRaysTexture();

    // Balanced Sun Core (Radius 1.65, non-intrusive, majestic crown)
    const sunGeo = new THREE.SphereGeometry(1.65, 36, 36);
    const sunMat = new THREE.MeshBasicMaterial({
      map: sunTexture
    });
    const sunCore = new THREE.Mesh(sunGeo, sunMat);
    sunGroup.add(sunCore);

    // Glowing Inner Chromosphere
    const sunInnerHaloGeo = new THREE.SphereGeometry(1.95, 32, 32);
    const sunInnerHaloMat = new THREE.MeshBasicMaterial({
      color: 0xf59e0b,
      transparent: true,
      opacity: 0.42,
      blending: THREE.AdditiveBlending
    });
    const sunCorona = new THREE.Mesh(sunInnerHaloGeo, sunInnerHaloMat);
    sunGroup.add(sunCorona);

    // Outer Radiant Ray Corona (Billboard rotating plane)
    const sunRaysGeo = new THREE.PlaneGeometry(7.2, 7.2);
    const sunRaysMat = new THREE.MeshBasicMaterial({
      map: sunRaysTexture,
      transparent: true,
      opacity: 0.70,
      blending: THREE.AdditiveBlending,
      depthWrite: false,
      side: THREE.DoubleSide
    });
    const sunRays = new THREE.Mesh(sunRaysGeo, sunRaysMat);
    sunGroup.add(sunRays);

    // Warm Stellar Point Light
    const sunLight = new THREE.PointLight(0xfff5e6, 5.5, 120);
    sunGroup.add(sunLight);

    solarSystemGroup.add(sunGroup);

    // Helper: High-Tech Holographic Orbit Line
    function createOrbitPath(radius, color = 0x38bdf8, opacity = 0.16) {
      const segments = 180;
      const pts = [];
      for (let i = 0; i <= segments; i++) {
        const theta = (i / segments) * Math.PI * 2;
        pts.push(new THREE.Vector3(Math.cos(theta) * radius, 0, Math.sin(theta) * radius));
      }
      const geo = new THREE.BufferGeometry().setFromPoints(pts);
      const mat = new THREE.LineDashedMaterial({
        color: color,
        dashSize: 0.85,
        gapSize: 0.45,
        transparent: true,
        opacity: opacity,
        blending: THREE.AdditiveBlending
      });
      const line = new THREE.Line(geo, mat);
      line.computeLineDistances();
      return line;
    }

    // Planetary Cache
    const solarPlanets = [];

    // 1. Mercury (Speed: 0.75)
    const mercOrbit = 3.2;
    solarSystemGroup.add(createOrbitPath(mercOrbit, 0x94a3b8, 0.20));
    const mercMesh = new THREE.Mesh(
      new THREE.SphereGeometry(0.18, 24, 24),
      new THREE.MeshStandardMaterial({ map: createMercuryTexture(), roughness: 0.88, metalness: 0.15 })
    );
    solarSystemGroup.add(mercMesh);
    solarPlanets.push({ mesh: mercMesh, orbitRadius: mercOrbit, speed: 0.75, angle: Math.random() * Math.PI * 2, rotSpeed: 0.4 });

    // 2. Venus (Speed: 0.55)
    const venusOrbit = 4.6;
    solarSystemGroup.add(createOrbitPath(venusOrbit, 0xfde047, 0.20));
    const venusMesh = new THREE.Mesh(
      new THREE.SphereGeometry(0.28, 26, 26),
      new THREE.MeshStandardMaterial({ map: createVenusTexture(), roughness: 0.35, metalness: 0.1 })
    );
    solarSystemGroup.add(venusMesh);
    solarPlanets.push({ mesh: venusMesh, orbitRadius: venusOrbit, speed: 0.55, angle: Math.random() * Math.PI * 2, rotSpeed: 0.3 });

    // 3. Earth & Orbiting Moon (Speed: 0.40)
    const earthOrbit = 6.2;
    solarSystemGroup.add(createOrbitPath(earthOrbit, 0x38bdf8, 0.24));
    const earthGroup = new THREE.Group();

    // Earth Base Sphere
    const earthMesh = new THREE.Mesh(
      new THREE.SphereGeometry(0.35, 30, 30),
      new THREE.MeshStandardMaterial({ map: createEarthTexture(), roughness: 0.45, metalness: 0.15 })
    );
    earthGroup.add(earthMesh);

    // Earth Swirling Cloud Layer
    const earthCloudsMesh = new THREE.Mesh(
      new THREE.SphereGeometry(0.365, 28, 28),
      new THREE.MeshStandardMaterial({ map: createEarthCloudsTexture(), transparent: true, opacity: 0.55, roughness: 0.8 })
    );
    earthGroup.add(earthCloudsMesh);

    // Earth Atmosphere Rim Glow
    const earthAtmosphere = new THREE.Mesh(
      new THREE.SphereGeometry(0.385, 24, 24),
      new THREE.MeshBasicMaterial({ color: 0x38bdf8, transparent: true, opacity: 0.16, blending: THREE.AdditiveBlending, side: THREE.BackSide })
    );
    earthGroup.add(earthAtmosphere);

    // Earth's Moon
    const moonMesh = new THREE.Mesh(
      new THREE.SphereGeometry(0.10, 18, 18),
      new THREE.MeshStandardMaterial({ map: createMoonTexture(), roughness: 0.85 })
    );
    earthGroup.add(moonMesh);

    solarSystemGroup.add(earthGroup);
    solarPlanets.push({
      mesh: earthGroup,
      orbitRadius: earthOrbit,
      speed: 0.40,
      angle: Math.random() * Math.PI * 2,
      selfRotate: earthMesh,
      clouds: earthCloudsMesh,
      rotSpeed: 0.8,
      moonMesh: moonMesh,
      moonOrbit: 0.82,
      moonAngle: 0
    });

    // 4. Mars (Speed: 0.30)
    const marsOrbit = 7.8;
    solarSystemGroup.add(createOrbitPath(marsOrbit, 0xf87171, 0.20));
    const marsMesh = new THREE.Mesh(
      new THREE.SphereGeometry(0.24, 24, 24),
      new THREE.MeshStandardMaterial({ map: createMarsTexture(), roughness: 0.75 })
    );
    solarSystemGroup.add(marsMesh);
    solarPlanets.push({ mesh: marsMesh, orbitRadius: marsOrbit, speed: 0.30, angle: Math.random() * Math.PI * 2, rotSpeed: 0.7 });

    // 5. Main Asteroid Belt (Between Mars & Jupiter)
    const asteroidCount = 260;
    const asteroidGeo = new THREE.BufferGeometry();
    const asteroidPos = new Float32Array(asteroidCount * 3);
    const asteroidColors = new Float32Array(asteroidCount * 3);
    const astPalette = [new THREE.Color(0x94a3b8), new THREE.Color(0xa16207), new THREE.Color(0xcbd5e1), new THREE.Color(0x64748b)];

    for (let i = 0; i < asteroidCount; i++) {
      const aAng = Math.random() * Math.PI * 2;
      const aRad = 9.2 + (Math.random() - 0.5) * 1.5;
      asteroidPos[i * 3] = Math.cos(aAng) * aRad;
      asteroidPos[i * 3 + 1] = (Math.random() - 0.5) * 0.6;
      asteroidPos[i * 3 + 2] = Math.sin(aAng) * aRad;

      const col = astPalette[Math.floor(Math.random() * astPalette.length)];
      asteroidColors[i * 3] = col.r;
      asteroidColors[i * 3 + 1] = col.g;
      asteroidColors[i * 3 + 2] = col.b;
    }
    asteroidGeo.setAttribute('position', new THREE.BufferAttribute(asteroidPos, 3));
    asteroidGeo.setAttribute('color', new THREE.BufferAttribute(asteroidColors, 3));
    const asteroidBelt = new THREE.Points(
      asteroidGeo,
      new THREE.PointsMaterial({
        size: 0.22,
        map: pointSpriteTexture,
        vertexColors: true,
        transparent: true,
        opacity: 0.82,
        depthWrite: false
      })
    );
    solarSystemGroup.add(asteroidBelt);

    // 6. Jupiter with Banded Atmosphere & Great Red Spot (Speed: 0.18)
    const jupOrbit = 11.5;
    solarSystemGroup.add(createOrbitPath(jupOrbit, 0xfbbf24, 0.20));
    const jupMesh = new THREE.Mesh(
      new THREE.SphereGeometry(0.72, 34, 34),
      new THREE.MeshStandardMaterial({ map: createJupiterTexture(), roughness: 0.45, metalness: 0.1 })
    );
    solarSystemGroup.add(jupMesh);
    solarPlanets.push({ mesh: jupMesh, orbitRadius: jupOrbit, speed: 0.18, angle: Math.random() * Math.PI * 2, rotSpeed: 1.4 });

    // 7. Saturn & High-Fidelity Ring System (Speed: 0.12)
    const satOrbit = 14.0;
    solarSystemGroup.add(createOrbitPath(satOrbit, 0xfde68a, 0.20));
    const saturnGroup = new THREE.Group();
    const saturnSphere = new THREE.Mesh(
      new THREE.SphereGeometry(0.60, 32, 32),
      new THREE.MeshStandardMaterial({ color: 0xfde68a, roughness: 0.45, metalness: 0.15 })
    );
    saturnGroup.add(saturnSphere);

    // Multi-Ring Disk
    const satRingGeo = new THREE.RingGeometry(0.80, 1.70, 96);
    const satRingMat = new THREE.MeshStandardMaterial({
      map: createSaturnRingTexture(),
      side: THREE.DoubleSide,
      transparent: true,
      opacity: 0.94,
      roughness: 0.3
    });
    const satRing = new THREE.Mesh(satRingGeo, satRingMat);
    satRing.rotation.x = Math.PI * 0.42;
    saturnGroup.rotation.z = 0.35; // Axial Tilt
    saturnGroup.add(satRing);

    solarSystemGroup.add(saturnGroup);
    solarPlanets.push({ mesh: saturnGroup, orbitRadius: satOrbit, speed: 0.12, angle: Math.random() * Math.PI * 2, selfRotate: saturnSphere, rotSpeed: 1.2 });

    // 8. Uranus with Tilted Vertical Rings (Speed: 0.08)
    const uranOrbit = 16.5;
    solarSystemGroup.add(createOrbitPath(uranOrbit, 0x67e8f9, 0.18));
    const uranGroup = new THREE.Group();
    const uranSphere = new THREE.Mesh(
      new THREE.SphereGeometry(0.42, 28, 28),
      new THREE.MeshStandardMaterial({ map: createUranusTexture(), roughness: 0.3, metalness: 0.1 })
    );
    uranGroup.add(uranSphere);

    const uranRing = new THREE.Mesh(
      new THREE.RingGeometry(0.55, 0.82, 48),
      new THREE.MeshBasicMaterial({ color: 0xa5f3fc, side: THREE.DoubleSide, transparent: true, opacity: 0.45 })
    );
    uranRing.rotation.x = Math.PI * 0.48; // Extreme Axial Tilt (~85°)
    uranGroup.add(uranRing);
    solarSystemGroup.add(uranGroup);
    solarPlanets.push({ mesh: uranGroup, orbitRadius: uranOrbit, speed: 0.08, angle: Math.random() * Math.PI * 2, selfRotate: uranSphere, rotSpeed: 0.8 });

    // 9. Neptune with Methane Storms (Speed: 0.05)
    const nepOrbit = 19.0;
    solarSystemGroup.add(createOrbitPath(nepOrbit, 0x60a5fa, 0.16));
    const nepMesh = new THREE.Mesh(
      new THREE.SphereGeometry(0.40, 28, 28),
      new THREE.MeshStandardMaterial({ map: createNeptuneTexture(), roughness: 0.3, metalness: 0.15 })
    );
    solarSystemGroup.add(nepMesh);
    solarPlanets.push({ mesh: nepMesh, orbitRadius: nepOrbit, speed: 0.05, angle: Math.random() * Math.PI * 2, rotSpeed: 0.8 });

    // --- 3D Modular Assembly Core ---
    const mainGroup = new THREE.Group();
    mainGroup.position.set(0, 0.9, 0);
    scene.add(mainGroup);

    const modularParts = [];

    function registerPart(mesh, assembledPos, assembledRot, explodedPos, explodedRot, scale = 1) {
      mesh.position.copy(explodedPos);
      mesh.rotation.copy(explodedRot);
      mesh.scale.set(scale, scale, scale);
      mainGroup.add(mesh);

      const partData = {
        mesh,
        assembledPos: assembledPos.clone(),
        assembledRot: assembledRot.clone(),
        explodedPos: explodedPos.clone(),
        explodedRot: explodedRot.clone()
      };
      modularParts.push(partData);
    }

    // Material Library
    const mats = {
      carbonDark: new THREE.MeshStandardMaterial({
        color: 0x0f172a,
        roughness: 0.35,
        metalness: 0.92
      }),
      titaniumBody: new THREE.MeshStandardMaterial({
        color: 0x1e293b,
        roughness: 0.2,
        metalness: 0.95
      }),
      neonCyan: new THREE.MeshStandardMaterial({
        color: 0x00f2fe,
        emissive: 0x00c8d4,
        emissiveIntensity: 0.85,
        roughness: 0.15,
        metalness: 0.8
      }),
      neonPurple: new THREE.MeshStandardMaterial({
        color: 0xa855f7,
        emissive: 0x7e22ce,
        emissiveIntensity: 0.8,
        roughness: 0.18,
        metalness: 0.85
      }),
      neonEmerald: new THREE.MeshStandardMaterial({
        color: 0x10b981,
        emissive: 0x059669,
        emissiveIntensity: 0.8,
        roughness: 0.2,
        metalness: 0.8
      }),
      glassCyan: new THREE.MeshPhysicalMaterial({
        color: 0x0284c7,
        transparent: true,
        opacity: 0.85,
        roughness: 0.1,
        metalness: 0.15,
        transmission: 0.78,
        ior: 1.52,
        clearcoat: 1.0,
        clearcoatRoughness: 0.08
      }),
      glassEmerald: new THREE.MeshPhysicalMaterial({
        color: 0x059669,
        transparent: true,
        opacity: 0.85,
        roughness: 0.1,
        metalness: 0.15,
        transmission: 0.8,
        ior: 1.5,
        clearcoat: 1.0
      }),
      chromeMetal: new THREE.MeshStandardMaterial({
        color: 0xe2e8f0,
        roughness: 0.1,
        metalness: 0.98
      }),
      goldAccent: new THREE.MeshStandardMaterial({
        color: 0xf59e0b,
        emissive: 0xb45309,
        emissiveIntensity: 0.45,
        roughness: 0.15,
        metalness: 0.95
      })
    };

    // ─────────────────────────────────────────────────────────────
    // TEXTURE GENERATORS (512x512 High-Definition Textures)
    // ─────────────────────────────────────────────────────────────

    // 1. Procedural Spherical Planet Grid & Circuit Texture
    function createPlanetCircuitTexture() {
      const cv = document.createElement('canvas');
      cv.width = 512;
      cv.height = 256;
      const c = cv.getContext('2d');

      c.fillStyle = '#061325';
      c.fillRect(0, 0, 512, 256);

      // Latitudes & Longitudes
      c.strokeStyle = 'rgba(0, 242, 254, 0.18)';
      c.lineWidth = 1.5;
      for (let y = 32; y < 256; y += 32) {
        c.beginPath();
        c.moveTo(0, y);
        c.lineTo(512, y);
        c.stroke();
      }
      for (let x = 64; x < 512; x += 64) {
        c.beginPath();
        c.moveTo(x, 0);
        c.lineTo(x, 256);
        c.stroke();
      }

      // Tech Markings
      c.fillStyle = '#00f2fe';
      c.font = 'bold 16px monospace';
      c.fillText('LUAU COMPILER // JIT VM v2', 40, 120);
      c.fillText('FASTCALL :: SIMD INTRINSICS', 40, 145);
      c.fillText('STRICT TYPE SOLVER 100%', 290, 120);
      c.fillText('ATOMIC BINDING RUNTIME', 290, 145);

      // Circuit Dots
      c.fillStyle = '#a855f7';
      for (let i = 0; i < 20; i++) {
        const cx = Math.random() * 512;
        const cy = Math.random() * 256;
        c.beginPath();
        c.arc(cx, cy, 3, 0, Math.PI * 2);
        c.fill();
      }

      return new THREE.CanvasTexture(cv);
    }

    const planetTex = createPlanetCircuitTexture();
    const planetMat = new THREE.MeshPhysicalMaterial({
      map: planetTex,
      color: 0x0284c7,
      transparent: true,
      opacity: 0.88,
      transmission: 0.72,
      roughness: 0.12,
      metalness: 0.2,
      ior: 1.5,
      clearcoat: 1.0
    });

    // 2. High-Res Roblox Script Face Textures
    function createRobloxScriptTexture(mode) {
      const cv = document.createElement('canvas');
      cv.width = 512;
      cv.height = 512;
      const c = cv.getContext('2d');

      // Studio IDE Background
      c.fillStyle = '#090d16';
      c.fillRect(0, 0, 512, 512);

      // Outer Bevel Rim
      const rimColor = mode === 'server' ? '#00f2fe' : mode === 'module' ? '#a855f7' : '#10b981';
      c.strokeStyle = rimColor;
      c.lineWidth = 8;
      c.strokeRect(4, 4, 504, 504);

      // Title Bar
      c.fillStyle = '#111827';
      c.fillRect(8, 8, 496, 68);

      // Window Dots
      c.fillStyle = '#ef4444';
      c.beginPath(); c.arc(32, 42, 7, 0, Math.PI * 2); c.fill();
      c.fillStyle = '#f59e0b';
      c.beginPath(); c.arc(54, 42, 7, 0, Math.PI * 2); c.fill();
      c.fillStyle = '#10b981';
      c.beginPath(); c.arc(76, 42, 7, 0, Math.PI * 2); c.fill();

      // Title Text
      c.fillStyle = '#ffffff';
      c.font = 'bold 22px monospace';
      c.textAlign = 'left';
      const title = mode === 'server' ? 'ServerScript // NetworkBridge.luau' :
                    mode === 'module' ? 'ModuleScript // StateMachine.luau' :
                                        'ActorWorker // ParallelEngine.luau';
      c.fillText(title, 105, 48);

      // Code Lines
      c.font = '19px monospace';
      let lines = [];
      if (mode === 'server') {
        lines = [
          { num: '01', color: '#64748b', text: '--!strict' },
          { num: '02', color: '#38bdf8', text: 'local Players = game:GetService("Players")' },
          { num: '03', color: '#38bdf8', text: 'local RunService = game:GetService("RunService")' },
          { num: '04', color: '#64748b', text: '' },
          { num: '05', color: '#a855f7', text: 'export type Packet<T> = {' },
          { num: '06', color: '#f59e0b', text: '    id: string,' },
          { num: '07', color: '#f59e0b', text: '    payload: T,' },
          { num: '08', color: '#f59e0b', text: '    timestamp: number' },
          { num: '09', color: '#a855f7', text: '}' },
          { num: '10', color: '#38bdf8', text: 'function Net.send(player, pkt)' },
          { num: '11', color: '#10b981', text: '    assert(player, "Invalid target")' },
          { num: '12', color: '#38bdf8', text: 'end' }
        ];
      } else if (mode === 'module') {
        lines = [
          { num: '01', color: '#64748b', text: '--!strict' },
          { num: '02', color: '#a855f7', text: 'local StateMachine = {}' },
          { num: '03', color: '#a855f7', text: 'StateMachine.__index = StateMachine' },
          { num: '04', color: '#64748b', text: '' },
          { num: '05', color: '#38bdf8', text: 'function StateMachine.new<S>(init: S)' },
          { num: '06', color: '#f59e0b', text: '    local self = setmetatable({}, StateMachine)' },
          { num: '07', color: '#f59e0b', text: '    self.state = init' },
          { num: '08', color: '#38bdf8', text: '    return self' },
          { num: '09', color: '#38bdf8', text: 'end' },
          { num: '10', color: '#64748b', text: '' },
          { num: '11', color: '#00f2fe', text: 'return StateMachine' }
        ];
      } else {
        lines = [
          { num: '01', color: '#64748b', text: '--!native' },
          { num: '02', color: '#10b981', text: 'task.desynchronize() -- Parallel Worker' },
          { num: '03', color: '#38bdf8', text: 'local buf = buffer.create(1024)' },
          { num: '04', color: '#f59e0b', text: 'buffer.writef32(buf, 0, 3.14159)' },
          { num: '05', color: '#f59e0b', text: 'buffer.writeu32(buf, 4, 0xCAFEBABE)' },
          { num: '06', color: '#64748b', text: '' },
          { num: '07', color: '#10b981', text: 'task.synchronize() -- Main Thread Snap' },
          { num: '08', color: '#38bdf8', text: 'return buffer.tostring(buf)' }
        ];
      }

      let yPos = 118;
      lines.forEach((l) => {
        c.fillStyle = '#475569';
        c.fillText(l.num, 24, yPos);
        c.fillStyle = l.color;
        c.fillText(l.text, 65, yPos);
        yPos += 32;
      });

      return new THREE.CanvasTexture(cv);
    }

    const scriptTexServer = createRobloxScriptTexture('server');
    const scriptTexModule = createRobloxScriptTexture('module');
    const scriptTexActor = createRobloxScriptTexture('actor');

    const scriptMatServer = new THREE.MeshStandardMaterial({ map: scriptTexServer, roughness: 0.25, metalness: 0.7 });
    const scriptMatModule = new THREE.MeshStandardMaterial({ map: scriptTexModule, roughness: 0.25, metalness: 0.7 });
    const scriptMatActor = new THREE.MeshStandardMaterial({ map: scriptTexActor, roughness: 0.25, metalness: 0.7 });

    // ─────────────────────────────────────────────────────────────
    // 1. MASTER 3D LUAU CELESTIAL EMBLEM
    // ─────────────────────────────────────────────────────────────

    // A: Inner Luminous Nucleus Sphere
    const nucleusGeo = new THREE.SphereGeometry(0.72, 32, 32);
    const nucleus = new THREE.Mesh(nucleusGeo, mats.neonCyan);
    registerPart(
      nucleus,
      new THREE.Vector3(0, 0, 0),
      new THREE.Euler(0, 0, 0),
      new THREE.Vector3(0, 3.4, -4.5),
      new THREE.Euler(1.1, 0.6, 0)
    );

    // B: Inner Geometric Quantum Icosahedron Lattice
    const latticeGeo = new THREE.IcosahedronGeometry(0.9, 1);
    const latticeMat = new THREE.MeshBasicMaterial({
      color: 0x38bdf8,
      wireframe: true,
      transparent: true,
      opacity: 0.65
    });
    const quantumLattice = new THREE.Mesh(latticeGeo, latticeMat);
    nucleus.add(quantumLattice);

    // C: Outer Optical Glass Mantle Sphere (With Circuit Map)
    const mantleGeo = new THREE.SphereGeometry(1.12, 48, 48);
    const mantle = new THREE.Mesh(mantleGeo, planetMat);
    registerPart(
      mantle,
      new THREE.Vector3(0, 0, 0),
      new THREE.Euler(0, 0, 0),
      new THREE.Vector3(0, -3.2, -4.0),
      new THREE.Euler(-0.8, 0.5, 0.2)
    );

    // D: Equatorial Compiler Ring Band
    const bandGeo = new THREE.CylinderGeometry(1.22, 1.22, 0.1, 48, 1, true);
    const band = new THREE.Mesh(bandGeo, mats.titaniumBody);
    registerPart(
      band,
      new THREE.Vector3(0, 0, 0),
      new THREE.Euler(0, 0, 0),
      new THREE.Vector3(3.5, 2.5, -4.5),
      new THREE.Euler(0.4, 0.8, -0.6)
    );

    // E: SCULPTED 3D CRESCENT MOON ARC (Parametric Tapered Geometry)
    function createCrescentGeometry(outerR, taperDepth, arcSpread) {
      const shape = new THREE.Shape();
      const steps = 40;

      // Outer perimeter
      for (let i = 0; i <= steps; i++) {
        const t = i / steps;
        const theta = -arcSpread + t * (2 * arcSpread);
        const x = Math.cos(theta) * outerR;
        const y = Math.sin(theta) * outerR;
        if (i === 0) shape.moveTo(x, y);
        else shape.lineTo(x, y);
      }

      // Inner perimeter returning with smooth taper
      for (let i = steps; i >= 0; i--) {
        const t = i / steps;
        const theta = -arcSpread + t * (2 * arcSpread);
        const taper = Math.sin(t * Math.PI);
        const r = outerR - taper * taperDepth;
        const x = Math.cos(theta) * r;
        const y = Math.sin(theta) * r;
        shape.lineTo(x, y);
      }
      shape.closePath();

      const extrudeSettings = {
        steps: 1,
        depth: 0.28,
        bevelEnabled: true,
        bevelThickness: 0.05,
        bevelSize: 0.05,
        bevelSegments: 4
      };
      return new THREE.ExtrudeGeometry(shape, extrudeSettings);
    }

    const crescentGeo = createCrescentGeometry(1.95, 0.62, Math.PI * 0.76);
    crescentGeo.center();
    const crescentMoon = new THREE.Mesh(crescentGeo, mats.titaniumBody);

    // Glowing Neon Edge Ribbon on Crescent
    const crescentRimGeo = createCrescentGeometry(2.02, 0.18, Math.PI * 0.77);
    crescentRimGeo.center();
    const crescentRim = new THREE.Mesh(crescentRimGeo, mats.neonCyan);
    crescentRim.scale.set(1.01, 1.01, 0.6);
    crescentMoon.add(crescentRim);

    registerPart(
      crescentMoon,
      new THREE.Vector3(0, 0, 0),
      new THREE.Euler(0, 0, Math.PI * 0.22),
      new THREE.Vector3(-5.2, 4.5, 3.2),
      new THREE.Euler(-0.7, 1.1, 0.4)
    );

    // F: POLISHED GOLD CELESTIAL SATELLITE MOON & DUAL GIMBAL RINGS
    const satelliteGroup = new THREE.Group();
    const satSphereGeo = new THREE.SphereGeometry(0.38, 28, 28);
    const satSphere = new THREE.Mesh(satSphereGeo, mats.goldAccent);
    satelliteGroup.add(satSphere);

    // Gimbal Ring 1 & 2
    const gim1Geo = new THREE.TorusGeometry(0.52, 0.02, 16, 48);
    const gim1 = new THREE.Mesh(gim1Geo, mats.goldAccent);
    satelliteGroup.add(gim1);

    const gim2Geo = new THREE.TorusGeometry(0.58, 0.018, 16, 48);
    const gim2 = new THREE.Mesh(gim2Geo, mats.neonCyan);
    gim2.rotation.x = Math.PI / 2;
    satelliteGroup.add(gim2);

    registerPart(
      satelliteGroup,
      new THREE.Vector3(1.8, 1.4, 0.2),
      new THREE.Euler(0, 0, 0),
      new THREE.Vector3(6.5, 4.8, -3.5),
      new THREE.Euler(0.5, -0.9, 0.6)
    );

    // G: Elliptical Satellite Orbit Track Ring
    const orbitTrackGeo = new THREE.TorusGeometry(2.35, 0.015, 16, 120);
    const orbitTrackMat = new THREE.MeshBasicMaterial({
      color: 0x00f2fe,
      transparent: true,
      opacity: 0.35
    });
    const orbitTrack = new THREE.Mesh(orbitTrackGeo, orbitTrackMat);
    orbitTrack.rotation.x = Math.PI * 0.35;
    orbitTrack.rotation.y = Math.PI * 0.15;
    registerPart(
      orbitTrack,
      new THREE.Vector3(0, 0, 0),
      orbitTrack.rotation.clone(),
      new THREE.Vector3(4.8, -3.8, 3.5),
      new THREE.Euler(1.2, -0.4, 0.8)
    );

    // H: Concentric Outer Segmented Cyber Rings
    const ring1Geo = new THREE.TorusGeometry(2.65, 0.045, 16, 80);
    const ring1 = new THREE.Mesh(ring1Geo, mats.neonCyan);
    registerPart(
      ring1,
      new THREE.Vector3(0, 0, 0),
      new THREE.Euler(Math.PI / 4, 0, 0),
      new THREE.Vector3(0, -5.5, 4.2),
      new THREE.Euler(1.3, -0.6, 0)
    );

    const ring2Geo = new THREE.TorusGeometry(3.1, 0.04, 16, 80);
    const ring2 = new THREE.Mesh(ring2Geo, mats.neonPurple);
    registerPart(
      ring2,
      new THREE.Vector3(0, 0, 0),
      new THREE.Euler(0, Math.PI / 3, Math.PI / 6),
      new THREE.Vector3(4.5, -5.2, -4.0),
      new THREE.Euler(-1.0, 0.8, 1.2)
    );

    // ─────────────────────────────────────────────────────────────
    // 2. SCULPTED 3D TYPE SOLVER TOKENS (< T > AND { })
    // ─────────────────────────────────────────────────────────────

    // A: Parametric Beveled Curly Braces { and }
    function createBracketGeometry(flip = false) {
      const sign = flip ? -1 : 1;
      const pts = [
        new THREE.Vector2(0.38 * sign, 1.25),
        new THREE.Vector2(0.18 * sign, 1.20),
        new THREE.Vector2(0.02 * sign, 0.95),
        new THREE.Vector2(-0.04 * sign, 0.65),
        new THREE.Vector2(-0.04 * sign, 0.28),
        new THREE.Vector2(-0.28 * sign, 0.0), // central cusp
        new THREE.Vector2(-0.04 * sign, -0.28),
        new THREE.Vector2(-0.04 * sign, -0.65),
        new THREE.Vector2(0.02 * sign, -0.95),
        new THREE.Vector2(0.18 * sign, -1.20),
        new THREE.Vector2(0.38 * sign, -1.25),
        // inner contour returning
        new THREE.Vector2(0.26 * sign, -1.08),
        new THREE.Vector2(0.12 * sign, -0.85),
        new THREE.Vector2(0.06 * sign, -0.55),
        new THREE.Vector2(0.06 * sign, -0.20),
        new THREE.Vector2(-0.16 * sign, 0.0),
        new THREE.Vector2(0.06 * sign, 0.20),
        new THREE.Vector2(0.06 * sign, 0.55),
        new THREE.Vector2(0.12 * sign, 0.85),
        new THREE.Vector2(0.26 * sign, 1.08)
      ];
      const shape = new THREE.Shape(pts);
      const extrudeSettings = {
        steps: 1,
        depth: 0.16,
        bevelEnabled: true,
        bevelThickness: 0.03,
        bevelSize: 0.03,
        bevelSegments: 3
      };
      const geo = new THREE.ExtrudeGeometry(shape, extrudeSettings);
      geo.center();
      return geo;
    }

    const bracketLGeo = createBracketGeometry(false);
    const bracketL = new THREE.Mesh(bracketLGeo, mats.glassCyan);
    registerPart(
      bracketL,
      new THREE.Vector3(-2.2, -0.9, 0.4),
      new THREE.Euler(0, 0.25, 0),
      new THREE.Vector3(-7.2, -4.8, 3.8),
      new THREE.Euler(0.8, 0.4, 0.9)
    );

    const bracketRGeo = createBracketGeometry(true);
    const bracketR = new THREE.Mesh(bracketRGeo, mats.glassCyan);
    registerPart(
      bracketR,
      new THREE.Vector3(2.2, -0.9, 0.4),
      new THREE.Euler(0, -0.25, 0),
      new THREE.Vector3(7.2, -4.5, 4.0),
      new THREE.Euler(-0.7, -0.5, -0.8)
    );

    // B: Chamfered Type Chevrons < and >
    function createChevronToken(flip = false) {
      const group = new THREE.Group();
      const armGeo = new THREE.BoxGeometry(0.2, 1.1, 0.2);

      const topArm = new THREE.Mesh(armGeo, mats.neonCyan);
      topArm.position.set(flip ? 0.32 : -0.32, 0.35, 0);
      topArm.rotation.z = flip ? Math.PI / 4 : -Math.PI / 4;
      group.add(topArm);

      const btmArm = new THREE.Mesh(armGeo, mats.neonCyan);
      btmArm.position.set(flip ? 0.32 : -0.32, -0.35, 0);
      btmArm.rotation.z = flip ? -Math.PI / 4 : Math.PI / 4;
      group.add(btmArm);

      // Outer metallic armor casing
      const armorGeo = new THREE.BoxGeometry(0.24, 1.15, 0.12);
      const topArmor = new THREE.Mesh(armorGeo, mats.titaniumBody);
      topArmor.position.copy(topArm.position);
      topArmor.position.z -= 0.08;
      topArmor.rotation.copy(topArm.rotation);
      group.add(topArmor);

      return group;
    }

    const chevL = createChevronToken(false);
    registerPart(
      chevL,
      new THREE.Vector3(-2.5, 0.2, 0.6),
      new THREE.Euler(0, 0.2, 0),
      new THREE.Vector3(-8.5, 3.2, 5.0),
      new THREE.Euler(0.7, -0.9, 0.4)
    );

    const chevR = createChevronToken(true);
    registerPart(
      chevR,
      new THREE.Vector3(2.5, 0.2, 0.6),
      new THREE.Euler(0, -0.2, 0),
      new THREE.Vector3(8.5, 3.5, 4.8),
      new THREE.Euler(-0.6, 1.0, -0.3)
    );

    // C: Beveled Chrome "T" Glyph
    const tGroup = new THREE.Group();
    const tBarH = new THREE.Mesh(new THREE.BoxGeometry(1.0, 0.22, 0.22), mats.chromeMetal);
    tBarH.position.y = 0.52;
    tGroup.add(tBarH);
    const tBarV = new THREE.Mesh(new THREE.BoxGeometry(0.24, 1.1, 0.22), mats.chromeMetal);
    tBarV.position.y = 0;
    tGroup.add(tBarV);
    registerPart(
      tGroup,
      new THREE.Vector3(0, 1.5, 0.7),
      new THREE.Euler(0, 0, 0),
      new THREE.Vector3(0, 7.2, 6.0),
      new THREE.Euler(1.2, 0.4, -0.5)
    );

    // ─────────────────────────────────────────────────────────────
    // 3. AUTHENTIC 3D ROBLOX SCRIPT BRICKS WITH CYLINDRICAL STUDS
    // ─────────────────────────────────────────────────────────────
    function createRobloxScriptBrick(faceMat, studMat, titleText) {
      const brickGroup = new THREE.Group();
      const bodyGeo = new THREE.BoxGeometry(1.5, 1.3, 0.4);

      // Create multi-material box so the front face displays high-res code
      const materials = [
        mats.carbonDark,    // right
        mats.carbonDark,    // left
        mats.carbonDark,    // top
        mats.carbonDark,    // bottom
        faceMat,            // front (+Z)
        mats.carbonDark     // back (-Z)
      ];
      const body = new THREE.Mesh(bodyGeo, materials);
      brickGroup.add(body);

      // 4 Authentic Cylindrical Roblox Studs on Top Face
      const studGeo = new THREE.CylinderGeometry(0.16, 0.16, 0.12, 18);
      const studPositions = [-0.48, -0.16, 0.16, 0.48];
      studPositions.forEach((posX) => {
        const stud = new THREE.Mesh(studGeo, studMat);
        stud.position.set(posX, 0.65 + 0.06, 0);
        brickGroup.add(stud);

        // Top inset stud ring
        const studRingGeo = new THREE.RingGeometry(0.06, 0.14, 16);
        const studRing = new THREE.Mesh(studRingGeo, mats.chromeMetal);
        studRing.rotation.x = -Math.PI / 2;
        studRing.position.set(posX, 0.65 + 0.125, 0);
        brickGroup.add(studRing);
      });

      return brickGroup;
    }

    // ServerScript Brick (Left Wing)
    const serverScriptBrick = createRobloxScriptBrick(scriptMatServer, mats.neonCyan, 'ServerScript');
    registerPart(
      serverScriptBrick,
      new THREE.Vector3(-2.6, 1.3, -0.9),
      new THREE.Euler(0, 0.35, 0.1),
      new THREE.Vector3(-9.2, 6.2, -5.2),
      new THREE.Euler(1.5, -0.9, 0.3)
    );

    // ModuleScript Brick (Right Wing)
    const moduleScriptBrick = createRobloxScriptBrick(scriptMatModule, mats.neonPurple, 'ModuleScript');
    registerPart(
      moduleScriptBrick,
      new THREE.Vector3(2.6, 1.3, -0.9),
      new THREE.Euler(0, -0.35, -0.1),
      new THREE.Vector3(9.5, 6.0, -5.5),
      new THREE.Euler(-1.3, 1.2, -0.4)
    );

    // Parallel Actor / Worker Brick (Upper Center Rear)
    const actorScriptBrick = createRobloxScriptBrick(scriptMatActor, mats.neonEmerald, 'ActorWorker');
    registerPart(
      actorScriptBrick,
      new THREE.Vector3(0, 2.4, -1.2),
      new THREE.Euler(-0.25, 0, 0),
      new THREE.Vector3(0, 9.5, -6.5),
      new THREE.Euler(1.8, 0, 0)
    );

    // ─────────────────────────────────────────────────────────────
    // 4. LOW-LEVEL VM MEMORY BUFFERS & 3D VECTOR3 RGB GIZMO
    // ─────────────────────────────────────────────────────────────

    // 6 Hexagonal Prism Memory Buffer Cells
    const hexGeo = new THREE.CylinderGeometry(0.44, 0.44, 0.65, 6);
    for (let i = 0; i < 6; i++) {
      const angle = (i / 6) * Math.PI * 2;
      const isCyan = i % 2 === 0;
      const hexMesh = new THREE.Mesh(hexGeo, isCyan ? mats.glassCyan : mats.glassEmerald);

      // Inner glowing core cylinder
      const innerHexCore = new THREE.Mesh(
        new THREE.CylinderGeometry(0.25, 0.25, 0.67, 6),
        isCyan ? mats.neonCyan : mats.neonEmerald
      );
      hexMesh.add(innerHexCore);

      const assemP = new THREE.Vector3(Math.cos(angle) * 2.6, Math.sin(angle) * 1.5 - 0.2, -1.4);
      const assemR = new THREE.Euler(0.2, angle, 0.2);

      const expP = new THREE.Vector3(
        Math.cos(angle) * 10.5 + (Math.random() - 0.5) * 3,
        Math.sin(angle) * 8.0 + (Math.random() - 0.5) * 3,
        (Math.random() - 0.5) * 8
      );
      const expR = new THREE.Euler(Math.random() * 3, Math.random() * 3, Math.random() * 3);
      registerPart(hexMesh, assemP, assemR, expP, expR, 0.72);
    }

    // 3D Vector3 Coordinate Axes Gizmo (Lower Base)
    const gizmoGroup = new THREE.Group();
    const axisPivotGeo = new THREE.SphereGeometry(0.24, 20, 20);
    const axisPivot = new THREE.Mesh(axisPivotGeo, mats.chromeMetal);
    gizmoGroup.add(axisPivot);

    function createAxisRod(dir, colorHex) {
      const rodGroup = new THREE.Group();
      const shaft = new THREE.Mesh(
        new THREE.CylinderGeometry(0.04, 0.04, 0.8, 16),
        new THREE.MeshStandardMaterial({ color: colorHex, emissive: colorHex, emissiveIntensity: 0.6 })
      );
      shaft.position.y = 0.4;
      rodGroup.add(shaft);

      const tip = new THREE.Mesh(
        new THREE.ConeGeometry(0.09, 0.22, 16),
        new THREE.MeshStandardMaterial({ color: colorHex, emissive: colorHex, emissiveIntensity: 0.8 })
      );
      tip.position.y = 0.88;
      rodGroup.add(tip);

      if (dir === 'x') {
        rodGroup.rotation.z = -Math.PI / 2;
      } else if (dir === 'z') {
        rodGroup.rotation.x = Math.PI / 2;
      }
      return rodGroup;
    }

    gizmoGroup.add(createAxisRod('x', 0xef4444)); // X = Red
    gizmoGroup.add(createAxisRod('y', 0x10b981)); // Y = Green
    gizmoGroup.add(createAxisRod('z', 0x3b82f6)); // Z = Blue

    registerPart(
      gizmoGroup,
      new THREE.Vector3(0, -1.2, 0.8),
      new THREE.Euler(0.2, 0.4, 0),
      new THREE.Vector3(0, -6.5, 4.5),
      new THREE.Euler(-0.8, 1.2, 0)
    );

    // Architectural Base Plate
    const basePlateGeo = new THREE.BoxGeometry(4.8, 0.38, 2.2);
    const basePlate = new THREE.Mesh(basePlateGeo, mats.carbonDark);
    registerPart(
      basePlate,
      new THREE.Vector3(0, -2.1, 0),
      new THREE.Euler(0, 0, 0),
      new THREE.Vector3(0, -8.2, -6.0),
      new THREE.Euler(0.6, 0, 0.2)
    );

    // ─────────────────────────────────────────────────────────────
    // 5. 150+ CRYSTALLINE & CARBON SHARDS
    // ─────────────────────────────────────────────────────────────
    const shardGeos = [
      new THREE.OctahedronGeometry(0.32, 0),
      new THREE.TetrahedronGeometry(0.34, 0),
      new THREE.BoxGeometry(0.48, 0.16, 0.85),
      new THREE.ConeGeometry(0.26, 0.75, 4)
    ];

    const shardMaterials = [
      mats.titaniumBody,
      mats.neonCyan,
      mats.chromeMetal,
      mats.neonPurple,
      mats.glassCyan
    ];

    const totalShards = 150;
    for (let i = 0; i < totalShards; i++) {
      const geo = shardGeos[i % shardGeos.length];
      const mat = shardMaterials[i % shardMaterials.length];
      const shardMesh = new THREE.Mesh(geo, mat);

      const theta = Math.random() * Math.PI * 2;
      const phi = (Math.random() - 0.5) * Math.PI;
      const radius = 1.9 + Math.random() * 1.6;

      const assemPos = new THREE.Vector3(
        radius * Math.cos(phi) * Math.cos(theta),
        radius * Math.sin(phi),
        radius * Math.cos(phi) * Math.sin(theta)
      );
      const assemRot = new THREE.Euler(Math.random() * Math.PI, Math.random() * Math.PI, 0);

      const expDist = 8.5 + Math.random() * 9.5;
      const expPos = new THREE.Vector3(
        assemPos.x * (expDist / radius) + (Math.random() - 0.5) * 4.5,
        assemPos.y * (expDist / radius) + (Math.random() - 0.5) * 4.5,
        assemPos.z * (expDist / radius) + (Math.random() - 0.5) * 4.5
      );
      const expRot = new THREE.Euler(Math.random() * 6, Math.random() * 6, Math.random() * 6);

      registerPart(shardMesh, assemPos, assemRot, expPos, expRot, 0.35 + Math.random() * 0.65);
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

    // Camera Spline (Balanced focal framing across stages)
    const cameraWaypoints = [
      { pos: new THREE.Vector3(0, 2.2, 17.5), lookAt: new THREE.Vector3(0, 0.8, 0) },
      { pos: new THREE.Vector3(-3.2, 1.4, 9.8), lookAt: new THREE.Vector3(-1.2, 0.6, 0) },
      { pos: new THREE.Vector3(3.6, 2.2, 9.2), lookAt: new THREE.Vector3(1.0, 0.5, -0.4) },
      { pos: new THREE.Vector3(0, 3.8, 11.5), lookAt: new THREE.Vector3(0, 0.4, 0) },
      { pos: new THREE.Vector3(-2.2, 1.8, 13.5), lookAt: new THREE.Vector3(0, 0.8, 0) },
      { pos: new THREE.Vector3(0, 1.5, 12.0), lookAt: new THREE.Vector3(0, 0.8, 0) }
    ];

    function getInterpolatedCamera(t) {
      const safeT = (isNaN(t) || t < 0) ? 0 : (t > 1 ? 1 : t);
      const segCount = cameraWaypoints.length - 1;
      const scaled = safeT * segCount;
      const idx = Math.min(Math.max(0, Math.floor(scaled)), segCount - 1);
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
    // 7. HUD SYNCHRONIZATION (Silent, Pure Visual Telemetry)
    // ─────────────────────────────────────────────────────────────
    const speedEl = document.getElementById('f1SpeedVal');
    const stageValEl = document.getElementById('f1StageVal');
    const progressFillEl = document.getElementById('f1ProgressFill');
    const ledBars = document.querySelectorAll('.led-segment');
    const stageCards = document.querySelectorAll('.luau-stage-card');
    const tickerAssemblyVal = document.getElementById('tickerAssemblyVal');

    let currentStageIndex = -1;

    let frameCount = 0;
    let lastFpsTime = performance.now();
    let currentFps = 60;

    function syncHUD(t) {
      if (speedEl) {
        if (t < 0.08) {
          speedEl.textContent = String(Math.max(30, Math.min(144, currentFps))).padStart(3, '0');
        } else {
          const simulatedSpeed = Math.round(t * 360);
          speedEl.textContent = String(simulatedSpeed).padStart(3, '0');
        }
      }

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

        stageCards.forEach((card) => {
          const cardStage = parseInt(card.getAttribute('data-stage'), 10);
          if (cardStage === stageIdx) {
            card.classList.add('active');
          } else {
            card.classList.remove('active');
          }
        });
      }
    }

    // ─────────────────────────────────────────────────────────────
    // 8. INTERACTIVE BUTTON CONTROLS
    // ─────────────────────────────────────────────────────────────
    const resetBtn = document.getElementById('btnAssembleReset');
    if (resetBtn) {
      resetBtn.addEventListener('click', (e) => {
        e.preventDefault();
        window.scrollTo({ top: container.offsetTop, behavior: 'smooth' });
      });
    }

    const inspectBtn = document.getElementById('btnInspectPortfolio');
    if (inspectBtn) {
      inspectBtn.addEventListener('click', (e) => {
        e.preventDefault();
        const heroSection = document.getElementById('hero');
        if (heroSection) heroSection.scrollIntoView({ behavior: 'smooth' });
      });
    }

    document.querySelectorAll('.hud-jump-link').forEach((link) => {
      link.addEventListener('click', (e) => {
        e.preventDefault();
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

      // ═════════════════════════════════════════════════════════════
      // STAGE 0 vs STAGES 1-5 VISIBILITY & TRANSITION LOGIC
      // Stage 0: ONLY the 3D Solar System + Starfield + Hero text!
      // (NO floor grid, NO ground plate, NO Luau parts, NO shards)
      // Stages 1-5: Solar System dives into deep space and turns off;
      // Luau architecture appears, fades in and begins assembly!
      // ═════════════════════════════════════════════════════════════
      if (currentScroll < 0.12) {
        // Pure Stage 0: ONLY Solar System is visible!
        solarSystemGroup.visible = true;
        solarSystemGroup.position.set(0, 3.2, -25);
        solarSystemGroup.scale.set(1, 1, 1);

        keyLight.intensity = 0.35;
        rimLight.intensity = 0.35;
        frontFillLight.intensity = 0.45;
        mainGroup.visible = false;
        gridHelper.visible = false;
        ground.visible = false;
        coreLight.intensity = 0;
      } else if (currentScroll < 0.24) {
        // Transition between Stage 0 and Stage 1
        const tExit = (currentScroll - 0.12) / 0.12; // 0.0 -> 1.0
        solarSystemGroup.visible = true;
        solarSystemGroup.position.set(0, 3.2 + tExit * 2.0, -25 - tExit * 50);
        solarSystemGroup.scale.setScalar(Math.max(0.01, 1 - tExit * 0.75));

        keyLight.intensity = 0.35 + tExit * 2.25;
        rimLight.intensity = 0.35 + tExit * 2.65;
        frontFillLight.intensity = 0.45 + tExit * 0.85;
        mainGroup.visible = true;
        mainGroup.scale.setScalar(Math.min(1, tExit * 1.05));
        gridHelper.visible = true;
        ground.visible = true;
        coreLight.intensity = 2.8 * Math.min(1, tExit);
      } else {
        // Stages 1-5: Full Luau Assembly (Solar system completely hidden)
        solarSystemGroup.visible = false;
        keyLight.intensity = 2.6;
        rimLight.intensity = 3.0;
        frontFillLight.intensity = 1.3;
        mainGroup.visible = true;
        mainGroup.scale.set(1, 1, 1);
        gridHelper.visible = true;
        ground.visible = true;
        coreLight.intensity = 2.8 + Math.sin(elapsed * 3) * 0.7;
      }

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


      // Subtle celestial rotation of elements
      if (quantumLattice) {
        quantumLattice.rotation.x = elapsed * 0.25;
        quantumLattice.rotation.y = elapsed * 0.35;
      }
      if (ring1) ring1.rotation.z += 0.008;
      if (ring2) ring2.rotation.x += 0.01;
      if (band) band.rotation.y += 0.006;
      if (crescentMoon) crescentMoon.rotation.y += 0.004;

      // Orbiting Golden Satellite Moon
      if (satelliteGroup) {
        const satAngle = elapsed * 1.5;
        satelliteGroup.position.x = Math.cos(satAngle) * 2.35;
        satelliteGroup.position.z = Math.sin(satAngle) * 2.35;
        satelliteGroup.position.y = Math.sin(satAngle * 2) * 0.35 + 0.9;
        gim1.rotation.y += 0.02;
        gim2.rotation.z += 0.025;
      }

      // Starfield Particle Flow
      const positions = starfield.geometry.attributes.position.array;
      const speedMult = 1 + scrollVelocity * 45;
      for (let i = 2; i < positions.length; i += 3) {
        positions[i] += 0.025 * speedMult;
        if (positions[i] > 32) positions[i] = -32;
      }
      starfield.geometry.attributes.position.needsUpdate = true;
      starfield.rotation.y = elapsed * 0.015;

      coreLight.intensity = 2.8 + Math.sin(elapsed * 3) * 0.7;

      // Orbiting Solar System Animation
      if (typeof solarPlanets !== 'undefined') {
        solarPlanets.forEach((p) => {
          p.angle += delta * p.speed * 0.45;
          p.mesh.position.x = Math.cos(p.angle) * p.orbitRadius;
          p.mesh.position.z = Math.sin(p.angle) * p.orbitRadius;

          if (p.selfRotate) {
            p.selfRotate.rotation.y += delta * (p.rotSpeed || 1.0);
          } else {
            p.mesh.rotation.y += delta * 1.0;
          }

          if (p.clouds) {
            p.clouds.rotation.y += delta * 1.35;
          }

          if (p.moonMesh) {
            p.moonAngle += delta * 2.2;
            p.moonMesh.position.x = Math.cos(p.moonAngle) * p.moonOrbit;
            p.moonMesh.position.z = Math.sin(p.moonAngle) * p.moonOrbit;
            p.moonMesh.rotation.y += delta * 1.5;
          }
        });
      }

      if (sunCorona) {
        sunCorona.rotation.y += delta * 0.12;
        sunCorona.scale.setScalar(1 + Math.sin(elapsed * 2.5) * 0.04);
      }
      if (typeof sunRays !== 'undefined' && sunRays) {
        sunRays.rotation.z += delta * 0.035;
      }
      if (typeof sunCore !== 'undefined' && sunCore) {
        sunCore.rotation.y += delta * 0.025;
      }
      if (asteroidBelt) {
        asteroidBelt.rotation.y += delta * 0.04;
      }
      if (solarSystemGroup) {
        solarSystemGroup.rotation.y += delta * 0.008;
      }

      // Live Render FPS Tracker
      frameCount++;
      const now = performance.now();
      if (now - lastFpsTime >= 500) {
        currentFps = Math.round((frameCount * 1000) / (now - lastFpsTime));
        frameCount = 0;
        lastFpsTime = now;
      }

      syncHUD(currentScroll);

      renderer.render(scene, camera);
    }

    renderLoop();
    } catch (err) {
      console.error('[Luau Engine Critical Error]', err);
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initEngine);
  } else {
    initEngine();
  }
})();
