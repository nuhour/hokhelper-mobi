import React, { useEffect, useRef, useState } from 'react';
import * as THREE from 'three';
import { CubeState } from '../types';
import { playCubeRotateTick, triggerHaptic } from '../utils/audio';

interface MagicCube3DProps {
  cubeState: CubeState;
  onStateChange: (state: CubeState) => void;
  onShakeComplete: () => void;
  onResourceError: () => void;
}

export const MagicCube3D: React.FC<MagicCube3DProps> = ({
  cubeState,
  onStateChange,
  onShakeComplete,
  onResourceError,
}) => {
  const containerRef = useRef<HTMLDivElement>(null);
  const rendererRef = useRef<THREE.WebGLRenderer | null>(null);
  const sceneRef = useRef<THREE.Scene | null>(null);
  const cameraRef = useRef<THREE.PerspectiveCamera | null>(null);
  const cubeGroupRef = useRef<THREE.Group | null>(null);
  const cubiesRef = useRef<THREE.Mesh[]>([]);
  const coreMeshRef = useRef<THREE.Mesh | null>(null);
  const particleSystemRef = useRef<THREE.Points | null>(null);
  const energyRingsRef = useRef<THREE.Group | null>(null);

  // Control state refs
  const isPointerDown = useRef(false);
  const pointerStart = useRef({ x: 0, y: 0 });
  const previousPointer = useRef({ x: 0, y: 0 });
  const angularVelocity = useRef({ x: 0.005, y: 0.008 });
  const targetCamDistance = useRef(6.2);
  const currentCamDistance = useRef(6.2);
  const isTwistingRef = useRef(false);
  const twistProgressRef = useRef(0);
  const lastTouchDistance = useRef<number | null>(null);
  const lastTapTime = useRef<number>(0);

  const [hoverTip, setHoverTip] = useState<string>('单指拖动旋转 · 双指缩放 · 双击复位');

  // Helper to generate HOK Emblem Texture on Canvas
  const createHokFaceTexture = () => {
    const canvas = document.createElement('canvas');
    canvas.width = 512;
    canvas.height = 512;
    const ctx = canvas.getContext('2d');
    if (!ctx) return new THREE.CanvasTexture(canvas);

    // Dark titanium metallic background with subtle radial highlight
    const bgGradient = ctx.createRadialGradient(256, 256, 20, 256, 256, 256);
    bgGradient.addColorStop(0, '#1e293b');
    bgGradient.addColorStop(0.7, '#0f172a');
    bgGradient.addColorStop(1, '#020617');
    ctx.fillStyle = bgGradient;
    ctx.fillRect(0, 0, 512, 512);

    // Gold Hextech Bevel Frame
    ctx.strokeStyle = '#f59e0b';
    ctx.lineWidth = 14;
    ctx.strokeRect(20, 20, 472, 472);

    ctx.strokeStyle = '#06b6d4';
    ctx.lineWidth = 4;
    ctx.strokeRect(36, 36, 440, 440);

    // Corner Hex Pattern
    const corners = [[50, 50], [462, 50], [50, 462], [462, 462]];
    ctx.fillStyle = '#06b6d4';
    corners.forEach(([cx, cy]) => {
      ctx.beginPath();
      ctx.arc(cx, cy, 10, 0, Math.PI * 2);
      ctx.fill();
    });

    // Center HOK Wings / Crown Emblem
    ctx.save();
    ctx.translate(256, 256);

    // Outer Glowing Ring
    ctx.beginPath();
    ctx.arc(0, 0, 140, 0, Math.PI * 2);
    ctx.strokeStyle = 'rgba(245, 158, 11, 0.4)';
    ctx.lineWidth = 8;
    ctx.stroke();

    ctx.beginPath();
    ctx.arc(0, 0, 110, 0, Math.PI * 2);
    ctx.strokeStyle = '#06b6d4';
    ctx.lineWidth = 6;
    ctx.stroke();

    // HOK Crown / Emblem Wings
    ctx.fillStyle = '#fbbf24';
    ctx.shadowColor = '#f59e0b';
    ctx.shadowBlur = 25;

    // Wing Left
    ctx.beginPath();
    ctx.moveTo(-20, -60);
    ctx.lineTo(-90, -100);
    ctx.lineTo(-70, 10);
    ctx.lineTo(-30, 40);
    ctx.closePath();
    ctx.fill();

    // Wing Right
    ctx.beginPath();
    ctx.moveTo(20, -60);
    ctx.lineTo(90, -100);
    ctx.lineTo(70, 10);
    ctx.lineTo(30, 40);
    ctx.closePath();
    ctx.fill();

    // Center Diamond
    ctx.fillStyle = '#38bdf8';
    ctx.shadowColor = '#0284c7';
    ctx.beginPath();
    ctx.moveTo(0, -70);
    ctx.lineTo(30, 0);
    ctx.lineTo(0, 70);
    ctx.lineTo(-30, 0);
    ctx.closePath();
    ctx.fill();

    ctx.restore();

    const texture = new THREE.CanvasTexture(canvas);
    texture.needsUpdate = true;
    return texture;
  };

  useEffect(() => {
    if (!containerRef.current) return;
    const width = containerRef.current.clientWidth || 360;
    const height = containerRef.current.clientHeight || 360;

    // Check WebGL availability
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

    // 1. Scene setup
    const scene = new THREE.Scene();
    sceneRef.current = scene;

    // 2. Camera setup - CG Focal Distance
    const camera = new THREE.PerspectiveCamera(45, width / height, 0.1, 100);
    camera.position.set(0, 1.2, 6.2);
    camera.lookAt(0, 0, 0);
    cameraRef.current = camera;

    // 3. Renderer with antialias and shadows
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
    } catch (e) {
      console.error('WebGL init error:', e);
      onResourceError();
      return;
    }

    // 4. CG Ambient & Rim Lighting
    const ambientLight = new THREE.AmbientLight(0x0f172a, 2.5);
    scene.add(ambientLight);

    // Directional Gold Sun
    const sunLight = new THREE.DirectionalLight(0xf59e0b, 3.5);
    sunLight.position.set(5, 8, 5);
    sunLight.castShadow = true;
    scene.add(sunLight);

    // Left Rim Cyan Light
    const leftRimLight = new THREE.PointLight(0x06b6d4, 8, 15);
    leftRimLight.position.set(-6, 2, 3);
    scene.add(leftRimLight);

    // Right Rim Purple Light
    const rightRimLight = new THREE.PointLight(0x8b5cf6, 6, 15);
    rightRimLight.position.set(6, -2, -3);
    scene.add(rightRimLight);

    // 5. Construct Magic Cube Group
    const mainGroup = new THREE.Group();
    scene.add(mainGroup);
    cubeGroupRef.current = mainGroup;

    // Textures & Materials
    const faceTexture = createHokFaceTexture();

    const metallicDarkMaterial = new THREE.MeshStandardMaterial({
      color: 0x0f172a,
      metalness: 0.85,
      roughness: 0.25,
      map: faceTexture,
    });

    const glowSeamMaterial = new THREE.MeshBasicMaterial({
      color: 0x06b6d4,
      wireframe: false,
    });

    const goldCornerMaterial = new THREE.MeshStandardMaterial({
      color: 0xf59e0b,
      metalness: 0.95,
      roughness: 0.15,
    });

    // Inner Glowing Core (Crystal Sphere)
    const coreGeometry = new THREE.SphereGeometry(0.85, 32, 32);
    const coreMaterial = new THREE.MeshStandardMaterial({
      color: 0x38bdf8,
      emissive: 0x0284c7,
      emissiveIntensity: 1.2,
      roughness: 0.1,
      metalness: 0.2,
      transparent: true,
      opacity: 0.85,
    });
    const coreMesh = new THREE.Mesh(coreGeometry, coreMaterial);
    mainGroup.add(coreMesh);
    coreMeshRef.current = coreMesh;

    // 3x3x3 Rubik Cubies Construction
    const cubies: THREE.Mesh[] = [];
    const size = 0.88;
    const gap = 0.06;
    const offset = size + gap;

    const cubieGeometry = new THREE.BoxGeometry(size, size, size);

    for (let x = -1; x <= 1; x++) {
      for (let y = -1; y <= 1; y++) {
        for (let z = -1; z <= 1; z++) {
          if (x === 0 && y === 0 && z === 0) continue; // skip core

          // Choose material per face/location for depth
          const isCorner = Math.abs(x) + Math.abs(y) + Math.abs(z) === 3;
          const mat = isCorner ? [
            goldCornerMaterial, metallicDarkMaterial,
            metallicDarkMaterial, metallicDarkMaterial,
            goldCornerMaterial, metallicDarkMaterial
          ] : metallicDarkMaterial;

          const cubie = new THREE.Mesh(cubieGeometry, mat);
          cubie.position.set(x * offset, y * offset, z * offset);
          cubie.userData = { origX: x, origY: y, origZ: z };
          cubie.castShadow = true;
          cubie.receiveShadow = true;

          // Inner energy seam outline
          const edges = new THREE.EdgesGeometry(cubieGeometry);
          const line = new THREE.LineSegments(edges, new THREE.LineBasicMaterial({ color: 0x06b6d4, linewidth: 1.5 }));
          cubie.add(line);

          mainGroup.add(cubie);
          cubies.push(cubie);
        }
      }
    }
    cubiesRef.current = cubies;

    // 6. Particle Energy Field Floating Around Cube
    const particleCount = 120;
    const particleGeometry = new THREE.BufferGeometry();
    const positions = new Float32Array(particleCount * 3);
    const colors = new Float32Array(particleCount * 3);

    for (let i = 0; i < particleCount; i++) {
      const radius = 2.5 + Math.random() * 3.5;
      const theta = Math.random() * Math.PI * 2;
      const phi = (Math.random() - 0.5) * Math.PI;

      positions[i * 3] = radius * Math.cos(phi) * Math.cos(theta);
      positions[i * 3 + 1] = radius * Math.sin(phi);
      positions[i * 3 + 2] = radius * Math.cos(phi) * Math.sin(theta);

      // Gold and Cyan mixed energy particles
      if (i % 2 === 0) {
        colors[i * 3] = 0.96; // R
        colors[i * 3 + 1] = 0.62; // G
        colors[i * 3 + 2] = 0.04; // B
      } else {
        colors[i * 3] = 0.02;
        colors[i * 3 + 1] = 0.71;
        colors[i * 3 + 2] = 0.83;
      }
    }

    particleGeometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
    particleGeometry.setAttribute('color', new THREE.BufferAttribute(colors, 3));

    const particleMaterial = new THREE.PointsMaterial({
      size: 0.09,
      vertexColors: true,
      transparent: true,
      opacity: 0.75,
      blending: THREE.AdditiveBlending,
    });

    const particleSystem = new THREE.Points(particleGeometry, particleMaterial);
    scene.add(particleSystem);
    particleSystemRef.current = particleSystem;

    // 7. Outer Energy Orbit Rings (CG Aesthetic)
    const energyRings = new THREE.Group();
    const ringMat = new THREE.MeshBasicMaterial({
      color: 0xf59e0b,
      side: THREE.DoubleSide,
      transparent: true,
      opacity: 0.35,
      wireframe: true,
    });
    const ringGeo = new THREE.TorusGeometry(2.4, 0.02, 16, 64);
    const ring1 = new THREE.Mesh(ringGeo, ringMat);
    ring1.rotation.x = Math.PI / 3;
    const ring2 = new THREE.Mesh(ringGeo, new THREE.MeshBasicMaterial({ color: 0x06b6d4, wireframe: true, transparent: true, opacity: 0.35 }));
    ring2.rotation.y = Math.PI / 4;

    energyRings.add(ring1);
    energyRings.add(ring2);
    scene.add(energyRings);
    energyRingsRef.current = energyRings;

    // Initial camera rotation angle
    mainGroup.rotation.x = 0.35;
    mainGroup.rotation.y = 0.6;

    // 8. Animation Loop
    let animationFrameId: number;

    const animate = () => {
      animationFrameId = requestAnimationFrame(animate);

      // Smooth camera zoom interpolation
      currentCamDistance.current += (targetCamDistance.current - currentCamDistance.current) * 0.08;
      if (cameraRef.current) {
        cameraRef.current.position.z = currentCamDistance.current;
      }

      // Rotate particle cloud & energy rings
      if (particleSystemRef.current) {
        particleSystemRef.current.rotation.y += 0.0015;
        particleSystemRef.current.rotation.x += 0.0008;
      }
      if (energyRingsRef.current) {
        energyRingsRef.current.rotation.z += 0.003;
        energyRingsRef.current.rotation.y -= 0.002;
      }

      // Pulse core crystal
      if (coreMeshRef.current) {
        const scale = 1 + Math.sin(Date.now() * 0.003) * 0.05;
        coreMeshRef.current.scale.set(scale, scale, scale);
      }

      // Handle States & Animations
      if (cubeGroupRef.current) {
        if (isTwistingRef.current) {
          // SHAKING / SPINNING CG State
          twistProgressRef.current += 0.02;

          // Rapid angular rotation
          cubeGroupRef.current.rotation.x += 0.12;
          cubeGroupRef.current.rotation.y += 0.18;
          cubeGroupRef.current.rotation.z += 0.08;

          // Explode/twist cubies outwards & back
          const explodeFactor = Math.sin(twistProgressRef.current * Math.PI) * 0.35;
          cubiesRef.current.forEach((cubie) => {
            const { origX, origY, origZ } = cubie.userData;
            cubie.position.set(
              origX * (0.94 + explodeFactor),
              origY * (0.94 + explodeFactor),
              origZ * (0.94 + explodeFactor)
            );
            cubie.rotation.x += 0.05 * origX;
            cubie.rotation.y += 0.05 * origY;
          });

          // End twist animation after ~2.2s
          if (twistProgressRef.current >= 1.0) {
            isTwistingRef.current = false;
            twistProgressRef.current = 0;

            // Reset cubies positions smoothly
            cubiesRef.current.forEach((cubie) => {
              const { origX, origY, origZ } = cubie.userData;
              cubie.position.set(origX * 0.94, origY * 0.94, origZ * 0.94);
              cubie.rotation.set(0, 0, 0);
            });

            onShakeComplete();
          }
        } else if (!isPointerDown.current) {
          // Inertia decay for drag or auto idle rotation
          cubeGroupRef.current.rotation.y += angularVelocity.current.y;
          cubeGroupRef.current.rotation.x += angularVelocity.current.x;

          // Friction slowdown
          angularVelocity.current.x *= 0.96;
          angularVelocity.current.y *= 0.96;

          // Maintain subtle idle rotation minimum
          if (Math.abs(angularVelocity.current.y) < 0.003) {
            angularVelocity.current.y = 0.003;
          }
        }
      }

      if (rendererRef.current && sceneRef.current && cameraRef.current) {
        rendererRef.current.render(sceneRef.current, cameraRef.current);
      }
    };

    animate();

    // Handle Resize
    const handleResize = () => {
      if (!containerRef.current || !rendererRef.current || !cameraRef.current) return;
      const nw = containerRef.current.clientWidth || 360;
      const nh = containerRef.current.clientHeight || 360;
      cameraRef.current.aspect = nw / nh;
      cameraRef.current.updateProjectionMatrix();
      rendererRef.current.setSize(nw, nh);
    };

    window.addEventListener('resize', handleResize);

    return () => {
      window.removeEventListener('resize', handleResize);
      cancelAnimationFrame(animationFrameId);
      if (rendererRef.current && rendererRef.current.domElement) {
        rendererRef.current.domElement.remove();
        rendererRef.current.dispose();
      }
    };
  }, [onResourceError]);

  // Trigger SHAKE / SPIN action when state transitions to SHAKING or AUTO_ROTATING
  useEffect(() => {
    if (cubeState === 'SHAKING') {
      isTwistingRef.current = true;
      twistProgressRef.current = 0;
      angularVelocity.current = { x: 0.1, y: 0.15 };
      setHoverTip('方舟魔方极速运转中，正在凝聚峡谷胜局运势...');
      triggerHaptic([30, 50, 40, 80, 50, 100]);
    } else if (cubeState === 'AUTO_ROTATING') {
      angularVelocity.current = { x: 0.02, y: 0.08 };
      setTimeout(() => {
        if (cubeState === 'AUTO_ROTATING') {
          onStateChange('INITIAL');
        }
      }, 2500);
    } else if (cubeState === 'DRAGGING') {
      setHoverTip('按住并拖动旋转视角');
    } else if (cubeState === 'INITIAL') {
      setHoverTip('单指拖动旋转 · 双指缩放 · 双击复位');
    }
  }, [cubeState, onStateChange]);

  // Touch and Mouse Event Handlers
  const handlePointerDown = (clientX: number, clientY: number) => {
    isPointerDown.current = true;
    pointerStart.current = { x: clientX, y: clientY };
    previousPointer.current = { x: clientX, y: clientY };

    if (cubeState !== 'SHAKING' && cubeState !== 'RESULT_REVEALED') {
      onStateChange('DRAGGING');
    }
  };

  const handlePointerMove = (clientX: number, clientY: number) => {
    if (!isPointerDown.current || !cubeGroupRef.current) return;

    const deltaX = clientX - previousPointer.current.x;
    const deltaY = clientY - previousPointer.current.y;

    const sensitivity = 0.008;
    cubeGroupRef.current.rotation.y += deltaX * sensitivity;
    cubeGroupRef.current.rotation.x += deltaY * sensitivity;

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

  // Zoom Handler (Mouse Wheel or Pinch)
  const handleWheel = (e: React.WheelEvent) => {
    e.preventDefault();
    const zoomDelta = e.deltaY * 0.003;
    targetCamDistance.current = Math.min(Math.max(targetCamDistance.current + zoomDelta, 4.2), 9.5);
  };

  // Double Tap Reset
  const handleDoubleTapReset = () => {
    targetCamDistance.current = 6.2;
    if (cubeGroupRef.current) {
      cubeGroupRef.current.rotation.x = 0.35;
      cubeGroupRef.current.rotation.y = 0.6;
      cubeGroupRef.current.rotation.z = 0;
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

      // Check double tap
      const now = Date.now();
      if (now - lastTapTime.current < 300) {
        handleDoubleTapReset();
      }
      lastTapTime.current = now;
    } else if (e.touches.length === 2) {
      // Pinch Zoom start
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
      // Pinch distance check
      const dist = Math.hypot(
        e.touches[0].clientX - e.touches[1].clientX,
        e.touches[0].clientY - e.touches[1].clientY
      );
      const delta = (lastTouchDistance.current - dist) * 0.01;
      targetCamDistance.current = Math.min(Math.max(targetCamDistance.current + delta, 4.2), 9.5);
      lastTouchDistance.current = dist;
    }
  };

  const handleTouchEnd = () => {
    lastTouchDistance.current = null;
    handlePointerUp();
  };

  return (
    <div className="relative w-full aspect-square max-w-[420px] mx-auto flex flex-col items-center justify-center select-none touch-none">
      {/* Background CG Radial Glow Effect */}
      <div className="absolute inset-0 pointer-events-none flex items-center justify-center">
        <div className="w-[85%] h-[85%] rounded-full bg-gradient-to-tr from-cyan-500/15 via-amber-500/20 to-purple-600/15 blur-3xl animate-pulse" />
        <div className="absolute w-[60%] h-[60%] rounded-full border border-amber-500/20 animate-spin" style={{ animationDuration: '24s' }} />
        <div className="absolute w-[75%] h-[75%] rounded-full border border-cyan-500/15 animate-spin" style={{ animationDuration: '36s', animationDirection: 'reverse' }} />
      </div>

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

      {/* Interactive Helper Overlay Tip */}
      <div className="absolute bottom-1 z-20 px-3 py-1.5 rounded-full bg-slate-900/80 backdrop-blur-md border border-amber-500/30 text-amber-300 text-xs font-medium tracking-wide shadow-lg flex items-center gap-1.5 pointer-events-none">
        <span className="w-2 h-2 rounded-full bg-cyan-400 animate-ping" />
        <span>{hoverTip}</span>
      </div>
    </div>
  );
};
