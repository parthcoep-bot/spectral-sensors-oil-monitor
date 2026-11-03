# TAKUMI-TYPE: Smart Multi-Spectral Oil Condition Monitor

### COEP Technological University, Pune | Department of Metallurgical Engineering
**B.Tech Mini-Project Thesis (Academic Year 2024–2025)**

---

### 🌐 Live Public Telemetry Web Portal
**Access the live dashboard worldwide:**  
👉 **[https://parthcoep-bot.github.io/spectral-sensors-oil-monitor/](https://parthcoep-bot.github.io/spectral-sensors-oil-monitor/)**

---

### 👤 Candidate Information
* **Researcher:** Parth Ramesh Shinde
* **MIS:** 642511003
* **Department:** Department of Metallurgical Engineering, COEP Technological University, Pune
* **Degree:** Bachelor of Technology in Metallurgical Engineering

---

### 🎯 Curriculum Domain Alignment
**Topic:** *Development of Phase Change Material for Thermal Energy Storage for Hybrid PVT System*

#### **Engineering Context & Utility:**
In hybrid Photovoltaic-Thermal (PVT) solar systems coupled to Phase Change Material (PCM) thermal storage, circulating thermal oils/heat-transfer fluids extract waste heat from solar panels and transfer it to latent-heat PCM storage tanks. Continuous operating thermal cycles (60°C to 120°C) drive **thermo-oxidative degradation, carbon soot/sludge buildup, and pump abrasive wear debris**, which fouls heat exchangers and reduces heat transfer coefficients by 35–45%.

**TAKUMI-TYPE** provides continuous, in-situ, multi-parameter fluid health monitoring directly inside active circulation lines:
1. **TSL25911 Dual-Channel Optical Sensor (Visible + NIR):** $CH1/CH0$ spectral ratio serves as an optical proxy for **ASTM E2412** oxidation (carbonyl formation), while broadband lux attenuation quantifies soot/sludge.
2. **DS18B20 Digital Temperature Sensor:** Precision ±0.5°C thermal tracking with real-time temperature compensation factor $tc = 1 + 0.006 	imes (T - 25)$.
3. **SS49E Linear Hall Effect Sensor:** Rare-earth biased magnetic deflection detecting ferromagnetic wear debris ($Fe$) from pumps and pipe walls.

---

### 📊 Repository Contents
* `index.html`: Responsive HTML5/Canvas real-time web telemetry portal with 60 FPS live charting and scenario simulator.
* `OilDashboard_Final.m`: Standalone desktop control system built with MATLAB App Designer.
* `MINI_PROJECT_REPORT.md`: Comprehensive 8-chapter technical report.
* `SPECTRAL_SENSORS_MINI_PROJECT_REPORT_COEP.docx`: Formal university report conforming to COEP guidelines.
