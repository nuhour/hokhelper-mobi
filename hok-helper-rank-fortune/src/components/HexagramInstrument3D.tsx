import React, { useEffect, useRef, useState } from 'react';
import * as THREE from 'three';
import { Sparkles, ChevronRight, RotateCcw, X } from 'lucide-react';
import { CubeState, FortuneResult } from '../types';
import { playCubeRotateTick, triggerHaptic } from '../utils/audio';

interface HexagramInstrument3DProps {
  cubeState: CubeState;
  embedded?: boolean;
  fortuneResult?: FortuneResult | null;
  onStateChange: (state: CubeState) => void;
  onShakeComplete: () => void;
  onResourceError: () => void;
  onOpenDetailModal?: () => void;
  onReroll?: () => void;
  onCloseResult?: () => void;
}

export const HexagramInstrument3D: React.FC<HexagramInstrument3DProps> = ({
  cubeState,
  embedded = false,
  fortuneResult,
  onStateChange,
  onShakeComplete,
  onResourceError,
  onOpenDetailModal,
  onReroll,
  onCloseResult,
}) => {
  const containerRef = useRef<HTMLDivElement>(null);
  const rendererRef = useRef<THREE.WebGLRenderer | null>(null);
  const sceneRef = useRef<THREE.Scene | null>(null);
  const cameraRef = useRef<THREE.PerspectiveCamera | null>(null);

  // Group & Mesh refs for independent multi-axis rotation
  const mainGroupRef = useRef<THREE.Group | null>(null);
  const outerFrameRef = useRef<THREE.Group | null>(null);
  const silverGimbalRef = useRef<THREE.Mesh | null>(null);
  const redGimbalRef = useRef<THREE.Mesh | null>(null);
  const glassCoreRef = useRef<THREE.Mesh | null>(null);
  const innerNebulaRef = useRef<THREE.Mesh | null>(null);
  const energyVortexRef = useRef<THREE.Mesh | null>(null);
  const flameParticlesRef = useRef<THREE.Points | null>(null);

  // Levitation Field refs
  const levitationRuneDiscRef = useRef<THREE.Mesh | null>(null);
  const levitationBeamRef = useRef<THREE.Mesh | null>(null);
  const manaParticlesRef = useRef<THREE.Points | null>(null);
  const manaParticleGeoRef = useRef<THREE.BufferGeometry | null>(null);

  // Mana Swirl Vortex Streams around Hexagram Instrument (法力汇流跟随旋转)
  const manaSwirlGroupRef = useRef<THREE.Group | null>(null);
  const manaSwirlGroup2Ref = useRef<THREE.Group | null>(null);
  const manaSwirlMatRef = useRef<THREE.PointsMaterial | null>(null);

  // Asymmetric Light refs
  const coreLight1Ref = useRef<THREE.PointLight | null>(null);
  const coreLight2Ref = useRef<THREE.PointLight | null>(null);

  // Interaction & Animation refs
  const isPointerDown = useRef(false);
  const pointerStart = useRef({ x: 0, y: 0 });
  const previousPointer = useRef({ x: 0, y: 0 });
  const angularVelocity = useRef({ x: 0.003, y: 0.006 });
  const targetCamDistance = useRef(6.2);
  const currentCamDistance = useRef(6.2);

  const isSpinningRef = useRef(false);
  const spinProgressRef = useRef(0);
  const lastTouchDistance = useRef<number | null>(null);
  const lastTapTime = useRef<number>(0);

  const [hoverTip, setHoverTip] = useState<string>('玄法悬空 · 拖动旋转 · 双指缩放');

  // --- 1. Texture Generator Helpers ---

  // Bagua Trigrams (☰ ☱ ☲ ☳ ☴ ☵ ☶ ☷) and Runes
  const createTrigramTexture = (index: number) => {
    const canvas = document.createElement('canvas');
    canvas.width = 256;
    canvas.height = 256;
    const ctx = canvas.getContext('2d');
    if (!ctx) return new THREE.CanvasTexture(canvas);

    // Silver metallic gradient background
    const grad = ctx.createLinearGradient(0, 0, 256, 256);
    grad.addColorStop(0, '#f1f5f9');
    grad.addColorStop(0.5, '#cbd5e1');
    grad.addColorStop(1, '#64748b');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, 256, 256);

    ctx.strokeStyle = '#334155';
    ctx.lineWidth = 8;
    ctx.strokeRect(6, 6, 244, 244);

    const trigrams = [
      [[1,1,1]], // ☰ 乾
      [[1,1,0]], // ☱ 兑
      [[1,0,1]], // ☲ 离
      [[1,0,0]], // ☳ 震
      [[0,1,1]], // ☴ 巽
      [[0,1,0]], // ☵ 坎
      [[0,0,1]], // ☶ 艮
      [[0,0,0]], // ☷ 坤
    ];

    const lines = trigrams[index % 8][0];
    ctx.fillStyle = '#020617';

    lines.forEach((lineType, lIdx) => {
      const y = 60 + lIdx * 45;
      if (lineType === 1) {
        ctx.fillRect(45, y, 166, 22);
      } else {
        ctx.fillRect(45, y, 72, 22);
        ctx.fillRect(139, y, 72, 22);
      }
    });

    ctx.fillStyle = '#dc2626';
    ctx.font = 'bold 50px serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    const runes = ['S', '☯', '☥', 'C', 'S', '☯', '☥', 'C'];
    ctx.fillText(runes[index % 8], 128, 205);

    const texture = new THREE.CanvasTexture(canvas);
    texture.needsUpdate = true;
    return texture;
  };

  // Spiral Node Texture
  const createSpiralNodeTexture = () => {
    const canvas = document.createElement('canvas');
    canvas.width = 256;
    canvas.height = 256;
    const ctx = canvas.getContext('2d');
    if (!ctx) return new THREE.CanvasTexture(canvas);

    ctx.fillStyle = '#991b1b';
    ctx.fillRect(0, 0, 256, 256);

    ctx.strokeStyle = '#f8fafc';
    ctx.lineWidth = 20;
    ctx.lineCap = 'round';
    ctx.beginPath();
    for (let i = 0; i < 4 * Math.PI; i += 0.1) {
      const r = 10 + i * 12;
      const x = 128 + r * Math.cos(i);
      const y = 128 + r * Math.sin(i);
      if (i === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    }
    ctx.stroke();

    const texture = new THREE.CanvasTexture(canvas);
    texture.needsUpdate = true;
    return texture;
  };

  // Non-uniform Multi-gradient Inner Sphere Texture (非均匀多重渐变与多彩光晕)
  const createNonUniformSphereTexture = () => {
    const canvas = document.createElement('canvas');
    canvas.width = 512;
    canvas.height = 512;
    const ctx = canvas.getContext('2d');
    if (!ctx) return new THREE.CanvasTexture(canvas);

    // Deep cosmic violet background
    ctx.fillStyle = '#1e1b4b';
    ctx.fillRect(0, 0, 512, 512);

    // Asymmetric Radial Light Spot 1: Hot Magenta/Rose Core (Top Right)
    const rad1 = ctx.createRadialGradient(340, 160, 10, 340, 160, 260);
    rad1.addColorStop(0, '#fb7185');
    rad1.addColorStop(0.35, '#e11d48');
    rad1.addColorStop(0.7, '#881337');
    rad1.addColorStop(1, 'transparent');
    ctx.fillStyle = rad1;
    ctx.fillRect(0, 0, 512, 512);

    // Asymmetric Radial Light Spot 2: Solar Gold Flare (Bottom Left)
    const rad2 = ctx.createRadialGradient(160, 360, 5, 160, 360, 200);
    rad2.addColorStop(0, '#fef08a');
    rad2.addColorStop(0.4, '#f59e0b');
    rad2.addColorStop(0.8, '#b45309');
    rad2.addColorStop(1, 'transparent');
    ctx.fillStyle = rad2;
    ctx.fillRect(0, 0, 512, 512);

    // Asymmetric Radial Light Spot 3: Cyan Spell Halo (Top Left)
    const rad3 = ctx.createRadialGradient(140, 120, 10, 140, 120, 180);
    rad3.addColorStop(0, '#67e8f9');
    rad3.addColorStop(0.5, '#0284c7');
    rad3.addColorStop(1, 'transparent');
    ctx.fillStyle = rad3;
    ctx.fillRect(0, 0, 512, 512);

    // Organic Energy Nebula Swirl Arms
    ctx.save();
    ctx.translate(256, 256);
    ctx.rotate(0.4);

    for (let arm = 0; arm < 5; arm++) {
      ctx.rotate((Math.PI * 2) / 5);
      ctx.strokeStyle = arm % 2 === 0 ? 'rgba(253, 224, 71, 0.85)' : 'rgba(244, 63, 94, 0.85)';
      ctx.lineWidth = 12 + arm * 3;
      ctx.shadowColor = arm % 2 === 0 ? '#f59e0b' : '#f43f5e';
      ctx.shadowBlur = 25;

      ctx.beginPath();
      for (let i = 0; i < 2.5 * Math.PI; i += 0.08) {
        const r = 8 + i * 26 + (arm * 8);
        const x = r * Math.cos(i);
        const y = r * Math.sin(i);
        if (i === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
      ctx.stroke();
    }
    ctx.restore();

    const texture = new THREE.CanvasTexture(canvas);
    texture.needsUpdate = true;
    return texture;
  };

  // Levitation Magic Rune Circle Texture (法力悬空符阵)
  const createRuneDiscTexture = () => {
    const canvas = document.createElement('canvas');
    canvas.width = 512;
    canvas.height = 512;
    const ctx = canvas.getContext('2d');
    if (!ctx) return new THREE.CanvasTexture(canvas);

    ctx.clearRect(0, 0, 512, 512);

    // Glowing outer ring
    ctx.strokeStyle = '#06b6d4';
    ctx.lineWidth = 10;
    ctx.shadowColor = '#0284c7';
    ctx.shadowBlur = 20;
    ctx.beginPath();
    ctx.arc(256, 256, 220, 0, Math.PI * 2);
    ctx.stroke();

    // Inner dashed ring
    ctx.strokeStyle = '#f43f5e';
    ctx.lineWidth = 6;
    ctx.shadowColor = '#f43f5e';
    ctx.shadowBlur = 15;
    ctx.setLineDash([18, 12]);
    ctx.beginPath();
    ctx.arc(256, 256, 180, 0, Math.PI * 2);
    ctx.stroke();
    ctx.setLineDash([]);

    // Central Hexagram (六芒星)
    ctx.strokeStyle = '#fbbf24';
    ctx.lineWidth = 8;
    ctx.shadowColor = '#f59e0b';
    ctx.shadowBlur = 20;

    const drawTriangle = (angleOffset: number) => {
      ctx.beginPath();
      for (let i = 0; i < 3; i++) {
        const angle = angleOffset + (i * Math.PI * 2) / 3;
        const x = 256 + 150 * Math.cos(angle);
        const y = 256 + 150 * Math.sin(angle);
        if (i === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
      ctx.closePath();
      ctx.stroke();
    };

    drawTriangle(-Math.PI / 2);
    drawTriangle(Math.PI / 2);

    // Ancient Rune symbols around the circumference
    ctx.fillStyle = '#38bdf8';
    ctx.font = 'bold 36px serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    const runeChars = ['☰', '☱', '☲', '☳', '☴', '☵', '☶', '☷', '☯', '☥', '卍', '✦'];
    runeChars.forEach((char, idx) => {
      const angle = (idx * Math.PI * 2) / runeChars.length;
      const x = 256 + 200 * Math.cos(angle);
      const y = 256 + 200 * Math.sin(angle);
      ctx.fillText(char, x, y);
    });

    const texture = new THREE.CanvasTexture(canvas);
    texture.needsUpdate = true;
    return texture;
  };

  // --- 2. Main Three.js Initialization ---
  useEffect(() => {
    if (!containerRef.current) return;
    const width = containerRef.current.clientWidth || 360;
    const height = containerRef.current.clientHeight || 360;

    try {
      const testCanvas = document.createElement('canvas');
      const gl = testCanvas.getContext('webgl') || testCanvas.getContext('experimental-webgl');
      if (!gl) {
        onResourceError();
        return;
      }
    } catch {
      onResourceError();
      return;
    }

    const scene = new THREE.Scene();
    sceneRef.current = scene;

    const camera = new THREE.PerspectiveCamera(45, width / height, 0.1, 100);
    const aspect = width / height;
    const baseDist = embedded ? 8.2 : 7.0;
    const initialDist = aspect < 0.85 ? Math.min(10.2, Math.max(7.6, baseDist * (0.85 / aspect))) : baseDist;
    camera.position.set(0, 0.15, initialDist);
    camera.lookAt(0, -0.2, 0);
    cameraRef.current = camera;
    targetCamDistance.current = initialDist;

    let renderer: THREE.WebGLRenderer;
    try {
      renderer = new THREE.WebGLRenderer({
        antialias: true,
        alpha: true,
        powerPreference: 'high-performance',
      });
      renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
      renderer.setSize(width, height);
      renderer.shadowMap.enabled = true;
      renderer.shadowMap.type = THREE.PCFSoftShadowMap;
      containerRef.current.appendChild(renderer.domElement);
      rendererRef.current = renderer;
    } catch {
      onResourceError();
      return;
    }

    // Lighting Setup
    const ambientLight = new THREE.AmbientLight(0x1e1b4b, 2.5);
    scene.add(ambientLight);

    const silverSun = new THREE.DirectionalLight(0xf8fafc, 3.0);
    silverSun.position.set(6, 8, 5);
    silverSun.castShadow = true;
    scene.add(silverSun);

    // Asymmetric Inner Sphere Point Lights (多重非对称极光灯)
    const coreLight1 = new THREE.PointLight(0xf43f5e, 14, 10);
    coreLight1.position.set(0.4, 0.3, 0.2);
    scene.add(coreLight1);
    coreLight1Ref.current = coreLight1;

    const coreLight2 = new THREE.PointLight(0xf59e0b, 10, 10);
    coreLight2.position.set(-0.35, -0.25, -0.15);
    scene.add(coreLight2);
    coreLight2Ref.current = coreLight2;

    const rimLight = new THREE.PointLight(0x06b6d4, 8, 12);
    rimLight.position.set(-6, -4, 3);
    scene.add(rimLight);

    // Root Instrument Floating Group
    const mainGroup = new THREE.Group();
    mainGroup.position.set(0, 0.3, 0); // Hovering above hand
    scene.add(mainGroup);
    mainGroupRef.current = mainGroup;

    // Shared Materials
    const spiralTexture = createSpiralNodeTexture();
    const nodeMaterial = new THREE.MeshStandardMaterial({
      map: spiralTexture,
      metalness: 0.7,
      roughness: 0.2,
    });

    const silverMetalMaterial = new THREE.MeshStandardMaterial({
      color: 0xe2e8f0,
      metalness: 0.9,
      roughness: 0.15,
    });

    const redLacqueredMaterial = new THREE.MeshStandardMaterial({
      color: 0xbe123c,
      metalness: 0.7,
      roughness: 0.2,
      emissive: 0x881337,
      emissiveIntensity: 0.3,
    });

    // --- A. Outer Octagonal Frame ---
    const outerFrame = new THREE.Group();
    mainGroup.add(outerFrame);
    outerFrameRef.current = outerFrame;

    const numSegments = 8;
    const outerRadius = 2.15;

    for (let i = 0; i < numSegments; i++) {
      const angle1 = (i * Math.PI * 2) / numSegments;
      const angle2 = ((i + 1) * Math.PI * 2) / numSegments;
      const midAngle = (angle1 + angle2) / 2;

      const segmentGeo = new THREE.BoxGeometry(1.4, 0.36, 0.28);
      const trigramMat = new THREE.MeshStandardMaterial({
        map: createTrigramTexture(i),
        metalness: 0.85,
        roughness: 0.2,
      });

      const segmentMesh = new THREE.Mesh(segmentGeo, trigramMat);
      segmentMesh.position.set(
        Math.cos(midAngle) * outerRadius,
        Math.sin(midAngle) * outerRadius,
        0
      );
      segmentMesh.rotation.z = midAngle + Math.PI / 2;
      segmentMesh.castShadow = true;
      segmentMesh.receiveShadow = true;

      outerFrame.add(segmentMesh);

      if (i % 2 === 0) {
        const knobGeo = new THREE.CylinderGeometry(0.24, 0.24, 0.22, 24);
        const knobMesh = new THREE.Mesh(knobGeo, nodeMaterial);
        knobMesh.position.set(
          Math.cos(angle1) * (outerRadius + 0.12),
          Math.sin(angle1) * (outerRadius + 0.12),
          0
        );
        knobMesh.rotation.x = Math.PI / 2;
        knobMesh.castShadow = true;
        outerFrame.add(knobMesh);
      }
    }

    // --- B. Gimbal Rings ---
    const silverRingGeo = new THREE.TorusGeometry(1.72, 0.08, 16, 64);
    const silverRing = new THREE.Mesh(silverRingGeo, silverMetalMaterial);
    silverRing.rotation.x = Math.PI / 4;
    silverRing.castShadow = true;
    mainGroup.add(silverRing);
    silverGimbalRef.current = silverRing;

    const redRingGeo = new THREE.TorusGeometry(1.58, 0.07, 16, 64);
    const redRing = new THREE.Mesh(redRingGeo, redLacqueredMaterial);
    redRing.rotation.y = Math.PI / 2 + Math.PI / 6;
    redRing.castShadow = true;
    mainGroup.add(redRing);
    redGimbalRef.current = redRing;

    // --- C. Glass Core & Non-Uniform Inner Nebulae Shell ---
    // Outer Crystalline Glass Shell
    const outerGlassGeo = new THREE.SphereGeometry(1.32, 48, 48);
    const glassMaterial = new THREE.MeshPhysicalMaterial({
      color: 0xf43f5e,
      emissive: 0x9f1239,
      emissiveIntensity: 0.4,
      roughness: 0.08,
      metalness: 0.1,
      transmission: 0.82,
      thickness: 0.9,
      ior: 1.52,
      transparent: true,
      opacity: 0.75,
    });

    const glassSphere = new THREE.Mesh(outerGlassGeo, glassMaterial);
    mainGroup.add(glassSphere);
    glassCoreRef.current = glassSphere;

    // Inner Non-Uniform Gradient Nebulae Shell (非对称多彩光晕内球)
    const innerNebulaGeo = new THREE.SphereGeometry(1.15, 36, 36);
    const nonUniformTex = createNonUniformSphereTexture();
    const nebulaMaterial = new THREE.MeshBasicMaterial({
      map: nonUniformTex,
      transparent: true,
      opacity: 0.88,
      blending: THREE.AdditiveBlending,
      side: THREE.DoubleSide,
    });

    const innerNebula = new THREE.Mesh(innerNebulaGeo, nebulaMaterial);
    mainGroup.add(innerNebula);
    innerNebulaRef.current = innerNebula;

    // Swirling Vortex Core
    const vortexGeo = new THREE.PlaneGeometry(2.0, 2.0);
    const vortexMat = new THREE.MeshBasicMaterial({
      map: nonUniformTex,
      transparent: true,
      opacity: 0.85,
      blending: THREE.AdditiveBlending,
      side: THREE.DoubleSide,
    });
    const energyVortex = new THREE.Mesh(vortexGeo, vortexMat);
    mainGroup.add(energyVortex);
    energyVortexRef.current = energyVortex;

    // Magical Flame Particles
    const particleCount = 240;
    const particleGeo = new THREE.BufferGeometry();
    const pPositions = new Float32Array(particleCount * 3);
    const pColors = new Float32Array(particleCount * 3);

    for (let i = 0; i < particleCount; i++) {
      const radius = 1.2 + Math.random() * 2.0;
      const theta = Math.random() * Math.PI * 2;
      const phi = (Math.random() - 0.5) * Math.PI;

      pPositions[i * 3] = radius * Math.cos(phi) * Math.cos(theta);
      pPositions[i * 3 + 1] = radius * Math.sin(phi);
      pPositions[i * 3 + 2] = radius * Math.cos(phi) * Math.sin(theta);

      if (i % 3 === 0) {
        pColors[i * 3] = 0.98; pColors[i * 3 + 1] = 0.25; pColors[i * 3 + 2] = 0.37;
      } else if (i % 3 === 1) {
        pColors[i * 3] = 0.95; pColors[i * 3 + 1] = 0.85; pColors[i * 3 + 2] = 0.15;
      } else {
        pColors[i * 3] = 0.22; pColors[i * 3 + 1] = 0.74; pColors[i * 3 + 2] = 0.96;
      }
    }

    particleGeo.setAttribute('position', new THREE.BufferAttribute(pPositions, 3));
    particleGeo.setAttribute('color', new THREE.BufferAttribute(pColors, 3));

    const particleMaterial = new THREE.PointsMaterial({
      size: 0.1,
      vertexColors: true,
      transparent: true,
      opacity: 0.85,
      blending: THREE.AdditiveBlending,
    });

    const flameParticles = new THREE.Points(particleGeo, particleMaterial);
    scene.add(flameParticles);
    flameParticlesRef.current = flameParticles;

    // --- E. Levitation Magic Aura Field (法力悬空光阵) ---
    // Floating Magic Rune Disc between Hand & Instrument
    const runeTex = createRuneDiscTexture();
    const runeDiscGeo = new THREE.PlaneGeometry(2.6, 2.6);
    const runeDiscMat = new THREE.MeshBasicMaterial({
      map: runeTex,
      transparent: true,
      opacity: 0.85,
      blending: THREE.AdditiveBlending,
      side: THREE.DoubleSide,
    });

    const runeDisc = new THREE.Mesh(runeDiscGeo, runeDiscMat);
    runeDisc.position.set(0, -1.25, 0.1);
    runeDisc.rotation.x = Math.PI / 2 - 0.2; // Tilted slightly towards camera
    scene.add(runeDisc);
    levitationRuneDiscRef.current = runeDisc;

    // Upward Floating Mana Particles (法力能量微粒升腾)
    const manaCount = 90;
    const manaGeo = new THREE.BufferGeometry();
    const mPositions = new Float32Array(manaCount * 3);
    const mVelocities = new Float32Array(manaCount);

    for (let i = 0; i < manaCount; i++) {
      mPositions[i * 3] = (Math.random() - 0.5) * 1.5;
      mPositions[i * 3 + 1] = -2.1 + Math.random() * 1.8;
      mPositions[i * 3 + 2] = (Math.random() - 0.5) * 1.5;
      mVelocities[i] = 0.01 + Math.random() * 0.02;
    }

    manaGeo.setAttribute('position', new THREE.BufferAttribute(mPositions, 3));
    manaParticleGeoRef.current = manaGeo;

    const manaMat = new THREE.PointsMaterial({
      color: 0x38bdf8,
      size: 0.09,
      transparent: true,
      opacity: 0.9,
      blending: THREE.AdditiveBlending,
    });

    const manaParticles = new THREE.Points(manaGeo, manaMat);
    scene.add(manaParticles);
    manaParticlesRef.current = manaParticles;

    // --- F. Mana Swirl Vortex Stream Surrounding Instrument (抽签过程法力汇流旋转) ---
    const swirlGroup1 = new THREE.Group();
    const swirlGroup2 = new THREE.Group();
    scene.add(swirlGroup1);
    scene.add(swirlGroup2);
    manaSwirlGroupRef.current = swirlGroup1;
    manaSwirlGroup2Ref.current = swirlGroup2;

    const swirlParticleCount = 320;
    const swirlGeo1 = new THREE.BufferGeometry();
    const swirlGeo2 = new THREE.BufferGeometry();

    const sPos1 = new Float32Array(swirlParticleCount * 3);
    const sColors1 = new Float32Array(swirlParticleCount * 3);
    const sPos2 = new Float32Array(swirlParticleCount * 3);
    const sColors2 = new Float32Array(swirlParticleCount * 3);

    for (let i = 0; i < swirlParticleCount; i++) {
      const angle1 = (i / swirlParticleCount) * Math.PI * 6;
      const radius1 = 2.0 + Math.sin(angle1 * 3) * 0.25;
      const height1 = (Math.random() - 0.5) * 2.2;

      sPos1[i * 3] = Math.cos(angle1) * radius1;
      sPos1[i * 3 + 1] = height1;
      sPos1[i * 3 + 2] = Math.sin(angle1) * radius1;

      // Vibrant Amber / Gold Energy
      sColors1[i * 3] = 0.98;
      sColors1[i * 3 + 1] = 0.75 + Math.random() * 0.25;
      sColors1[i * 3 + 2] = 0.15;

      const angle2 = (i / swirlParticleCount) * Math.PI * 6 + Math.PI;
      const radius2 = 2.4 + Math.cos(angle2 * 2) * 0.3;
      const height2 = (Math.random() - 0.5) * 2.4;

      sPos2[i * 3] = Math.cos(angle2) * radius2;
      sPos2[i * 3 + 1] = height2;
      sPos2[i * 3 + 2] = Math.sin(angle2) * radius2;

      // Cyan / Rose Spell Power Energy
      if (i % 2 === 0) {
        sColors2[i * 3] = 0.95;
        sColors2[i * 3 + 1] = 0.25;
        sColors2[i * 3 + 2] = 0.45;
      } else {
        sColors2[i * 3] = 0.15;
        sColors2[i * 3 + 1] = 0.82;
        sColors2[i * 3 + 2] = 0.98;
      }
    }

    swirlGeo1.setAttribute('position', new THREE.BufferAttribute(sPos1, 3));
    swirlGeo1.setAttribute('color', new THREE.BufferAttribute(sColors1, 3));

    swirlGeo2.setAttribute('position', new THREE.BufferAttribute(sPos2, 3));
    swirlGeo2.setAttribute('color', new THREE.BufferAttribute(sColors2, 3));

    const swirlMat = new THREE.PointsMaterial({
      size: 0.11,
      vertexColors: true,
      transparent: true,
      opacity: 0.8,
      blending: THREE.AdditiveBlending,
    });
    manaSwirlMatRef.current = swirlMat;

    const swirlPoints1 = new THREE.Points(swirlGeo1, swirlMat);
    const swirlPoints2 = new THREE.Points(swirlGeo2, swirlMat);

    swirlGroup1.add(swirlPoints1);
    swirlGroup2.add(swirlPoints2);

    // Initial angle
    mainGroup.rotation.x = 0.2;
    mainGroup.rotation.y = 0.4;

    // --- 3. Render Animation Loop ---
    let animId: number;

    const animate = () => {
      animId = requestAnimationFrame(animate);

      const time = Date.now() * 0.002;

      // Smooth camera distance zoom
      currentCamDistance.current += (targetCamDistance.current - currentCamDistance.current) * 0.08;
      if (cameraRef.current) {
        cameraRef.current.position.z = currentCamDistance.current;
      }

      // 1. Levitation Rune Disc Spin & Energy Pulse
      if (levitationRuneDiscRef.current) {
        levitationRuneDiscRef.current.rotation.z += isSpinningRef.current ? 0.08 : 0.012;
      }

      if (levitationBeamRef.current) {
        const beamPulse = 0.3 + Math.sin(time * 2.5) * 0.12 + (isSpinningRef.current ? 0.3 : 0);
        (levitationBeamRef.current.material as THREE.MeshBasicMaterial).opacity = beamPulse;
      }

      // 3. Upward Mana Particles Levitation Animation
      if (manaParticleGeoRef.current) {
        const positions = manaParticleGeoRef.current.attributes.position.array as Float32Array;
        for (let i = 0; i < manaCount; i++) {
          positions[i * 3 + 1] += 0.015; // Move up towards instrument
          if (positions[i * 3 + 1] > -0.2) {
            positions[i * 3 + 1] = -2.1; // Reset to palm level
            positions[i * 3] = (Math.random() - 0.5) * 1.4;
            positions[i * 3 + 2] = (Math.random() - 0.5) * 1.4;
          }
        }
        manaParticleGeoRef.current.attributes.position.needsUpdate = true;
      }

      // 4. Mana Swirl Streams Rotating Around Instrument (法力汇流跟随旋转效果)
      if (manaSwirlGroupRef.current && manaSwirlGroup2Ref.current) {
        if (isSpinningRef.current) {
          const progress = Math.min(spinProgressRef.current, 1.0);
          const easeOut = Math.pow(1 - progress, 2.0);

          // Fast swirling mana streams surrounding the instrument
          manaSwirlGroupRef.current.rotation.y += 0.28 * easeOut + 0.05;
          manaSwirlGroupRef.current.rotation.x = Math.sin(time * 6) * 0.15;

          manaSwirlGroup2Ref.current.rotation.y -= 0.22 * easeOut + 0.04;
          manaSwirlGroup2Ref.current.rotation.z = Math.cos(time * 5) * 0.12;

          if (manaSwirlMatRef.current) {
            manaSwirlMatRef.current.opacity = 0.95;
            manaSwirlMatRef.current.size = 0.14 + Math.sin(time * 12) * 0.03;
          }
        } else {
          manaSwirlGroupRef.current.rotation.y += 0.012;
          manaSwirlGroup2Ref.current.rotation.y -= 0.009;

          if (manaSwirlMatRef.current) {
            manaSwirlMatRef.current.opacity = 0.45;
            manaSwirlMatRef.current.size = 0.09;
          }
        }
      }

      // 5. Non-Uniform Inner Nebulae & Swirl Rotations
      if (innerNebulaRef.current) {
        innerNebulaRef.current.rotation.y += 0.008;
        innerNebulaRef.current.rotation.z += 0.004;
      }

      if (energyVortexRef.current) {
        energyVortexRef.current.rotation.z += isSpinningRef.current ? 0.12 : 0.015;
      }

      if (flameParticlesRef.current) {
        flameParticlesRef.current.rotation.y += isSpinningRef.current ? 0.04 : 0.003;
        flameParticlesRef.current.rotation.x += isSpinningRef.current ? 0.02 : 0.001;
      }

      // 5. Asymmetric Inner Light Oscillations (Dynamic Halos & Gradients)
      if (coreLight1Ref.current && coreLight2Ref.current) {
        coreLight1Ref.current.position.x = 0.4 + Math.sin(time * 1.5) * 0.2;
        coreLight1Ref.current.position.y = 0.3 + Math.cos(time * 2.1) * 0.2;
        coreLight1Ref.current.intensity = (isSpinningRef.current ? 24 : 14) + Math.sin(time * 3.0) * 4;

        coreLight2Ref.current.position.x = -0.35 + Math.cos(time * 1.8) * 0.2;
        coreLight2Ref.current.position.z = -0.15 + Math.sin(time * 2.4) * 0.2;
        coreLight2Ref.current.intensity = (isSpinningRef.current ? 18 : 10) + Math.cos(time * 2.5) * 3;
      }

      // 6. Handle States & Spinning Animation
      if (mainGroupRef.current) {
        // Floating motion for main instrument above hand
        mainGroupRef.current.position.y = 0.3 + Math.sin(time * 1.2 + 0.5) * 0.06;

        if (isSpinningRef.current) {
          // Increment spin progress
          spinProgressRef.current += 0.0085; // ~2.2s spin duration
          const progress = Math.min(spinProgressRef.current, 1.0);

          // Ease-Out Cubic curve: starts high, smoothly decays to 0.0
          const easeOut = Math.pow(1 - progress, 2.5);

          // Speed decays smoothly from fast to zero
          const spinSpeedY = 0.32 * easeOut;
          const spinSpeedX = 0.16 * easeOut;

          mainGroupRef.current.rotation.y += spinSpeedY;
          mainGroupRef.current.rotation.x += spinSpeedX;

          if (outerFrameRef.current) {
            outerFrameRef.current.rotation.z -= 0.30 * easeOut;
          }

          if (silverGimbalRef.current) {
            silverGimbalRef.current.rotation.x += 0.35 * easeOut;
            silverGimbalRef.current.rotation.y += 0.20 * easeOut;
          }

          if (redGimbalRef.current) {
            redGimbalRef.current.rotation.y -= 0.42 * easeOut;
            redGimbalRef.current.rotation.z += 0.25 * easeOut;
          }

          if (glassCoreRef.current) {
            const scale = 1 + Math.sin(progress * Math.PI * 6) * 0.14 * easeOut;
            glassCoreRef.current.scale.set(scale, scale, scale);
          }

          if (spinProgressRef.current >= 1.0) {
            isSpinningRef.current = false;
            spinProgressRef.current = 0;

            if (glassCoreRef.current) {
              glassCoreRef.current.scale.set(1, 1, 1);
            }
            onShakeComplete();
          }
        } else {
          if (!isPointerDown.current) {
            mainGroupRef.current.rotation.y += angularVelocity.current.y;
            mainGroupRef.current.rotation.x += angularVelocity.current.x;

            angularVelocity.current.x *= 0.96;
            angularVelocity.current.y *= 0.96;

            if (Math.abs(angularVelocity.current.y) < 0.003) {
              angularVelocity.current.y = 0.003;
            }
          }

          if (silverGimbalRef.current) silverGimbalRef.current.rotation.z += 0.008;
          if (redGimbalRef.current) redGimbalRef.current.rotation.x += 0.012;
          if (outerFrameRef.current) outerFrameRef.current.rotation.z -= 0.004;
        }
      }

      // Smooth camera Z distance transition
      if (cameraRef.current) {
        const curZ = cameraRef.current.position.z;
        if (Math.abs(curZ - targetCamDistance.current) > 0.002) {
          cameraRef.current.position.z += (targetCamDistance.current - curZ) * 0.08;
        }
      }

      if (rendererRef.current && sceneRef.current && cameraRef.current) {
        rendererRef.current.render(sceneRef.current, cameraRef.current);
      }
    };

    animate();

    const handleResize = () => {
      if (!containerRef.current || !rendererRef.current || !cameraRef.current) return;
      const nw = containerRef.current.clientWidth || 360;
      const nh = containerRef.current.clientHeight || 360;
      const asp = nw / nh;
      cameraRef.current.aspect = asp;
      cameraRef.current.updateProjectionMatrix();
      rendererRef.current.setSize(nw, nh);

      const baseDist = embedded ? 8.2 : 7.0;
      const fitDist = asp < 0.85 ? Math.min(10.2, Math.max(7.6, baseDist * (0.85 / asp))) : baseDist;
      targetCamDistance.current = fitDist;
    };

    window.addEventListener('resize', handleResize);

    return () => {
      window.removeEventListener('resize', handleResize);
      cancelAnimationFrame(animId);
      if (rendererRef.current && rendererRef.current.domElement) {
        rendererRef.current.domElement.remove();
        rendererRef.current.dispose();
      }
    };
  }, [embedded, onResourceError]);

  // Handle state transitions
  useEffect(() => {
    if (cubeState === 'SHAKING') {
      isSpinningRef.current = true;
      spinProgressRef.current = 0;
      angularVelocity.current = { x: 0.1, y: 0.15 };
      setHoverTip('玄法凝聚 · 卦象仪与黑铠手套法力共鸣');
      triggerHaptic([30, 60, 40, 90, 60, 120]);
    } else if (cubeState === 'AUTO_ROTATING') {
      angularVelocity.current = { x: 0.015, y: 0.06 };
      setTimeout(() => {
        if (cubeState === 'AUTO_ROTATING') {
          onStateChange('INITIAL');
        }
      }, 2500);
    } else if (cubeState === 'DRAGGING') {
      setHoverTip('拖动旋转卦象仪视角');
    } else if (cubeState === 'INITIAL') {
      setHoverTip('玄法悬空 · 拖动旋转 · 双指缩放');
    }
  }, [cubeState, onStateChange]);

  // Mouse & Touch Controls
  const handlePointerDown = (clientX: number, clientY: number) => {
    isPointerDown.current = true;
    pointerStart.current = { x: clientX, y: clientY };
    previousPointer.current = { x: clientX, y: clientY };

    if (cubeState !== 'SHAKING' && cubeState !== 'RESULT_REVEALED') {
      onStateChange('DRAGGING');
    }
  };

  const handlePointerMove = (clientX: number, clientY: number) => {
    if (!isPointerDown.current || !mainGroupRef.current) return;

    const deltaX = clientX - previousPointer.current.x;
    const deltaY = clientY - previousPointer.current.y;

    const sensitivity = 0.008;
    mainGroupRef.current.rotation.y += deltaX * sensitivity;
    mainGroupRef.current.rotation.x += deltaY * sensitivity;

    angularVelocity.current = {
      x: deltaY * sensitivity * 0.5,
      y: deltaX * sensitivity * 0.5,
    };

    if (Math.abs(deltaX) > 2 || Math.abs(deltaY) > 2) {
      playCubeRotateTick();
    }

    previousPointer.current = { x: clientX, y: clientY };
  };

  const handlePointerUp = () => {
    if (isPointerDown.current) {
      isPointerDown.current = false;
      if (cubeState === 'DRAGGING') {
        onStateChange('INITIAL');
      }
    }
  };

  const handleWheel = (e: React.WheelEvent) => {
    e.preventDefault();
    const zoomDelta = e.deltaY * 0.003;
    targetCamDistance.current = Math.min(Math.max(targetCamDistance.current + zoomDelta, 4.0), 9.0);
  };

  const handleDoubleTapReset = () => {
    targetCamDistance.current = 6.2;
    if (mainGroupRef.current) {
      mainGroupRef.current.rotation.x = 0.2;
      mainGroupRef.current.rotation.y = 0.4;
      mainGroupRef.current.rotation.z = 0;
    }
    angularVelocity.current = { x: 0, y: 0.004 };
    triggerHaptic([20, 20]);
    setHoverTip('视角已重置为默认视角');
  };

  const handleMouseDown = (e: React.MouseEvent) => handlePointerDown(e.clientX, e.clientY);
  const handleMouseMove = (e: React.MouseEvent) => handlePointerMove(e.clientX, e.clientY);
  const handleMouseUp = () => handlePointerUp();

  const handleTouchStart = (e: React.TouchEvent) => {
    if (e.touches.length === 1) {
      const touch = e.touches[0];
      handlePointerDown(touch.clientX, touch.clientY);

      const now = Date.now();
      if (now - lastTapTime.current < 300) {
        handleDoubleTapReset();
      }
      lastTapTime.current = now;
    } else if (e.touches.length === 2) {
      const dist = Math.hypot(
        e.touches[0].clientX - e.touches[1].clientX,
        e.touches[0].clientY - e.touches[1].clientY
      );
      lastTouchDistance.current = dist;
    }
  };

  const handleTouchMove = (e: React.TouchEvent) => {
    if (e.touches.length === 1) {
      const touch = e.touches[0];
      handlePointerMove(touch.clientX, touch.clientY);
    } else if (e.touches.length === 2 && lastTouchDistance.current !== null) {
      const dist = Math.hypot(
        e.touches[0].clientX - e.touches[1].clientX,
        e.touches[0].clientY - e.touches[1].clientY
      );
      const delta = (lastTouchDistance.current - dist) * 0.01;
      targetCamDistance.current = Math.min(Math.max(targetCamDistance.current + delta, 4.0), 9.0);
      lastTouchDistance.current = dist;
    }
  };

  const handleTouchEnd = () => {
    lastTouchDistance.current = null;
    handlePointerUp();
  };

  return (
    <div className="fixed inset-0 w-full h-full flex flex-col items-center justify-center select-none touch-none z-0 overflow-hidden">
      {/* Background CG Radial Glow Effect */}
      {!embedded && <div className="absolute inset-0 pointer-events-none flex items-center justify-center z-0">
        <div className="w-[85%] h-[85%] max-w-[650px] max-h-[650px] rounded-full bg-gradient-to-tr from-rose-500/20 via-pink-600/25 to-amber-500/15 blur-3xl animate-pulse" />
        <div className="absolute w-[62%] h-[62%] max-w-[450px] max-h-[450px] rounded-full border border-rose-500/30 animate-spin" style={{ animationDuration: '20s' }} />
        <div className="absolute w-[78%] h-[78%] max-w-[550px] max-h-[550px] rounded-full border border-cyan-500/20 animate-spin" style={{ animationDuration: '30s', animationDirection: 'reverse' }} />
      </div>}

      {/* 3D WebGL Canvas Container */}
      <div
        ref={containerRef}
        className="w-full h-full cursor-grab active:cursor-grabbing z-10"
        onMouseDown={handleMouseDown}
        onMouseMove={handleMouseMove}
        onMouseUp={handleMouseUp}
        onMouseLeave={handleMouseUp}
        onWheel={handleWheel}
        onDoubleClick={handleDoubleTapReset}
        onTouchStart={handleTouchStart}
        onTouchMove={handleTouchMove}
        onTouchEnd={handleTouchEnd}
      />

      {/* Unfolding Fortune Scroll Banner on Top of 3D Hexagram Instrument */}
      {!embedded && cubeState === 'RESULT_REVEALED' && fortuneResult && (
        <div className="absolute top-2 left-2 right-2 z-30 pointer-events-auto flex flex-col items-center animate-unfold-scroll">
          <div className="w-full max-w-[380px] bg-gradient-to-b from-amber-950/85 via-red-950/85 to-slate-950/90 border-2 border-amber-400/80 rounded-2xl p-4 shadow-2xl shadow-rose-950/80 backdrop-blur-xl relative overflow-hidden animate-float-glow">
            {/* Top Right Explicit Close Button */}
            <button
              onClick={() => {
                if (onCloseResult) onCloseResult();
                else onStateChange('AUTO_ROTATING');
              }}
              className="absolute top-2 right-2 z-20 p-1.5 rounded-full bg-slate-900/80 text-amber-300/80 hover:text-amber-200 hover:bg-slate-800 transition-all cursor-pointer border border-amber-500/40 shadow-md"
              title="关闭出签面板"
            >
              <X className="w-4 h-4" />
            </button>

            {/* Scroll Decorative Corners */}
            <div className="absolute top-1.5 left-2.5 text-amber-400/60 text-xs font-serif">☯</div>
            <div className="absolute bottom-1.5 left-2.5 text-amber-400/60 text-xs font-serif">✦</div>
            <div className="absolute bottom-1.5 right-2.5 text-amber-400/60 text-xs font-serif">✦</div>

            {/* Gold Ribbon Tag */}
            <div className="text-center mb-1.5 pr-6">
              <span className="px-3 py-0.5 rounded-full bg-gradient-to-r from-amber-500 via-rose-500 to-amber-600 text-slate-950 text-[11px] font-black tracking-widest uppercase shadow-md inline-flex items-center gap-1">
                <Sparkles className="w-3 h-3 text-slate-950" />
                <span>{fortuneResult.luckTier} · 卦象出签</span>
              </span>
            </div>

            {/* Fortune Index Score (签运值) */}
            <div className="flex items-center justify-center gap-2 my-1">
              <span className="text-amber-200 text-xs font-bold tracking-wider">签运指数</span>
              <span className="text-3xl font-black text-transparent bg-clip-text bg-gradient-to-r from-yellow-300 via-amber-200 to-rose-300 drop-shadow-[0_2px_10px_rgba(245,158,11,0.6)]">
                {fortuneResult.luckScore}
              </span>
              <span className="text-amber-300 text-xs font-extrabold">分</span>
            </div>

            {/* Slogan Advice ("今日宜上分 · 顺风无敌") */}
            <div className="text-center my-2 px-1">
              <p className="text-rose-100 text-xs sm:text-sm font-bold tracking-wide leading-relaxed bg-rose-900/40 border border-rose-500/30 rounded-xl py-2 px-3 shadow-inner">
                ✨ “{fortuneResult.summary || '今日宜上分 · 顺风无敌'}”
              </p>
            </div>

            {/* Banner Buttons */}
            <div className="flex items-center justify-center gap-2 mt-2.5 pt-2 border-t border-amber-500/20 text-xs flex-wrap">
              {onOpenDetailModal && (
                <button
                  onClick={onOpenDetailModal}
                  className="px-3.5 py-1.5 rounded-xl bg-gradient-to-r from-amber-500 to-rose-500 hover:from-amber-400 hover:to-rose-400 text-slate-950 font-black shadow-lg shadow-amber-500/25 active:scale-95 transition-transform flex items-center gap-1 cursor-pointer"
                >
                  <span>查看排位详解</span>
                  <ChevronRight className="w-3.5 h-3.5" />
                </button>
              )}
              {onReroll && (
                <button
                  onClick={onReroll}
                  className="px-2.5 py-1.5 rounded-xl bg-slate-900/90 hover:bg-slate-800 text-amber-200 border border-amber-500/30 font-semibold active:scale-95 transition-transform flex items-center gap-1 cursor-pointer"
                >
                  <RotateCcw className="w-3.5 h-3.5 text-amber-400" />
                  <span>再摇一签</span>
                </button>
              )}
              <button
                onClick={() => {
                  if (onCloseResult) onCloseResult();
                  else onStateChange('AUTO_ROTATING');
                }}
                className="px-2.5 py-1.5 rounded-xl bg-slate-950/80 hover:bg-slate-900 text-slate-300 border border-slate-700 font-semibold active:scale-95 transition-transform flex items-center gap-1 cursor-pointer"
                title="收起出签面板"
              >
                <X className="w-3.5 h-3.5 text-rose-400" />
                <span>收起</span>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Interactive Helper Overlay Tip */}
      {!embedded && <div className="absolute bottom-1 z-20 px-3.5 py-1.5 rounded-full bg-slate-900/85 backdrop-blur-md border border-rose-500/40 text-rose-200 text-xs font-medium tracking-wide shadow-lg flex items-center gap-2 pointer-events-none">
        <span className="w-2 h-2 rounded-full bg-rose-400 animate-ping" />
        <span>{hoverTip}</span>
      </div>}
    </div>
  );
};
