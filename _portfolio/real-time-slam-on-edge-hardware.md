---
title: "Real-time visual SLAM on edge hardware"
excerpt: "A state-of-the-art SLAM pipeline taken from 0.26 to 2.4 FPS on a Jetson Orin NX — a ~9× speedup under strict power and compute limits."
collection: portfolio
order: 1
result: "9× faster inference"
tags: [TensorRT, ONNX, Jetson Orin NX, PyTorch]
---

**Context** — A drone analytics team needed visual SLAM for trajectory tracking, running on the aircraft rather than in the cloud.

**Problem** — MASt3R-SLAM produces excellent reconstructions, but at 0.26 FPS on the target board it was unusable for real-time flight. The usual answers — a smaller model, or a bigger board — were both unavailable: accuracy was the reason they chose the pipeline, and the compute and power budget was fixed by the airframe. Published optimisation guidance assumes server GPUs and stops being useful at the edge.

**Approach** — Two lines of attack. First, systematic inference optimisation for the Jetson Orin NX: ONNX export and TensorRT compilation, precision tuning, and removing host-to-device transfer stalls from the hot path. Second, an algorithmic change — adaptive retrieval, which raises the threshold for relocalisation during drone turns, exactly when candidate frames are least informative and the backend is doing the most redundant work.

**Result** — Roughly 9× faster inference, from 0.26 to 2.4 FPS, on unchanged hardware and with reconstruction quality intact. The optimisation sequence generalised into a playbook now applied to other models targeting constrained devices.

**Stack** — Jetson Orin NX · PyTorch · TensorRT · ONNX · CUDA · OpenCV
