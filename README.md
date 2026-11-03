# FIT3182 Assignment 2 & 3 — AWAS Traffic Monitoring Pipeline

**Students:** 34392009 | 34099484  
**Unit:** FIT3182 Big Data Management and Processing — Semester 1, 2026  
**Due:** 12 June 2026

---

## Overview

This assignment implements an end-to-end Automated Awareness Safety System (AWAS)
traffic monitoring pipeline using Apache Kafka, Apache Spark Structured Streaming,
and MongoDB. The system detects instantaneous and average speed violations from
simulated roadside camera events and stores them for real-time visualisation.

---

## Project Structure

```
34392009_34099484_assignment03/
├── README.md
├── src/
│   ├── 34392009_34099484_producer_a.ipynb
│   ├── 34392009_34099484_producer_b.ipynb
│   ├── 34392009_34099484_producer_c.ipynb
│   ├── 34392009_34099484_data_design_streaming.ipynb
│   ├── 34392009_34099484_visualisation.ipynb
│   ├── biht_flowchart.png
│   ├── performance_analysis_nonincremental.py
│   ├── performance_analysis_incremental.py
│   └── app.py
├── data/
│   ├── vehicle.csv
│   ├── camera.csv
│   ├── camera_event_A.csv
│   ├── camera_event_B.csv
│   └── camera_event_C.csv
├── deployment/
│   └── scripts/
│        ├── start-containers.ps1
│        ├── start-containers.sh
│        ├── start-dashboard.ps1
│        └── start-dashboard.sh
├── requirements.txt
├── technical_presentation_slides.pdf
├── video_recording.mp4
└── research_articles/
    ├── cache.pdf
    ├── asynchronous-incremental-maintenance.pdf
    ├── hotel-dashboard.pdf
    ├── incremental-query-processing.pdf
    ├── incremental-view-maintenance.pdf
    ├── sales-dashboard.pdf
    └── scalable-data-views.pdf
```

---

## Dependencies

### Docker & Jupyter Notebooks

The Docker container fit3182/pyspark should have most of the dependencies required to run the Jupyter notebooks. The only Python library that needs to be installed is `folium`.

Do `pip install folium` in the Jupyter notebook.

### Venv & Streamlit Dashboard + Performance Analysis

All dependencies needed to run the dashboard `app.py` and performance analysis scripts (`performance_analysis_nonincremental.py` + `performance_analysis_incremental.py`) can be found in `requirements.txt`.

---

## Setup

It is assumed you have PowerShell.

### Docker & Jupyter Notebooks

Assuming you are in the root folder for the project, run the `start-containers` script in the `deployment/scripts` folder. I.e. `.\deployment\scripts\start-containers.ps1`. 

This script runs the docker containers: fit3182/pyspark, fit3182/kafka, fit3182/mongo, and fit3182/zookeeper. It sets up the environment needed to run the Jupyter notebooks. 

Open the link to the Jupyter notebooks or `http://localhost:8888`. It is recommended to set a password. This way, you can restart the pyspark container by running the command `docker start pyspark` to access the Jupyter notebooks again after stopping the container.

### Venv & Streamlit Dashboard + Performance Analysis

#### Streamlit Dashboard

Open another terminal. Also assuming you are in the root folder for the project, run the `start-dashboard` script in the `deployment/scripts` folder. I.e. `.\deployment\scripts\start-dashboard.ps1`. 

This script creates a venv virtual environment, install the dependencies in requirements.txt, and start the Streamlit dashboard. Open the link to the Streamlit dashboard. The charts will only be shown when the data stream is active.

To access the Streamlit dashboard again, activate venv then run the command `streamlit run .\src\app.py`. 

#### Performance Analysis

Open another terminal in the root folder for the project. Assuming the `start-dashboard` script had been run, activate venv. I.e. run the command `.\venv\Scripts\Activate.ps1`. Run the performance analysis scripts to do performance analysis on non-incremental querying (`performance_analysis_nonincremental.py`) and incremental querying (`performance_analysis_incremental.py`). Performance can only be analyzed when the data stream is active.

## Running Order for Jupyter Notebooks

### Step 1 — Start Streaming Application

Open `34392009_34099484_data_design_streaming.ipynb`, run all cells from
top to bottom in order. The final cell starts the BiHT streaming query:

```python
query = (
    shared_stream.writeStream
    .foreachBatch(process_batch_with_biht)
    .outputMode("append")
    .option("checkpointLocation", "checkpoint_biht_awas")
    .start()
)
query.awaitTermination()
```

The streaming query will print batch-level output showing events
processed, violations detected, and MongoDB write results.

To stop the query, interrupt the kernel and run:
```python
query.stop()
```

### Step 2 — Start Kafka Producers

Open each producer notebook in a separate browser tab and run all cells:

| Notebook | Camera | Topic |
|---|---|---|
| `34392009_34099484_producer_a.ipynb` | Camera 1 | `camera_events` |
| `34392009_34099484_producer_b.ipynb` | Camera 2 | `camera_events` |
| `34392009_34099484_producer_c.ipynb` | Camera 3 | `camera_events` |

All three producers publish to the shared Kafka topic `camera_events`.
Each message includes a `producer_id` field (`A`, `B`, or `C`) for
source identification in Spark.

Producers can be started before or after the streaming notebook — the
streaming notebook uses `startingOffsets="latest"` so producers and
Spark should run concurrently for best results.

**Producer batch delay:**
```python
BATCH_DELAY = 0.01  # seconds — adjust to control replay speed
```

### Step 3 — Run Visualisations (Optional) - This is Assignment 2, Not the Dashboard for Assignment 3!

Open `34392009_34099484_visualisation.ipynb` in a separate browser tab
while the streaming query is running. As stated above, you will need to 
install `folium` before you proceed. Do `pip install folium`. Then, run 
all function definition cells first. After that, run the dashboard loop cell:

```python
# Real-time dashboard — refreshes every REFRESH_INTERVAL seconds
REFRESH_INTERVAL = 5
while True:
    df = query_violations()
    # plots update automatically
    time.sleep(REFRESH_INTERVAL)
```

The Folium map cell can be run separately at any time to generate an
interactive HTML map saved to `violation_map.html`.

### Step 4 — Reset State (Required before next fresh run)

In `34392009_34099484_data_design_streaming.ipynb`, run the
**Reset** cell at the bottom of the notebook:

```python
import shutil
shutil.rmtree("checkpoint_biht_awas", ignore_errors=True)
violations_col.delete_many({})
biht.clear()
event_buffers.clear()
dropped_log.clear()
written_event_ids.clear()
producer_latest_times.clear()
```

This clears the Spark checkpoint, MongoDB violations collection, and all
in-memory BiHT state. The checkpoint and MongoDB must always be cleared
together — clearing one without the other will cause offset mismatches.

---

# AI Declaration

Generative AI tools were used during the development of this assignment in accordance with the unit's academic integrity guidelines.

## Tools Used

| Tool | Purpose |
| ---- | ---- |
| Claude (Anthropic) | Dashboard development, code generation, debugging, data visualisation design, performance analysis |
| ChatGPT (OpenAI)   | Dashboard development, architecture design, code generation, documentation writing, performance analysis |

## Usage Summary

AI assistance was used for the following purposes:

### Dashboard Development

* Developing the Streamlit dashboard structure and layout
* Generating and refining dashboard components and user interface elements
* Implementing interactive filtering features, including filtering by date, camera, vehicle type, violation type, and severity level
* Designing dashboard navigation and user interaction workflows
* Improving the readability and organisation of visualisations and analytics outputs

### Data Visualisation

* Suggesting additional charts and analytical visualisations to better represent traffic violation patterns
* Assisting with Plotly chart configuration, formatting, labelling, and styling
* Assisting with Folium map visualisation and camera network representation
* Providing recommendations for KPI metrics and dashboard analytics

### Performance Analysis and Optimisation

* Developing scripts to measure dashboard performance and query execution times
* Analysing MongoDB query efficiency and incremental querying approaches
* Providing recommendations for caching strategies, session state management, and data refresh mechanisms
* Assisting with performance benchmarking and monitoring scripts

### Environment Setup and Reproducibility

* Generating scripts for environment setup and configuration
* Assisting with Docker container configuration and execution
* Creating virtual environment setup scripts and dependency installation procedures
* Providing guidance for reproducible deployment and execution of the project

### Code Debugging and Development Support

* Identifying and resolving implementation issues within the Streamlit dashboard
* Assisting with MongoDB integration and query logic
* Debugging data processing and visualisation issues
* Improving code structure, comments, and documentation
* Reviewing implementation approaches and suggesting improvements

### Documentation and Architecture Design

* Assisting with the creation of architecture diagrams and system design documentation
* Drafting technical explanations for implementation decisions
* Improving documentation clarity and readability
* Supporting the preparation of project reports and presentation materials

## Prompt Summary

Prompts used included:

* "How can I implement interactive filtering in a Streamlit dashboard?"
* "Suggest additional visualisations for traffic violation analysis."
* "How can I optimise MongoDB queries for real-time dashboard updates?"
* "Generate scripts for environment setup and reproducibility."
* "Create an architecture diagram for the Kafka–Spark–MongoDB–Streamlit pipeline."
* "Help debug Plotly, Streamlit, and Folium visualisation issues."
* "Review dashboard performance and suggest optimisation techniques."
* "Write technical documentation and implementation explanations."

All AI-generated content was reviewed, modified, tested, and validated by the author before submission. The final implementation decisions, code integration, testing, and evaluation were performed by the author.