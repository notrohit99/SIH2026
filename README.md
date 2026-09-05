# CITY trace – AI Vehicle Intelligence & GIS Traffic Analytics Platform

An AI-powered smart city traffic monitoring platform designed for real-time vehicle intelligence, license plate recognition (ANPR), multi-camera tracking, trajectory analytics, and GIS-based traffic congestion forecasting.

---

## 📌 System Architecture & Approach

The platform operates as a microservices architecture communicating via REST APIs:

```
                                 +-------------------------------------+
                                 |         Frontend Dashboard          |
                                 |   http://127.0.0.1:5500 (UI/GIS)    |
                                 +------------------+------------------+
                                                    |
               +------------------------------------+------------------------------------+
               |                                                                         |
               v (Video Uploads & Alerts)                                                v (Traffic Predictions & GIS)
+-------------------------------+                                         +-------------------------------+
|    Central Backend (:8005)    |                                         |     Traffic Service (:8003)   |
|   - API Gateway & Blacklist   |                                         |   - Spatio-Temporal GCN       |
|   - Routes to Integration     |                                         |   - 207 Sensor Nodes (METR-LA)|
+---------------+---------------+                                         +-------------------------------+
                |
                v
+-------------------------------+
|  Integration Service (:8002)  |
|  - Aggregates Tracks & OCR    |
+-------+---------------+-------+
        |               |
        v               v
+---------------+  +---------------+
| Tracking (:8001) | ANPR (:8000)  |
| YOLOv8 +         | YOLOv8 Plate +|
| ByteTrack        | PaddleOCR     |
+---------------+  +---------------+
```

### Core Technologies:
1. **Vehicle Detection & Tracking (Port 8001):**
   - **YOLOv8** identifies vehicle classes (cars, buses, trucks, motorcycles).
   - **ByteTrack** tracks vehicles across continuous frames and maintains unique IDs (`tracking_id`).
   - *Optimization:* Frame Stride = 2 and `imgsz=640` to halve CPU computation time without dropping tracking quality.
2. **Automated Number Plate Recognition (ANPR) (Port 8000):**
   - YOLOv8 plate detector crops high-resolution license plate patches.
   - **PaddleOCR** extracts alphanumeric characters with configurable confidence thresholds.
   - *Optimization:* Candidate cap & confidence early exit ($\ge 75\%$) prevents redundant inference on repeated frames.
3. **Integration Gateway (Port 8002):**
   - Cross-references track coordinates with OCR crops to generate structured JSON records.
4. **City Traffic Analytics & GIS Heatmap (Port 8003 & 5500/map.html):**
   - **ST-GCN (Spatial-Temporal Graph Convolutional Network)** predicts future highway speeds across 207 sensor nodes.
   - **Leaflet.js + Leaflet.heat** renders real-time color-coded congestion heatmaps and sensor markers.
5. **Real-time Alert System:**
   - Detects blacklisted license plates against security watchlists.
   - Identifies suspicious route anomalies (loitering, repetitive trajectories).

---

## 🚀 Quick Start (Running the System)

### 1. Master 1-Click Launch (Recommended)
Open PowerShell in the root directory (`e:\SIH2026`) and run:

```powershell
powershell -ExecutionPolicy Bypass -File .\run_all.ps1
```

This starts all microservices in the background, validates their health status, and launches the dashboard in your default browser:
* **Vehicle Intelligence Dashboard:** [http://127.0.0.1:5500](http://127.0.0.1:5500)
* **GIS Traffic & Heatmap Analytics:** [http://127.0.0.1:5500/map.html](http://127.0.0.1:5500/map.html)
* **Central API Docs:** [http://127.0.0.1:8005/docs](http://127.0.0.1:8005/docs)
* **Integration API Docs:** [http://127.0.0.1:8002/docs](http://127.0.0.1:8002/docs)

---

### 2. Stopping All Services
To cleanly shut down all running services and free all ports:

```powershell
powershell -ExecutionPolicy Bypass -File .\stop_all.ps1
```

---

### 3. Running Services Individually (Manual Mode)
If you want to view real-time logs in separate terminal tabs:

#### Terminal 1: ANPR Service (Port 8000)
```powershell
cd sih-vehicle-intelligence\services\anpr
.\.venv\Scripts\python.exe -m uvicorn app:app --host 127.0.0.1 --port 8000
```

#### Terminal 2: Tracking Service (Port 8001)
```powershell
cd sih-vehicle-intelligence\services\tracking
.\.venv\Scripts\python.exe -m uvicorn app:app --host 127.0.0.1 --port 8001
```

#### Terminal 3: Integration Service (Port 8002)
```powershell
cd sih-vehicle-intelligence\services\integration
.\.venv\Scripts\python.exe -m uvicorn app:app --host 127.0.0.1 --port 8002
```

#### Terminal 4: Traffic ST-GCN Service (Port 8003)
```powershell
cd sih-vehicle-intelligence\services\traffic
..\..\traffic-test\.venv\Scripts\python.exe -m uvicorn app:app --host 127.0.0.1 --port 8003
```

#### Terminal 5: Central Backend Gateway (Port 8005)
```powershell
cd sih-vehicle-intelligence\backend
.\.venv\Scripts\python.exe -m uvicorn app:app --host 127.0.0.1 --port 8005
```

#### Terminal 6: Frontend Web Server (Port 5500)
```powershell
cd sih-vehicle-intelligence\frontend
py -3.11 -m http.server 5500
```

---

## 📡 API Endpoints & Usage

### Process a Video
```bash
curl -X POST "http://127.0.0.1:8002/v1/process/video" \
     -F "file=@traffic_test.mp4" \
     -F "camera_id=CAM_01"
```

### Retrieve GIS Traffic Predictions
```bash
curl -X GET "http://127.0.0.1:8005/traffic/predict"
```

### Add a License Plate to Watchlist / Blacklist
```bash
curl -X POST "http://127.0.0.1:8005/blacklist" \
     -H "Content-Type: application/json" \
     -d '{"plate": "DL4CAB1234"}'
```

---

## 📂 Project Structure

```
SIH2026/
├── run_all.ps1                  # Master automated service runner
├── stop_all.ps1                 # Master graceful service stopper
├── .gitignore                   # Git ignore rules for models, venvs & media
├── sih-vehicle-intelligence/    # Core platform workspace
│   ├── backend/                 # Central API Gateway (:8005) & Blacklist store
│   ├── frontend/                # Interactive UI (:5500)
│   │   ├── index.html           # Main dashboard (Video, Table, Alerts, Stats)
│   │   ├── map.html             # GIS Traffic Heatmap & Sensor Analytics
│   │   ├── script.js            # Client-side state & API communication
│   │   └── style.css            # Dark/light theme styling & layout
│   └── services/                # Microservices
│       ├── anpr/                # License plate detection + PaddleOCR (:8000)
│       ├── tracking/            # YOLOv8 + ByteTrack vehicle tracking (:8001)
│       ├── integration/         # Orchestrator & vehicle record merger (:8002)
│       └── traffic/             # ST-GCN Spatio-Temporal prediction (:8003)
└── traffic-test/                # Dataset models & PyTorch environment
```

---

## 🌐 Deployment Guidelines (Vercel + Cloud)

* **Frontend (`sih-vehicle-intelligence/frontend`):**
  - Can be deployed directly to **Vercel** as a static site.
  - Simply import the `sih-vehicle-intelligence/frontend` folder on [Vercel](https://vercel.com).
* **Backend Microservices:**
  - Due to deep learning dependencies (OpenCV, PyTorch, YOLOv8, PaddleOCR), deploy the backend services on container platforms like **Render**, **Railway**, or an **AWS EC2** instance with Docker / Python 3.11.
  - Update `API_BASE` in `script.js` and `TRAFFIC_API` in `map.html` to point to your live cloud URL.
