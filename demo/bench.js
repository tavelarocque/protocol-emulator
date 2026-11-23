"use strict";
/* The bench: a demo board carrying the chip, wired to a device that follows
   the recorded pins. Drawn with three.js (demo/vendor, MIT), which the page
   carries inside itself, so nothing is fetched. Lengths are in millimetres.

   The board is a drawing in the style of a Tiny Tapeout demo board, not a
   copy of one, and the devices are drawings too. What moves them is the
   record: deviceState() in the page reads the pins and nothing else. */

async function makeBench(canvas, labelBox) {
  const T = window.THREE;
  if (!T) throw new Error("three.js is not in the page");

  const renderer = new T.WebGLRenderer({ canvas, antialias: true });
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = T.PCFSoftShadowMap;
  renderer.toneMapping = T.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.35;
  renderer.outputColorSpace = T.SRGBColorSpace;

  const world = new T.Scene();
  world.background = new T.Color(0x0a1517);
  world.fog = new T.Fog(0x0a1517, 520, 1200);

  /* ------------------------------------------------------- light and room */

  // Reflections come from a dark room with a few bright panels in it.
  {
    const room = new T.Scene();
    room.add(new T.Mesh(new T.BoxGeometry(900, 600, 900), new T.MeshBasicMaterial({ color: 0x141c1e, side: T.BackSide })));
    const panel = (x, y, z, w, h, power, ry) => {
      const m = new T.Mesh(new T.PlaneGeometry(w, h), new T.MeshBasicMaterial({ color: new T.Color().setScalar(power), side: T.DoubleSide }));
      m.position.set(x, y, z); m.lookAt(0, 0, 0); if (ry) m.rotateY(ry); room.add(m);
    };
    panel(-260, 260, 200, 260, 160, 9); panel(300, 220, -120, 200, 200, 5); panel(0, 290, 0, 300, 300, 3.5); panel(120, 60, 400, 400, 90, 2);
    const pm = new T.PMREMGenerator(renderer);
    world.environment = pm.fromScene(room, 0.03).texture;
    world.environmentIntensity = 1.0;
    pm.dispose();
  }
  world.add(new T.HemisphereLight(0xd6ecff, 0x1b1611, 0.9));
  const key = new T.DirectionalLight(0xfff0dc, 3.4);
  key.position.set(-150, 300, 190); key.castShadow = true;
  key.shadow.mapSize.set(2048, 2048); key.shadow.bias = -0.0005; key.shadow.normalBias = 0.6; key.shadow.radius = 5;
  Object.assign(key.shadow.camera, { left: -260, right: 260, top: 220, bottom: -220, near: 50, far: 800 });
  key.shadow.camera.updateProjectionMatrix();
  world.add(key, key.target);
  const fill = new T.DirectionalLight(0x8fb4d8, 0.55); fill.position.set(240, 120, -160); world.add(fill);

  /* ----------------------------------------------------------- materials */

  const mat = (color, o = {}) => new T.MeshStandardMaterial({ color, roughness: 0.6, metalness: 0, ...o });
  const M = {
    gold: mat(0xdcb65a, { metalness: 1, roughness: 0.26 }),
    steel: mat(0xcfd3d6, { metalness: 1, roughness: 0.3 }),
    brushed: mat(0xb9bec2, { metalness: 1, roughness: 0.48 }),
    black: mat(0x131517, { roughness: 0.5 }),
    housing: mat(0x101113, { roughness: 0.42 }),
    ic: mat(0x17191b, { roughness: 0.38 }),
    fr4: mat(0xb39a5c, { roughness: 0.8 }),
    rubber: mat(0x0c0d0e, { roughness: 0.95 }),
    cap: mat(0xb08a55, { roughness: 0.7 }),
    white: mat(0xf1f1ec, { roughness: 0.5 }),
  };

  function tex(wpx, hpx, paint) {
    const c = document.createElement("canvas"); c.width = wpx; c.height = hpx;
    const g = c.getContext("2d"); paint(g, wpx, hpx);
    const t = new T.CanvasTexture(c); t.colorSpace = T.SRGBColorSpace; t.anisotropy = renderer.capabilities.getMaxAnisotropy();
    return t;
  }
  function mesh(parent, geo, material, x = 0, y = 0, z = 0) {
    const m = new T.Mesh(geo, material); m.position.set(x, y, z); m.castShadow = true; m.receiveShadow = true; parent.add(m); return m;
  }
  const boxAt = (parent, w, h, d, material, x, y, z) => mesh(parent, new T.BoxGeometry(w, h, d), material, x, y, z);
  const cylAt = (parent, r, h, material, x, y, z, seg = 32) => mesh(parent, new T.CylinderGeometry(r, r, h, seg), material, x, y, z);

  // A slab with rounded corners, lying flat, its base at y = 0. Its top and
  // bottom take material 0 and its edge material 1; a texture on the top
  // reads left to right as x and top to bottom as z.
  function slab(w, d, h, r, bevel = 0) {
    const a = w - 2 * bevel, b = d - 2 * bevel, x = -a / 2, y = -b / 2, s = new T.Shape();
    s.moveTo(x + r, y); s.lineTo(x + a - r, y); s.quadraticCurveTo(x + a, y, x + a, y + r);
    s.lineTo(x + a, y + b - r); s.quadraticCurveTo(x + a, y + b, x + a - r, y + b);
    s.lineTo(x + r, y + b); s.quadraticCurveTo(x, y + b, x, y + b - r);
    s.lineTo(x, y + r); s.quadraticCurveTo(x, y, x + r, y);
    const g = new T.ExtrudeGeometry(s, { depth: h - 2 * bevel, bevelEnabled: bevel > 0, bevelThickness: bevel, bevelSize: bevel, bevelSegments: 3, curveSegments: 8 });
    g.rotateX(-Math.PI / 2); g.translate(0, bevel, 0);
    return g;
  }
  function boardTexture(w, d, k, paint) {
    const t = tex(Math.round(w * k), Math.round(d * k), (g) => { g.scale(k, k); g.translate(w / 2, d / 2); paint(g); });
    t.repeat.set(1 / w, 1 / d); t.offset.set(0.5, 0.5);
    return t;
  }
  // a trace that leaves along x, turns 45 degrees, and arrives along x
  function trace(g, x0, z0, x1, z1, width, at = 0.5) {
    const dz = z1 - z0, turn = x0 + (x1 - x0) * at - Math.sign(x1 - x0) * Math.abs(dz) / 2;
    g.lineWidth = width; g.lineJoin = "round"; g.lineCap = "round";
    g.beginPath(); g.moveTo(x0, z0); g.lineTo(turn, z0); g.lineTo(turn + Math.sign(x1 - x0) * Math.abs(dz), z1); g.lineTo(x1, z1); g.stroke();
  }
  const silk = (g, text, x, z, size, align = "center") => { g.font = "600 " + size + "px ui-monospace, Menlo, Consolas, monospace"; g.textAlign = align; g.textBaseline = "middle"; g.fillStyle = "#e8eee9"; g.fillText(text, x, z); };

  /* ------------------------------------------------------------ the bench */

  {
    const mat0 = tex(512, 512, (g, w) => {
      g.fillStyle = "#15292c"; g.fillRect(0, 0, w, w);
      g.strokeStyle = "rgba(160,205,200,0.10)"; g.lineWidth = 1;
      for (let i = 0; i <= 10; i++) { const p = i * w / 10; g.beginPath(); g.moveTo(p, 0); g.lineTo(p, w); g.moveTo(0, p); g.lineTo(w, p); g.stroke(); }
      g.strokeStyle = "rgba(160,205,200,0.22)"; g.lineWidth = 2; g.strokeRect(0, 0, w, w);
    });
    mat0.wrapS = mat0.wrapT = T.RepeatWrapping; mat0.repeat.set(24, 24);
    const ground = new T.Mesh(new T.PlaneGeometry(2400, 2400), mat(0xffffff, { map: mat0, roughness: 0.9 }));
    ground.rotation.x = -Math.PI / 2; ground.receiveShadow = true; world.add(ground);
  }

  /* ------------------------------------------------------------ the board */

  const BOARD = { w: 124, d: 86, top: 6.6 };          // top surface height above the bench
  const HEADER_X = 53, pinZ = (p) => -21 + p * 6;
  const WIRE_COLORS = [0xe9e9e4, 0xe2b714, 0x2f9a48, 0x2f66d0, 0x8a4fc7, 0x9a9da0, 0xd9622b, 0xc9302c];

  const board = new T.Group(); world.add(board);
  {
    const k = 12;
    const top = boardTexture(BOARD.w, BOARD.d, k, (g) => {
      g.fillStyle = "#0c3d36"; g.fillRect(-BOARD.w / 2, -BOARD.d / 2, BOARD.w, BOARD.d);
      // copper under the mask: a hatched pour, then the routed traces
      g.strokeStyle = "rgba(26,104,90,0.55)"; g.lineWidth = 0.25;
      for (let i = -160; i < 160; i += 2.2) { g.beginPath(); g.moveTo(i, -50); g.lineTo(i + 100, 50); g.stroke(); }
      g.fillStyle = "#0c3d36"; g.fillRect(-6, -26, 44, 44); g.fillRect(-42, -18, 28, 30);
      g.strokeStyle = "#1a7564";
      for (let p = 0; p < 8; p++) trace(g, 34.5, -14.5 + p * 3, HEADER_X - 2.6, pinZ(p), 0.55, 0.42);   // chip to P0..P7
      for (let i = 0; i < 4; i++) trace(g, -23.5, -8.5 + i * 3, -2.5, -8.5 + i * 3, 0.5);              // host port
      for (let i = 0; i < 2; i++) trace(g, -52, 19.2 + i * 1.6, -31.5 + i * 1.4, 1, 0.4, 0.3);         // USB
      trace(g, -28, 10.5, -28, 1.5, 0.4); trace(g, -44, -28, -33, -8, 0.4, 0.6); trace(g, 16, 20, 16, 30, 1.2);
      trace(g, -40, 30, 40, 30, 1.2); trace(g, -6, -30, 40, -30, 0.9);
      // pads and holes
      g.fillStyle = "#d6b25a";
      for (let p = 0; p < 8; p++) { g.beginPath(); g.arc(HEADER_X, pinZ(p), 1.75, 0, 7); g.fill(); }
      for (let i = 0; i < 12; i++) for (const s of [-1, 1]) { g.fillRect(16 + s * 17 - 1.2, -20.5 + i * 3 - 0.9, 2.4, 1.8); }
      for (const [x, z] of [[-55, -36], [55, -36], [-55, 36], [55, 36]]) {
        g.fillStyle = "#d6b25a"; g.beginPath(); g.arc(x, z, 3.4, 0, 7); g.fill();
        g.fillStyle = "#06100f"; g.beginPath(); g.arc(x, z, 1.7, 0, 7); g.fill();
      }
      for (const [x, z] of [[-12, 22], [-4, 26], [38, 24], [44, -34], [-18, -30], [2, 34], [-36, 20], [30, -36], [-50, 2], [46, 30]]) {
        g.fillStyle = "#d6b25a"; g.beginPath(); g.arc(x, z, 0.75, 0, 7); g.fill(); g.fillStyle = "#06100f"; g.beginPath(); g.arc(x, z, 0.3, 0, 7); g.fill();
      }
      // silkscreen
      silk(g, "PROTOCOL EMULATOR", -46, -37.2, 3.6, "left");
      silk(g, "demo board, drawn for this page", -46, -32.6, 2, "left");
      for (let p = 0; p < 8; p++) silk(g, "P" + p, HEADER_X - 6.6, pinZ(p), 2.5);
      silk(g, "HOST", -28, -15, 2.4); silk(g, "USB", -53, 12, 2.4); silk(g, "RESET", -44, -35, 2); silk(g, "SPI", -12, -12.5, 2);
      silk(g, "3V3", -32, 33.6, 2); silk(g, "GND", 22, 33.6, 2); silk(g, "PROTOCOL PINS", HEADER_X - 14, 30.5, 2.2);
      g.strokeStyle = "#e8eee9"; g.lineWidth = 0.3; g.strokeRect(-3.5, -23.5, 39, 39); g.strokeRect(HEADER_X - 3.4, -24.6, 6.8, 49.2);
    });
    const pcb = mesh(board, slab(BOARD.w, BOARD.d, 1.6, 3.5), [mat(0xffffff, { map: top, roughness: 0.42, metalness: 0.1 }), M.fr4], 0, BOARD.top - 1.6, 0);
    pcb.castShadow = true;
    for (const [x, z] of [[-55, -36], [55, -36], [-55, 36], [55, 36]]) {                        // standoffs and screws
      cylAt(board, 2.6, BOARD.top - 1.6, M.brushed, x, (BOARD.top - 1.6) / 2, z, 6);
      cylAt(board, 2.5, 1.2, M.steel, x, BOARD.top + 0.6, z, 24);
    }
    const Y = BOARD.top;
    // USB-C socket
    mesh(board, slab(9, 7.6, 3.2, 1.3, 0.3).rotateY(Math.PI / 2), [M.steel, M.steel], -58.6, Y, 20);
    boxAt(board, 5.4, 1.2, 6.4, M.black, -59.4, Y + 1.6, 20);
    // the host microcontroller, its crystal and flash
    const hostTop = tex(256, 256, (g) => { g.fillStyle = "#1a1c1e"; g.fillRect(0, 0, 256, 256); g.fillStyle = "#6f777b"; g.font = "600 34px ui-monospace, monospace"; g.textAlign = "center"; g.fillText("RP2040", 128, 118); g.font = "22px ui-monospace, monospace"; g.fillText("host", 128, 158); g.beginPath(); g.arc(34, 34, 9, 0, 7); g.fill(); });
    hostTop.repeat.set(1 / 7, 1 / 7); hostTop.offset.set(0.5, 0.5);
    mesh(board, slab(7, 7, 0.9, 0.3, 0.12), [mat(0xffffff, { map: hostTop, roughness: 0.4 }), M.ic], -28, Y, -4);
    mesh(board, slab(3.4, 1.5, 0.8, 0.5, 0.1), [M.steel, M.steel], -28, Y, 10);
    boxAt(board, 5.2, 1.5, 4, M.ic, -40, Y + 0.75, -6);
    for (let i = 0; i < 4; i++) for (const s of [-1, 1]) boxAt(board, 0.45, 0.25, 1, M.steel, -41.9 + i * 1.27, Y + 0.2, -6 + s * 2.6);
    // reset button, power LED, regulator
    boxAt(board, 6, 3.4, 6, M.brushed, -44, Y + 1.7, -28); cylAt(board, 1.7, 1.3, M.black, -44, Y + 4, -28, 20);
    boxAt(board, 6.5, 1.6, 3.5, M.ic, -20, Y + 0.8, 26); boxAt(board, 6.5, 0.3, 1.6, M.steel, -20, Y + 0.15, 28.4);
    const led = boxAt(board, 1.6, 0.7, 0.9, mat(0x64e08a, { emissive: 0x39d46e, emissiveIntensity: 2.2, roughness: 0.3 }), -8, Y + 0.35, 30); led.castShadow = false;
    // passives
    for (const [x, z, r] of [[-33, 3, 0], [-22, 4, 1], [-22, -12, 0], [-34, -12, 1], [-6, 22, 0], [4, 22, 0], [-2, -26, 1], [8, -26, 1], [40, 22, 0], [40, -24, 1], [-48, 8, 0], [-12, 28, 1], [28, 24, 0], [-36, 28, 0]]) {
      const c = new T.Group(); c.position.set(x, Y, z); c.rotation.y = r * Math.PI / 2; board.add(c);
      boxAt(c, 1.0, 0.8, 0.85, M.cap, 0, 0.4, 0); for (const s of [-1, 1]) boxAt(c, 0.36, 0.84, 0.9, M.steel, s * 0.66, 0.42, 0);
    }
    // the host's own header, unconnected
    for (let i = 0; i < 10; i++) { boxAt(board, 2.5, 2.5, 2.5, M.housing, -40 + i * 2.54, Y + 1.25, 36); boxAt(board, 0.64, 8.5, 0.64, M.gold, -40 + i * 2.54, Y + 2.2, 36); }
    for (let i = 0; i < 6; i++) { boxAt(board, 2.5, 2.5, 2.5, M.housing, 10 + i * 2.54, Y + 1.25, 36); boxAt(board, 0.64, 8.5, 0.64, M.gold, 10 + i * 2.54, Y + 2.2, 36); }
    // P0 to P7
    for (let p = 0; p < 8; p++) { boxAt(board, 4.6, 2.6, 4.6, M.housing, HEADER_X, Y + 1.3, pinZ(p)); boxAt(board, 0.9, 9, 0.9, M.gold, HEADER_X, Y + 3.2, pinZ(p)); }

    // the chip, on its carrier
    const cw = 38, carrier = new T.Group(); carrier.position.set(16, Y + 3.2, -4); board.add(carrier);
    const ctex = boardTexture(cw, cw, 14, (g) => {
      g.fillStyle = "#2a1846"; g.fillRect(-cw / 2, -cw / 2, cw, cw);
      g.strokeStyle = "#4a2f78";
      for (let i = 0; i < 12; i++) for (const s of [-1, 1]) { trace(g, s * 4.7, -3.85 + i * 0.7, s * 16.4, -16.5 + i * 3, 0.32, 0.36); }
      for (let i = 0; i < 8; i++) for (const s of [-1, 1]) { g.lineWidth = 0.32; g.beginPath(); g.moveTo(-2.45 + i * 0.7, s * 4.7); g.lineTo(-2.45 + i * 0.7, s * 7.5); g.lineTo(-9 + i * 2.6, s * 11.5); g.stroke(); }
      g.fillStyle = "#d6b25a";
      for (let i = 0; i < 12; i++) for (const s of [-1, 1]) { g.beginPath(); g.arc(s * 17, -16.5 + i * 3, 1.05, 0, 7); g.fill(); g.fillRect(s * 4.7 - 0.5, -4.05 + i * 0.7, 1, 0.4); }
      for (let i = 0; i < 12; i++) for (const s of [-1, 1]) g.fillRect(-4.05 + i * 0.7, s * 4.7 - 0.5, 0.4, 1);
      silk(g, "the chip", 0, -12.6, 2.6); silk(g, "IHP SG13 · 130 nm", 0, 12, 1.9); silk(g, "designed for tapeout", 0, 15, 1.6);
      g.fillStyle = "#e8eee9"; g.beginPath(); g.arc(-6.4, -6.4, 0.5, 0, 7); g.fill();
    });
    mesh(carrier, slab(cw, cw, 1.6, 2), [mat(0xffffff, { map: ctex, roughness: 0.4, metalness: 0.1 }), M.fr4]);
    for (let i = 0; i < 12; i++) for (const s of [-1, 1]) { boxAt(carrier, 2.5, 2.9, 2.5, M.housing, s * 17, -1.5, -16.5 + i * 3); cylAt(carrier, 0.55, 0.5, M.gold, s * 17, 1.75, -16.5 + i * 3, 12); }
    const chipTop = tex(512, 512, (g) => {
      g.fillStyle = "#17191b"; g.fillRect(0, 0, 512, 512);
      g.fillStyle = "#7d868a"; g.textAlign = "center"; g.font = "600 46px ui-monospace, monospace"; g.fillText("PROTOCOL", 256, 196); g.fillText("EMULATOR", 256, 250);
      g.font = "30px ui-monospace, monospace"; g.fillText("v2.3 · 2 threads", 256, 318); g.fillText("3 SRAM · 8 pins", 256, 360);
      g.beginPath(); g.arc(66, 66, 18, 0, 7); g.fill();
    });
    chipTop.repeat.set(1 / 9, 1 / 9); chipTop.offset.set(0.5, 0.5);
    mesh(carrier, slab(9, 9, 0.95, 0.3, 0.15), [mat(0xffffff, { map: chipTop, roughness: 0.36 }), M.ic], 0, 1.6, 0);
  }
  const pinTip = (p) => new T.Vector3(HEADER_X, BOARD.top + 7.7, pinZ(p));

  /* ---------------------------------------------------- wires and labels */

  let stage = null, wires = [], labels = [], pinTags = [];
  const label = (pos, cls) => { const el = document.createElement("div"); el.className = "lab " + (cls || ""); labelBox.appendChild(el); const l = { pos, el }; labels.push(l); return l; };

  // A jumper from a protocol pin to a point on a device: the housing on the
  // pin, the wire up and over, a housing at the far end.
  function jumper(pin, to, lift = 26, entry = new T.Vector3(0, 1, 0)) {
    const from = pinTip(pin), color = WIRE_COLORS[pin], g = stage;
    const m = mat(color, { roughness: 0.45, emissive: color, emissiveIntensity: 0 });
    boxAt(g, 2.7, 13, 2.7, M.housing, from.x, from.y + 1.5, from.z);
    const a = from.clone().add(new T.Vector3(0, 8, 0)), b = to.clone().addScaledVector(entry, 12);
    const mid = a.clone().lerp(b, 0.5); mid.y = Math.max(a.y, b.y) + lift;
    const curve = new T.CatmullRomCurve3([a, a.clone().add(new T.Vector3(1, 9, 0)), mid, b.clone().addScaledVector(entry, 8), b], false, "centripetal");
    const tube = mesh(g, new T.TubeGeometry(curve, 48, 0.72, 10), m); tube.receiveShadow = false;
    const end = boxAt(g, 2.7, 13, 2.7, M.housing, 0, 0, 0);
    end.position.copy(to).addScaledVector(entry, 6.5); end.quaternion.setFromUnitVectors(new T.Vector3(0, 1, 0), entry);
    wires.push({ pin, m });
  }
  // a wire that carries power or ground: it is there, and says nothing
  function lead(points, color, r = 0.6) {
    const t = mesh(stage, new T.TubeGeometry(new T.CatmullRomCurve3(points.map((p) => new T.Vector3(...p)), false, "centripetal"), 40, r, 8), mat(color, { roughness: 0.5 }));
    t.receiveShadow = false;
  }

  /* -------------------------------------------------------------- devices */

  function terminal(x, z, pin, turn = -0.42) {
    const g = new T.Group(); g.position.set(x, 0, z); g.rotation.y = turn; stage.add(g);
    mesh(g, slab(72, 26, 2.2, 5, 0.6), [M.black, M.black]);
    boxAt(g, 6, 16, 5, M.black, 0, 9, -6).rotation.x = -0.2;
    const head = new T.Group(); head.position.set(0, 34, -3); head.rotation.x = -0.2; g.add(head);
    mesh(head, slab(76, 50, 6, 4, 1).rotateX(Math.PI / 2), [M.black, M.black], 0, 0, -3);
    const c = document.createElement("canvas"); c.width = 768; c.height = 480;
    const screenTex = new T.CanvasTexture(c); screenTex.colorSpace = T.SRGBColorSpace; screenTex.anisotropy = 8;
    const screen = new T.Mesh(new T.PlaneGeometry(68, 42), new T.MeshStandardMaterial({ color: 0x000000, emissive: 0xffffff, emissiveMap: screenTex, emissiveIntensity: 1.25, roughness: 1 }));
    screen.position.set(0, 0, 3.3); head.add(screen);
    const glow = new T.PointLight(0x58e69a, 0, 160, 2); glow.position.set(0, 0, 24); head.add(glow);
    boxAt(g, 9, 4.4, 9, M.housing, -30, 2.2, -4);                         // where the line comes in
    g.updateMatrixWorld(true);
    jumper(pin, g.localToWorld(new T.Vector3(-30, 4.4, -4)), 26);
    label(g.localToWorld(new T.Vector3(0, 64, 0)), "dim").el.textContent = "serial terminal";
    let shown = null;
    return (st, s, c2) => {
      const text = "> " + st.text + (c2 < s.cycles - 1 ? "█" : "");
      if (text === shown) return; shown = text;
      const k = c.getContext("2d");
      k.fillStyle = "#04100c"; k.fillRect(0, 0, 768, 480);
      k.fillStyle = "#1f6b48"; k.font = "26px ui-monospace, Menlo, Consolas, monospace"; k.textBaseline = "top";
      k.fillText("serial  " + s.device.line, 30, 26);
      k.fillRect(30, 66, 708, 2);
      k.fillStyle = "#63f0a4"; k.font = "600 92px ui-monospace, Menlo, Consolas, monospace"; k.fillText(text, 30, 110);
      k.fillStyle = "#1f6b48"; k.font = "24px ui-monospace, Menlo, Consolas, monospace";
      k.fillText(st.text.length + " byte" + (st.text.length === 1 ? "" : "s") + " received", 30, 420);
      screenTex.needsUpdate = true; glow.intensity = 260 + st.text.length * 40;
    };
  }

  function stepper(x, z, d) {
    const g = new T.Group(); g.position.set(x, 0, z); g.rotation.y = -0.5; stage.add(g);
    // the driver board, which takes STEP and DIR
    const drv = new T.Group(); drv.position.set(-46, 0, 14); g.add(drv);
    const dtex = boardTexture(21, 16, 16, (k) => { k.fillStyle = "#7a1622"; k.fillRect(-11, -8, 22, 16); k.fillStyle = "#d6b25a"; for (let i = 0; i < 8; i++) for (const s of [-1, 1]) { k.beginPath(); k.arc(-8.9 + i * 2.54, s * 6.3, 0.8, 0, 7); k.fill(); } silk(k, "STEP DIR", -4.4, 3.6, 1.5); silk(k, "driver", 5.6, 3.6, 1.5); });
    mesh(drv, slab(21, 16, 1.6, 1), [mat(0xffffff, { map: dtex, roughness: 0.45 }), M.fr4], 0, 9, 0);
    for (let i = 0; i < 8; i++) for (const s of [-1, 1]) boxAt(drv, 0.64, 13, 0.64, M.gold, -8.9 + i * 2.54, 8, s * 6.3);
    for (const s of [-1, 1]) boxAt(drv, 21, 2.5, 2.5, M.housing, 0, 7.75, s * 6.3);
    mesh(drv, slab(26, 22, 2, 2), [M.black, M.black]); boxAt(drv, 22, 5, 2.6, M.housing, 0, 4.5, -6.3); boxAt(drv, 22, 5, 2.6, M.housing, 0, 4.5, 6.3);
    boxAt(drv, 5, 1, 5, M.ic, 0, 11.1, 0);
    for (let i = 0; i < 5; i++) boxAt(drv, 8.6, 5.5, 0.8, M.brushed, 0, 14.3, -3.4 + i * 1.7); boxAt(drv, 8.6, 1, 8.2, M.brushed, 0, 12.1, 0);
    // the motor: two end caps, the stack between them, the shaft towards the viewer
    const body = new T.Group(); body.position.set(8, 23.5, 0); g.add(body);
    const face = (zc, depth, m) => mesh(body, slab(42.3, 42.3, depth, 5, 0.8).rotateX(Math.PI / 2), [m, m], 0, 0, zc);
    face(-20, 10, M.brushed); face(10, 10, M.brushed);
    mesh(body, slab(42.3, 42.3, 20, 3).rotateX(Math.PI / 2), [M.black, mat(0x1b1d20, { roughness: 0.35, metalness: 0.6 })], 0, 0, -10);
    mesh(body, new T.CylinderGeometry(11, 11, 2, 48).rotateX(Math.PI / 2), M.brushed, 0, 0, 21);
    for (const sx of [-1, 1]) for (const sy of [-1, 1]) mesh(body, new T.CylinderGeometry(1.9, 1.9, 1.4, 16).rotateX(Math.PI / 2), M.steel, sx * 15.5, sy * 15.5, 20.6);
    boxAt(body, 16, 6, 8, mat(0xe9e6dc, { roughness: 0.6 }), 0, -18, -24);
    const rotor = new T.Group(); rotor.position.set(0, 0, 22); body.add(rotor);
    mesh(rotor, new T.CylinderGeometry(2.5, 2.5, 22, 24).rotateX(Math.PI / 2), M.steel, 0, 0, 11);
    mesh(rotor, new T.CylinderGeometry(15, 15, 2.4, 64).rotateX(Math.PI / 2), mat(0x1d6f7d, { metalness: 0.85, roughness: 0.34 }), 0, 0, 14);
    mesh(rotor, new T.CylinderGeometry(4.6, 4.6, 5, 32).rotateX(Math.PI / 2), M.brushed, 0, 0, 16.5);
    boxAt(rotor, 2.2, 10.5, 0.5, M.white, 0, 9.2, 15.4);
    for (let i = 0; i < 20; i++) { const a = i / 20 * Math.PI * 2, t = boxAt(body, 0.5, i % 5 ? 1.6 : 3, 0.3, M.white, Math.sin(a) * 18.4, Math.cos(a) * 18.4, 20.3); t.rotation.z = -a; t.castShadow = false; }
    mesh(g, slab(50, 46, 2, 3), [M.rubber, M.rubber], 8, 0, 0);
    g.updateMatrixWorld(true);
    const at = (v) => g.localToWorld(new T.Vector3(...v));
    jumper(d.step, at([-52.36, 12.5, 20.3]), 22); jumper(d.dir, at([-49.82, 12.5, 20.3]), 30);
    [0x1a1a1a, 0x2a9d4a, 0xc9302c, 0x2f66d0].forEach((col, i) => lead([at([-41 + i * 2.5, 13, 7.7]).toArray(), at([-36 + i * 2, 20, 2 - i]).toArray(), at([-22 + i * 2, 12, -22 - i]).toArray(), at([2 + i * 2.6, 7, -25]).toArray()], col, 0.55));
    label(at([8, 56, 0]), "dim").el.textContent = "stepper motor and driver";
    const read = label(at([8, -2, 34]), "val");
    return (st) => { rotor.rotation.z = -st.steps * 1.8 * Math.PI / 180; read.el.textContent = (st.steps >= 0 ? "+" : "") + st.steps + " steps · " + (st.steps * 1.8).toFixed(1) + "°"; };
  }

  function servo(x, z, pin) {
    const g = new T.Group(); g.position.set(x, 0, z); g.rotation.y = -0.35; g.scale.setScalar(1.7); stage.add(g);
    const blue = mat(0x1b5fc4, { roughness: 0.32, transparent: true, opacity: 0.93 });
    mesh(g, slab(23, 12.5, 22, 1.2, 0.5), [blue, blue], 0, 1, 0);
    mesh(g, slab(32.5, 12.5, 2.4, 1.2, 0.3), [blue, blue], 0, 17, 0);
    cylAt(g, 5.9, 4.6, blue, -5.3, 25.2, 0, 40); cylAt(g, 2.8, 4.6, blue, 1.6, 25.2, 0, 24);
    cylAt(g, 2.3, 3.4, M.white, -5.3, 28.6, 0, 24);
    for (const s of [-1, 1]) cylAt(g, 1.1, 2.6, M.rubber, s * 13.9, 18.3, 0, 16);
    const horn = new T.Group(); horn.position.set(-5.3, 30.4, 0); g.add(horn);
    cylAt(horn, 3.6, 1.6, M.white, 0, 0, 0, 32); mesh(horn, slab(19, 4.4, 1.5, 2.1), [M.white, M.white], 8.4, -0.75, 0); cylAt(horn, 1.2, 1.9, M.steel, 0, 0.3, 0, 16);
    for (let i = 0; i < 4; i++) cylAt(horn, 0.5, 1.7, M.rubber, 6 + i * 3.2, 0, 0, 10);
    mesh(g, slab(44, 26, 1.2, 3), [M.rubber, M.rubber], 0, 0, 0);
    g.updateMatrixWorld(true);
    const at = (v) => g.localToWorld(new T.Vector3(...v));
    const plug = at([-17, 4.4, 9]);
    boxAt(stage, 8.4, 4.4, 14, M.housing, plug.x, plug.y - 2.2, plug.z).rotation.y = g.rotation.y;
    jumper(pin, plug.clone().add(new T.Vector3(-2.2, 0, 0)), 26);
    [[0x5a3a1c, -1], [0xc9302c, 0], [0xe07b1a, 1]].forEach(([col, i]) => lead([at([-11.5, 3.6, 1 + i * 1.2]).toArray(), at([-16, 2.2, 4 + i * 1.5]).toArray(), [plug.x + i * 2.3 + 1, plug.y - 1.5, plug.z - 6]], col, 0.7));
    label(at([0, 44, 0]), "dim").el.textContent = "RC servo";
    const read = label(at([0, -2, 16]), "val");
    return (st) => {
      const us = st.us == null ? 1500 : st.us;
      horn.rotation.y = (us - 1500) / 1000 * Math.PI;
      read.el.textContent = st.us == null ? "waiting for a pulse" : us.toFixed(0) + " us · " + ((us - 1000) / 1000 * 180).toFixed(0) + "°";
    };
  }

  function lamp(x, z, pin) {
    const g = new T.Group(); g.position.set(x, 0, z); stage.add(g);
    const btex = boardTexture(30, 30, 12, (k) => { k.fillStyle = "#101214"; k.fillRect(-15, -15, 30, 30); k.fillStyle = "#d6b25a"; for (const [a, b] of [[-11, -11], [11, -11], [-11, 11], [11, 11]]) { k.beginPath(); k.arc(a, b, 1.8, 0, 7); k.fill(); } k.fillRect(-13, 5, 5, 2.4); silk(k, "signal lamp", 0, -11.5, 2); silk(k, "KEY", -10.5, 10, 2); });
    mesh(g, slab(30, 30, 1.6, 2.5), [mat(0xffffff, { map: btex, roughness: 0.5 }), M.fr4], 0, 3, 0);
    for (const [a, b] of [[-11, -11], [11, -11], [-11, 11], [11, 11]]) cylAt(g, 1.6, 3, M.rubber, a, 1.5, b, 12);
    cylAt(g, 7.2, 1.6, M.brushed, 0, 5.4, 0, 48);
    const dome = mat(0xffe9a8, { emissive: 0xffc23d, emissiveIntensity: 0, roughness: 0.15, transparent: true, opacity: 0.9 });
    cylAt(g, 6, 9, dome, 0, 10.6, 0, 48).castShadow = false;
    mesh(g, new T.SphereGeometry(6, 48, 24, 0, Math.PI * 2, 0, Math.PI / 2), dome, 0, 15.1, 0).castShadow = false;
    boxAt(g, 1, 6, 0.4, M.steel, -1.4, 9, 0); boxAt(g, 2.4, 5, 0.4, M.steel, 1.6, 8.6, 0);
    const light = new T.PointLight(0xffc24d, 0, 260, 1.7); light.position.set(0, 20, 0); g.add(light);
    boxAt(g, 5, 4.6, 2.6, M.housing, -10.5, 6.9, 6.2); boxAt(g, 0.7, 7, 0.7, M.gold, -10.5, 9, 6.2);
    jumper(pin, new T.Vector3(x - 10.5, 12.5, z + 6.2), 24);
    label(new T.Vector3(x, 34, z), "dim").el.textContent = "signal lamp";
    const read = label(new T.Vector3(x, -2, z + 22), "val");
    return (st, s, c) => {
      dome.emissiveIntensity = st.lit ? 2.6 : 0.03; light.intensity = st.lit ? 4200 : 0;
      read.el.textContent = "received: " + (s.marks.filter((m) => m.until <= c).map((m) => m.text[0]).join("") || "...");
    };
  }

  function sensor(x, z, d) {
    const g = new T.Group(); g.position.set(x, 0, z); g.rotation.y = -0.3; g.scale.setScalar(1.5); stage.add(g);
    const w = 34, dd = 26;
    const btex = boardTexture(w, dd, 16, (k) => {
      k.fillStyle = "#1b2f6b"; k.fillRect(-w / 2, -dd / 2, w, dd);
      k.strokeStyle = "#2c4aa0"; for (let i = 0; i < 4; i++) trace(k, -13, -7.6 + i * 5.08, 1.5, -2.9 + i * 1.27 + (i > 1 ? 1.3 : 0), 0.4, 0.5);
      k.fillStyle = "#d6b25a"; for (let i = 0; i < 4; i++) { k.beginPath(); k.arc(-13.5, -7.6 + i * 5.08, 1.5, 0, 7); k.fill(); }
      for (const [a, b] of [[13, -9.5], [13, 9.5]]) { k.beginPath(); k.arc(a, b, 2.2, 0, 7); k.fill(); k.fillStyle = "#06100f"; k.beginPath(); k.arc(a, b, 1.1, 0, 7); k.fill(); k.fillStyle = "#d6b25a"; }
      ["VCC", "GND", "SDA", "SCL"].forEach((t, i) => silk(k, t, -8.6, -7.6 + i * 5.08, 1.9, "left"));
      silk(k, "TEMP", 7.5, -9.8, 2.4); silk(k, "I2C 0x48", 7.5, 10.6, 1.9);
    });
    mesh(g, slab(w, dd, 1.6, 2), [mat(0xffffff, { map: btex, roughness: 0.42, metalness: 0.1 }), M.fr4], 0, 4, 0);
    for (const [a, b] of [[13, -9.5], [13, 9.5], [-13, -11], [-13, 11]]) cylAt(g, 1.5, 4, M.rubber, a, 2, b, 12);
    boxAt(g, 5, 1.5, 4, M.ic, 4.5, 6.35, 0);                                          // the sensor
    for (let i = 0; i < 4; i++) for (const s of [-1, 1]) boxAt(g, 0.45, 0.25, 1, M.steel, 2.6 + i * 1.27, 5.8, s * 2.6);
    for (const b of [-5.2, 5.2]) { boxAt(g, 1.6, 0.6, 0.9, M.ic, 9.5, 5.9, b); for (const s of [-1, 1]) boxAt(g, 0.4, 0.64, 0.95, M.steel, 9.5 + s * 0.9, 5.92, b); }
    for (let i = 0; i < 4; i++) { boxAt(g, 2.5, 2.5, 2.5, M.housing, -13.5, 6.85, -7.6 + i * 5.08); boxAt(g, 0.64, 9, 0.64, M.gold, -13.5, 8.6, -7.6 + i * 5.08); }
    g.updateMatrixWorld(true);
    const at = (v) => g.localToWorld(new T.Vector3(...v));
    jumper(d.sda, at([-13.5, 12.4, 2.56]), 22); jumper(d.scl, at([-13.5, 12.4, 7.64]), 30);
    lead([[22, BOARD.top + 9, 36], [40, 30, 58], at([-24, 26, -6]).toArray(), at([-13.5, 15, -7.6]).toArray()], 0xc9302c, 0.65);
    lead([[24.5, BOARD.top + 9, 36], [46, 24, 64], at([-26, 22, 2]).toArray(), at([-13.5, 15, -2.52]).toArray()], 0x1a1a1a, 0.65);
    label(at([2, 30, 0]), "dim").el.textContent = "temperature sensor";
    const read = label(at([4, -2, 20]), "val");
    return (st) => { read.el.textContent = st.say; };
  }

  function network(x, z, d) {
    const g = new T.Group(); g.position.set(x, 0, z); stage.add(g);
    // the jack and its transformer, on a small board
    const w = 30, dd = 34;
    const btex = boardTexture(w, dd, 14, (k) => {
      k.fillStyle = "#0d4f3e"; k.fillRect(-w / 2, -dd / 2, w, dd);
      k.strokeStyle = "#1a7564"; for (let i = 0; i < 2; i++) trace(k, -11, -10.5 + i * 2.54, -1, -2 + i * 3, 0.5, 0.5);
      k.fillStyle = "#d6b25a"; for (let i = 0; i < 4; i++) { k.beginPath(); k.arc(-11.5, -10.5 + i * 2.54, 0.95, 0, 7); k.fill(); }
      silk(k, "TD+", -8, -10.5, 1.7, "left"); silk(k, "TD-", -8, -7.96, 1.7, "left"); silk(k, "10BASE-T", 3, -14, 2);
    });
    mesh(g, slab(w, dd, 1.6, 2), [mat(0xffffff, { map: btex, roughness: 0.42, metalness: 0.1 }), M.fr4], 0, 4, 0);
    for (const [a, b] of [[-12, 14], [12, 14], [12, -14], [-12, -3]]) cylAt(g, 1.5, 4, M.rubber, a, 2, b, 12);
    mesh(g, slab(16.5, 21.5, 13.5, 0.8, 0.3), [M.brushed, M.brushed], 4, 5.6, 5);       // the jack
    boxAt(g, 12, 8.5, 1, M.black, 4, 12.2, 15.6);
    const linkLed = boxAt(g, 2.6, 2, 0.6, mat(0x49d67c, { emissive: 0x2fd66e, emissiveIntensity: 2 }), -0.4, 17.4, 15.7);
    const actLed = boxAt(g, 2.6, 2, 0.6, mat(0xffb53d, { emissive: 0xff9d1a, emissiveIntensity: 0 }), 8.4, 17.4, 15.7);
    linkLed.castShadow = actLed.castShadow = false;
    for (let i = 0; i < 4; i++) { boxAt(g, 2.5, 2.5, 2.5, M.housing, -11.5, 6.85, -10.5 + i * 2.54); boxAt(g, 0.64, 9, 0.64, M.gold, -11.5, 8.6, -10.5 + i * 2.54); }
    // a switch for it to talk to, and the cable between
    const sw = new T.Group(); sw.position.set(58, 0, -52); sw.rotation.y = -0.25; g.add(sw);
    mesh(sw, slab(96, 58, 22, 3, 0.8), [mat(0x23272b, { metalness: 0.7, roughness: 0.45 }), mat(0x23272b, { metalness: 0.7, roughness: 0.45 })], 0, 2, 0);
    for (const [a, b] of [[-40, -22], [40, -22], [-40, 22], [40, 22]]) cylAt(sw, 3, 2, M.rubber, a, 1, b, 14);
    const lamps = [];
    for (let i = 0; i < 5; i++) {
      boxAt(sw, 13, 10.5, 1.2, M.black, -34 + i * 17, 11, 29);
      const l = boxAt(sw, 2.6, 1.6, 0.6, mat(0x1c3a25, { emissive: 0x2fd66e, emissiveIntensity: 0 }), -38 + i * 17, 19.4, 29.3); l.castShadow = false; lamps.push(l);
    }
    const swLabel = tex(512, 96, (k) => { k.fillStyle = "#23272b"; k.fillRect(0, 0, 512, 96); k.fillStyle = "#aeb8bd"; k.font = "600 34px ui-monospace, monospace"; k.textBaseline = "middle"; k.fillText("5-port switch · 10 Mbit/s", 16, 50); });
    const plate = new T.Mesh(new T.PlaneGeometry(64, 12), mat(0xffffff, { map: swLabel, roughness: 0.6 })); plate.rotation.x = -Math.PI / 2; plate.position.set(-10, 24.05, 10); sw.add(plate);
    g.updateMatrixWorld(true);
    const at = (v) => g.localToWorld(new T.Vector3(...v)), port = sw.localToWorld(new T.Vector3(-34, 11, 30));
    const cable = mat(0x2a6fd6, { roughness: 0.5 });
    const path = new T.CatmullRomCurve3([at([4, 12, 17]), at([5, 9, 30]), at([14, 2.8, 50]), at([40, 2.8, 52]), port.clone().add(new T.Vector3(-6, -5, 26)), port.clone().add(new T.Vector3(-1.5, 0, 9)), port], false, "centripetal");
    mesh(stage, new T.TubeGeometry(path, 80, 2.4, 12), cable);
    const plugA = boxAt(stage, 11.5, 8, 13, mat(0xdfe6ea, { roughness: 0.3, transparent: true, opacity: 0.85 }), 0, 0, 0); plugA.position.copy(at([4, 12.2, 21]));
    const plugB = boxAt(stage, 11.5, 8, 13, mat(0xdfe6ea, { roughness: 0.3, transparent: true, opacity: 0.85 }), 0, 0, 0); plugB.position.copy(port).add(new T.Vector3(-1, 0, 5.5)); plugB.rotation.y = -0.25;
    jumper(d.plus, at([-11.5, 12.4, -10.5]), 24); jumper(d.minus, at([-11.5, 12.4, -7.96]), 31);
    label(at([4, 30, 6]), "dim").el.textContent = "RJ45 jack and transformer";
    label(sw.localToWorld(new T.Vector3(0, 36, 0)), "dim").el.textContent = "network switch";
    const read = label(at([10, -2, 40]), "val");
    return (st) => {
      read.el.textContent = st.say;
      actLed.material.emissiveIntensity = st.active ? 3 : 0;
      lamps[0].material.emissiveIntensity = st.active ? 3.2 : 1.2;
    };
  }

  function canbus(x, z, d) {
    const g = new T.Group(); g.position.set(x, 0, z); stage.add(g);
    // the transceiver, which turns TXD and RXD into the two bus wires
    const w = 26, dd = 22;
    const btex = boardTexture(w, dd, 16, (k) => {
      k.fillStyle = "#12356e"; k.fillRect(-w / 2, -dd / 2, w, dd);
      k.strokeStyle = "#2a55a8"; for (let i = 0; i < 2; i++) { trace(k, -9.5, -3.8 + i * 2.54, -1.5, -1.9 + i * 1.27, 0.4); trace(k, 2.5, -1.9 + i * 3.8, 9, -2.5 + i * 5, 0.5); }
      k.fillStyle = "#d6b25a"; for (let i = 0; i < 4; i++) { k.beginPath(); k.arc(-10, -3.8 + i * 2.54, 0.95, 0, 7); k.fill(); }
      silk(k, "RXD", -7.4, -3.8, 1.6, "left"); silk(k, "TXD", -7.4, -1.26, 1.6, "left"); silk(k, "CAN transceiver", 0, -8.6, 1.8); silk(k, "H", 6.6, 7.6, 1.8); silk(k, "L", 6.6, 9.6, 1.8);
    });
    mesh(g, slab(w, dd, 1.6, 1.6), [mat(0xffffff, { map: btex, roughness: 0.42, metalness: 0.1 }), M.fr4], 0, 4, 0);
    for (const [a, b] of [[-11, -9], [11, -9], [-11, 9], [11, 9]]) cylAt(g, 1.4, 4, M.rubber, a, 2, b, 12);
    boxAt(g, 5, 1.5, 4, M.ic, 0.5, 6.35, 0);
    for (let i = 0; i < 4; i++) for (const s of [-1, 1]) boxAt(g, 0.45, 0.25, 1, M.steel, -1.4 + i * 1.27, 5.8, s * 2.6);
    for (let i = 0; i < 4; i++) { boxAt(g, 2.5, 2.5, 2.5, M.housing, -10, 6.85, -3.8 + i * 2.54); boxAt(g, 0.64, 9, 0.64, M.gold, -10, 8.6, -3.8 + i * 2.54); }
    const terminal = (parent, px, py, pz) => { boxAt(parent, 6.4, 8, 10.4, mat(0x2f8f4a, { roughness: 0.5 }), px, py + 4, pz); for (const s of [-1, 1]) cylAt(parent, 1.5, 0.8, M.steel, px, py + 8.2, pz + s * 2.6, 14); };
    terminal(g, 9.6, 5.6, 2.5);
    // the other node, further along the pair
    const node = new T.Group(); node.position.set(66, 0, -30); node.rotation.y = -0.45; g.add(node);
    mesh(node, slab(46, 34, 14, 3, 0.8), [mat(0x2b2f33, { roughness: 0.5 }), mat(0x2b2f33, { roughness: 0.5 })], 0, 1.5, 0);
    for (const [a, b] of [[-18, -12], [18, -12], [-18, 12], [18, 12]]) cylAt(node, 2.2, 1.5, M.rubber, a, 0.75, b, 12);
    terminal(node, -19, 15.5, 4);
    const nodeLed = boxAt(node, 3, 1, 3, mat(0x3a2a10, { emissive: 0xffa21a, emissiveIntensity: 0 }), 12, 15.9, 8); nodeLed.castShadow = false;
    const power = boxAt(node, 3, 1, 3, mat(0x49d67c, { emissive: 0x2fd66e, emissiveIntensity: 1.6 }), 4, 15.9, 8); power.castShadow = false;
    const tag = tex(512, 160, (k) => { k.fillStyle = "#2b2f33"; k.fillRect(0, 0, 512, 160); k.fillStyle = "#b9c2c7"; k.font = "600 44px ui-monospace, monospace"; k.textBaseline = "middle"; k.fillText("CAN node", 20, 56); k.font = "30px ui-monospace, monospace"; k.fillText("125 kbit/s · clock 1.25% slow", 20, 116); });
    const plate = new T.Mesh(new T.PlaneGeometry(34, 10.6), mat(0xffffff, { map: tag, roughness: 0.6 })); plate.rotation.x = -Math.PI / 2; plate.position.set(3, 15.55, -6); node.add(plate);
    g.updateMatrixWorld(true);
    const at = (v) => g.localToWorld(new T.Vector3(...v)), far = (v) => node.localToWorld(new T.Vector3(...v));
    // the pair: CAN H and CAN L, twisted
    const a0 = at([9.6, 14, 2.5]), b0 = far([-19, 24, 4]), turns = 9;
    const mid = [a0.clone().add(new T.Vector3(8, 6, 6)), a0.clone().lerp(b0, 0.5).add(new T.Vector3(0, -8, 14)), b0.clone().add(new T.Vector3(-8, 6, 6))];
    const spine = new T.CatmullRomCurve3([a0, ...mid, b0], false, "centripetal");
    [[0xe2b714, 0], [0x2f9a48, Math.PI]].forEach(([col, ph]) => {
      const pts = []; const up = new T.Vector3(0, 1, 0);
      for (let i = 0; i <= 120; i++) {
        const t = i / 120, p = spine.getPoint(t), tan = spine.getTangent(t), side = new T.Vector3().crossVectors(tan, up).normalize(), lift = new T.Vector3().crossVectors(side, tan).normalize();
        const a = t * turns * Math.PI * 2 + ph, r = 1.1 * Math.min(1, t * 8, (1 - t) * 8) + 0.5;
        pts.push(p.addScaledVector(side, Math.cos(a) * r).addScaledVector(lift, Math.sin(a) * r));
      }
      mesh(stage, new T.TubeGeometry(new T.CatmullRomCurve3(pts), 240, 0.65, 8), mat(col, { roughness: 0.5 })).receiveShadow = false;
    });
    jumper(d.rxd, at([-10, 12.4, -3.8]), 22); jumper(d.txd, at([-10, 12.4, -1.26]), 29);
    label(at([2, -3, 16]), "dim").el.textContent = "CAN transceiver";
    label(far([30, 6, 22]), "dim").el.textContent = "another CAN node";
    const read = label(far([0, 36, 0]), "val");
    return (st) => { read.el.textContent = "node: " + st.say; nodeLed.material.emissiveIntensity = st.nodeDrives ? 3.2 : 0; };
  }

  /* --------------------------------------------------------------- camera */

  const camera = new T.PerspectiveCamera(30, 2, 10, 3000);
  let yaw = -0.34, pitch = 0.5, zoom = 1, target = new T.Vector3(), reach = 300, current = null, cursorNow = 0, updaters = [];

  function render() {
    const w = canvas.clientWidth, h = canvas.clientHeight;
    if (!w || !h) return;
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    if (canvas.width !== Math.round(w * dpr) || canvas.height !== Math.round(h * dpr)) { renderer.setPixelRatio(dpr); renderer.setSize(w, h, false); }
    camera.aspect = w / h;
    const dist = reach * zoom * Math.max(1, 1.55 / camera.aspect);
    camera.position.set(target.x + dist * Math.sin(yaw) * Math.cos(pitch), target.y + dist * Math.sin(pitch), target.z + dist * Math.cos(yaw) * Math.cos(pitch));
    camera.lookAt(target); camera.updateProjectionMatrix();
    renderer.render(world, camera);
    const v = new T.Vector3();
    for (const l of labels) {
      v.copy(l.pos).project(camera);
      l.el.style.display = v.z < 1 ? "" : "none";
      l.el.style.left = ((v.x + 1) / 2 * w).toFixed(1) + "px"; l.el.style.top = ((1 - v.y) / 2 * h).toFixed(1) + "px";
    }
  }

  function setScene(s) {
    if (stage) { world.remove(stage); stage.traverse((o) => { if (o.geometry) o.geometry.dispose(); }); }
    labelBox.textContent = ""; labels = []; wires = []; updaters = [];
    stage = new T.Group(); world.add(stage); current = s;
    const d = s.device;
    if (d.kind === "terminal") updaters.push(terminal(128, -14, d.pin));
    if (d.kind === "stepper") updaters.push(stepper(138, 4, d));
    if (d.kind === "servo") updaters.push(servo(128, 0, d.pin));
    if (d.kind === "lamp") updaters.push(lamp(112, 2, d.pin));
    if (d.kind === "sensor") updaters.push(sensor(122, -2, d));
    if (d.kind === "network") updaters.push(network(112, 8, d));
    if (d.kind === "canbus") updaters.push(canbus(108, 4, d));
    if (d.kind === "both") { updaters.push(terminal(118, -78, d.pin, -0.2)); updaters.push(stepper(144, 26, d)); }
    const pl = label(new T.Vector3(HEADER_X, BOARD.top + 46, pinZ(s.pins[0].pin)), "pins");
    pinTags = s.pins.map((p) => { const e = document.createElement("span"); e.textContent = "P" + p.pin + " " + p.name; pl.el.appendChild(e); return { pin: p.pin, e }; });
    const wide = d.kind === "both" || d.kind === "network" || d.kind === "canbus";
    target.set(wide ? 56 : 44, 12, wide ? -18 : 2); reach = wide ? 440 : 345;
    update(0);
  }

  function update(c) {
    if (!current) return;
    cursorNow = c;
    const st = deviceState(current, c);
    for (const u of updaters) u(st, current, c);
    for (const w of wires) w.m.emissiveIntensity = level(current, w.pin, c) ? 0.5 : 0;
    for (const t of pinTags) t.e.classList.toggle("high", level(current, t.pin, c) === 1);
    render();
  }

  let drag = null;
  canvas.addEventListener("pointerdown", (e) => { canvas.setPointerCapture(e.pointerId); drag = [e.clientX, e.clientY, yaw, pitch]; });
  canvas.addEventListener("pointermove", (e) => {
    if (!drag || !e.buttons) return;
    yaw = drag[2] - (e.clientX - drag[0]) * 0.007;
    pitch = Math.max(0.1, Math.min(1.45, drag[3] + (e.clientY - drag[1]) * 0.005)); render();
  });
  canvas.addEventListener("pointerup", () => { drag = null; });
  canvas.addEventListener("wheel", (e) => {
    if (!e.ctrlKey && !e.metaKey) return;                     // plain scrolling moves the page
    e.preventDefault(); zoom = Math.max(0.45, Math.min(1.6, zoom * Math.exp(e.deltaY * 0.004))); render();
  }, { passive: false });
  new ResizeObserver(render).observe(canvas);

  return { setScene, update, zoomBy: (k) => { zoom = Math.max(0.45, Math.min(1.6, zoom * k)); render(); } };
}
