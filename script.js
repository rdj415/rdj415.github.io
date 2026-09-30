/**
 * ROBLOX LUAU SYSTEMS ARCHITECT - SCRIPT ENGINE
 * Background Particle Canvas, Code Showroom Tabs, Clipboard Feedback
 */

document.addEventListener('DOMContentLoaded', () => {

  // 1. High-Performance Interactive Background Engine
  const canvas = document.getElementById('bg-canvas');
  if (canvas) {
    const ctx = canvas.getContext('2d');
    let width = 0;
    let height = 0;
    let dpr = window.devicePixelRatio || 1;

    function resize() {
      width = window.innerWidth;
      height = window.innerHeight;
      canvas.width = width * dpr;
      canvas.height = height * dpr;
      canvas.style.width = width + 'px';
      canvas.style.height = height + 'px';
      ctx.setTransform(1, 0, 0, 1, 0, 0);
      ctx.scale(dpr, dpr);
    }
    resize();
    window.addEventListener('resize', resize);

    // Mouse Interaction
    const mouse = {
      x: null,
      y: null,
      radius: 180,
      active: false
    };

    window.addEventListener('mousemove', (e) => {
      mouse.x = e.clientX;
      mouse.y = e.clientY;
      mouse.active = true;
      document.documentElement.style.setProperty('--mouse-x', `${e.clientX}px`);
      document.documentElement.style.setProperty('--mouse-y', `${e.clientY}px`);
    });

    window.addEventListener('mouseleave', () => {
      mouse.active = false;
      mouse.x = null;
      mouse.y = null;
    });

    const colors = [
      { r: 0, g: 242, b: 254 },   // Cyan
      { r: 168, g: 85, b: 247 },  // Purple
      { r: 56, g: 189, b: 248 },  // Sky
      { r: 16, g: 185, b: 129 }   // Emerald
    ];

    const particleCount = Math.min(Math.floor(window.innerWidth / 18), 75);
    const particles = [];

    class Particle {
      constructor() {
        this.x = Math.random() * width;
        this.y = Math.random() * height;
        this.vx = (Math.random() - 0.5) * 0.55;
        this.vy = (Math.random() - 0.5) * 0.55;
        this.radius = Math.random() * 1.6 + 0.9;
        this.color = colors[Math.floor(Math.random() * colors.length)];
        this.pulsePhase = Math.random() * Math.PI * 2;
        this.pulseSpeed = 0.02 + Math.random() * 0.02;
      }

      update() {
        // Mouse Repulsion
        if (mouse.active && mouse.x !== null) {
          const dx = mouse.x - this.x;
          const dy = mouse.y - this.y;
          const dist = Math.sqrt(dx * dx + dy * dy);

          if (dist < mouse.radius) {
            const force = (mouse.radius - dist) / mouse.radius;
            const angle = Math.atan2(dy, dx);
            this.x -= Math.cos(angle) * force * 1.6;
            this.y -= Math.sin(angle) * force * 1.6;
          }
        }

        this.x += this.vx;
        this.y += this.vy;

        // Wrap edges smoothly
        if (this.x < -10) this.x = width + 10;
        if (this.x > width + 10) this.x = -10;
        if (this.y < -10) this.y = height + 10;
        if (this.y > height + 10) this.y = -10;

        this.pulsePhase += this.pulseSpeed;
      }

      draw() {
        const pulse = Math.sin(this.pulsePhase) * 0.35 + 0.65;
        const currentRadius = this.radius * (0.85 + pulse * 0.3);

        ctx.beginPath();
        ctx.arc(this.x, this.y, currentRadius, 0, Math.PI * 2);
        ctx.fillStyle = `rgba(${this.color.r}, ${this.color.g}, ${this.color.b}, ${0.55 * pulse})`;
        ctx.shadowBlur = 8;
        ctx.shadowColor = `rgba(${this.color.r}, ${this.color.g}, ${this.color.b}, 0.7)`;
        ctx.fill();
        ctx.shadowBlur = 0;
      }
    }

    for (let i = 0; i < particleCount; i++) {
      particles.push(new Particle());
    }

    // Traveling Data Packets
    let pulseT = 0;

    function animate() {
      ctx.clearRect(0, 0, width, height);
      pulseT += 0.012;

      // 1. Connect nearby particles
      const connectionDist = 135;
      for (let i = 0; i < particles.length; i++) {
        for (let j = i + 1; j < particles.length; j++) {
          const p1 = particles[i];
          const p2 = particles[j];
          const dx = p1.x - p2.x;
          const dy = p1.y - p2.y;
          const dist = Math.sqrt(dx * dx + dy * dy);

          if (dist < connectionDist) {
            const alpha = (1 - dist / connectionDist) * 0.22;
            ctx.beginPath();
            ctx.moveTo(p1.x, p1.y);
            ctx.lineTo(p2.x, p2.y);
            ctx.strokeStyle = `rgba(0, 242, 254, ${alpha})`;
            ctx.lineWidth = 0.8;
            ctx.stroke();

            // Occasional traveling data pulse between linked nodes
            if ((i + j) % 6 === 0 && dist < 110) {
              const packetPos = (Math.sin(pulseT * 2 + i) + 1) / 2;
              const px = p1.x + (p2.x - p1.x) * packetPos;
              const py = p1.y + (p2.y - p1.y) * packetPos;
              ctx.beginPath();
              ctx.arc(px, py, 1.5, 0, Math.PI * 2);
              ctx.fillStyle = 'rgba(255, 255, 255, 0.75)';
              ctx.fill();
            }
          }
        }
      }

      // 2. Connect particles to mouse cursor when active
      if (mouse.active && mouse.x !== null) {
        for (let i = 0; i < particles.length; i++) {
          const p = particles[i];
          const dx = mouse.x - p.x;
          const dy = mouse.y - p.y;
          const dist = Math.sqrt(dx * dx + dy * dy);

          if (dist < mouse.radius) {
            const alpha = (1 - dist / mouse.radius) * 0.48;
            ctx.beginPath();
            ctx.moveTo(p.x, p.y);
            ctx.lineTo(mouse.x, mouse.y);
            ctx.strokeStyle = `rgba(0, 242, 254, ${alpha})`;
            ctx.lineWidth = 1.2;
            ctx.stroke();

            // Glow on connected node
            ctx.beginPath();
            ctx.arc(p.x, p.y, p.radius * 1.6, 0, Math.PI * 2);
            ctx.fillStyle = `rgba(0, 242, 254, ${alpha * 0.8})`;
            ctx.fill();
          }
        }
      }

      // 3. Update & render particles
      for (let i = 0; i < particles.length; i++) {
        particles[i].update();
        particles[i].draw();
      }

      requestAnimationFrame(animate);
    }
    animate();
  }

  // 2. Toast Notifications & Clipboard
  const toastContainer = document.getElementById('toastContainer');

  function showToast(message, icon = '📋') {
    if (!toastContainer) return;
    const toast = document.createElement('div');
    toast.className = 'toast';
    toast.innerHTML = `<span>${icon}</span> <span>${message}</span>`;
    toastContainer.appendChild(toast);

    setTimeout(() => toast.classList.add('show'), 20);

    setTimeout(() => {
      toast.classList.remove('show');
      setTimeout(() => toast.remove(), 300);
    }, 2500);
  }

  function copyText(text, successMsg) {
    if (navigator.clipboard && window.isSecureContext) {
      navigator.clipboard.writeText(text).then(() => {
        showToast(successMsg || `Copied: ${text}`, '✅');
      }).catch(() => fallbackCopy(text, successMsg));
    } else {
      fallbackCopy(text, successMsg);
    }
  }

  function fallbackCopy(text, successMsg) {
    const textarea = document.createElement('textarea');
    textarea.value = text;
    textarea.style.position = 'fixed';
    textarea.style.left = '-9999px';
    document.body.appendChild(textarea);
    textarea.focus();
    textarea.select();
    try {
      document.execCommand('copy');
      showToast(successMsg || `Copied: ${text}`, '✅');
    } catch (err) {
      showToast('Could not copy', '❌');
    }
    document.body.removeChild(textarea);
  }

  document.querySelectorAll('[data-copy]').forEach((btn) => {
    btn.addEventListener('click', (e) => {
      e.preventDefault();
      const val = btn.getAttribute('data-copy');
      const isCrypto = val && val.startsWith('T') && val.length > 25;
      const msg = isCrypto ? 'TRON (TRC-20) address copied to clipboard!' : `Discord tag copied: ${val}`;
      copyText(val, msg);
    });
  });

  const quickDiscordBtn = document.getElementById('quickDiscordBtn');
  if (quickDiscordBtn) {
    quickDiscordBtn.addEventListener('click', () => {
      const tag = quickDiscordBtn.getAttribute('data-discord') || 'rdj_rb';
      copyText(tag, `Discord tag copied: ${tag}`);
    });
  }

  document.querySelectorAll('.btn-copy-code').forEach((btn) => {
    btn.addEventListener('click', () => {
      const targetSel = btn.getAttribute('data-clipboard-target');
      const targetEl = document.querySelector(targetSel);
      if (targetEl) {
        copyText(targetEl.innerText, 'Code snippet copied to clipboard!');
      }
    });
  });

  // 2.5 Video Showcase Switcher
  const videoTabs = document.querySelectorAll('.v-tab');
  const videoCards = document.querySelectorAll('.featured-video-card');

  videoTabs.forEach((tab) => {
    tab.addEventListener('click', () => {
      const targetId = tab.getAttribute('data-target');
      videoTabs.forEach((t) => t.classList.remove('active'));
      videoCards.forEach((c) => {
        c.classList.remove('active');
        const v = c.querySelector('video');
        if (v) v.pause();
      });

      tab.classList.add('active');
      const targetCard = document.getElementById(targetId);
      if (targetCard) {
        targetCard.classList.add('active');
        const activeVideo = targetCard.querySelector('video');
        if (activeVideo) {
          activeVideo.currentTime = 0;
          activeVideo.play().catch(() => {});
        }
      }
    });
  });

  // 3. Code Tabs Switcher
  const codeTabs = document.querySelectorAll('.code-tab');
  const codePanels = document.querySelectorAll('.code-panel');

  codeTabs.forEach((tab) => {
    tab.addEventListener('click', () => {
      const targetId = tab.getAttribute('data-target');
      codeTabs.forEach((t) => t.classList.remove('active'));
      codePanels.forEach((p) => p.classList.remove('active'));

      tab.classList.add('active');
      const targetPanel = document.getElementById(targetId);
      if (targetPanel) targetPanel.classList.add('active');
    });
  });

  // 4. Mobile Navigation
  const navToggle = document.getElementById('navToggle');
  const navLinks = document.getElementById('nav-links');

  if (navToggle && navLinks) {
    navToggle.addEventListener('click', () => {
      navLinks.classList.toggle('open');
    });

    document.querySelectorAll('.nav-link').forEach((link) => {
      link.addEventListener('click', () => {
        navLinks.classList.remove('open');
      });
    });
  }

  // 5. Scroll Spy
  const sections = document.querySelectorAll('#scrolly-luau-container, section[id]');
  const navItems = document.querySelectorAll('.nav-link');

  window.addEventListener('scroll', () => {
    let current = '';
    const scrollY = window.pageYOffset;

    sections.forEach((section) => {
      const sectionTop = section.offsetTop - 100;
      const sectionHeight = section.offsetHeight;
      if (scrollY >= sectionTop && scrollY < sectionTop + sectionHeight) {
        current = section.getAttribute('id');
      }
    });

    navItems.forEach((link) => {
      link.classList.remove('active');
      if (link.getAttribute('href') === `#${current}`) {
        link.classList.add('active');
      }
    });
  });

});
