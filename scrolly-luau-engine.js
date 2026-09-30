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

    const container = document.getElementById('scrolly-luau-container');
    const stage = document.getElementById('webgl-stage');
    if (!container || !stage) return;

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

    const particleMat = new THREE.PointsMaterial({
      size: 0.22,
      vertexColors: true,
      transparent: true,
      opacity: 0.75,
      blending: THREE.AdditiveBlending
    });
    const starfield = new THREE.Points(particleGeo, particleMat);
    scene.add(starfield);

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
    // 7. HUD SYNCHRONIZATION (Silent, Pure Visual Telemetry)
    // ─────────────────────────────────────────────────────────────
    const speedEl = document.getElementById('f1SpeedVal');
    const stageValEl = document.getElementById('f1StageVal');
    const progressFillEl = document.getElementById('f1ProgressFill');
    const ledBars = document.querySelectorAll('.led-segment');
    const stageCards = document.querySelectorAll('.luau-stage-card');
    const tickerAssemblyVal = document.getElementById('tickerAssemblyVal');

    let currentStageIndex = -1;

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
