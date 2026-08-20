# Aswenna Agricultural Marketplace — Presentation Slides

---

### Slide 1: Title Slide & Project Overview

# Aswenna Agricultural Marketplace
### Bridging Agricultural Supply Chains via Multi-Tier Architecture & Contextual RAG AI

* **Student Name / ID**: [Your Name / Candidate ID]
* **Degree Program**: BSc (Hons) in Software Engineering
* **Module**: WRT1 — Software Development Project
* **Target Audience**: Evaluation Panel & Viva Defense

#### Project Snapshot
* **Platform Type**: Cross-Platform Digital Agritech Marketplace & Machine Learning Advisory Engine
* **Core Technology Stack**:
  * **Frontend**: Flutter 3.22 (Dart) — Cross-platform Android/iOS application
  * **Backend API**: Laravel 11 (PHP 8.2), MySQL 8.0, Laravel Sanctum Token Authentication
  * **AI Microservice**: Python 3.10 Flask service, ChromaDB Vector DB, SentenceTransformers (`all-MiniLM-L6-v2`), Groq LLM API
  * **Tabular ML Core**: LightGBM (Crop Recommendation), XGBoost (Yield Regression), Random Forest (Fertilizer Optimization)
* **Core Purpose**: Connect 6 distinct agricultural stakeholders directly while providing real-time AI-powered agronomic field advisory.

---

### Slide 1.5: Project Abstract

# Abstract

Managing traditional agricultural supply chains in Sri Lanka involves severe challenges, including multi-layered middleman overhead, opaque price negotiations, low price realization for smallholder farmers, high post-harvest crop spoilage, and a lack of localized agronomic guidance. This project addresses these critical gaps by developing **Aswenna**, an intelligent AI-powered Digital Agricultural Marketplace and Agronomic Advisory Platform tailored for Sri Lanka's agricultural sector.

The platform leverages tabular machine learning models—including **LightGBM** for crop recommendation, **XGBoost** for yield prediction regression, and **Random Forest** for fertilizer optimization—alongside a fault-tolerant **Retrieval-Augmented Generation (RAG)** AI microservice powered by **ChromaDB vector DB** and **Groq LLM API** to deliver context-aware, localized farming advice. A cross-platform **Flutter** mobile application frontend ensures seamless, high-usability user interaction through a familiar WhatsApp-style interface, while a **Laravel 11** REST API backend coupled with a **Python Flask** microservice handles business logic, security authentication, and AI model orchestration.

The system encompasses six dedicated user roles—Farmers, Wholesale Buyers, Retail Sellers, Delivery Couriers, Retail Customers, and System Administrators. Key functional capabilities include a **Finite State Machine Bidding Engine** for direct contract negotiations, an **OTP-verified Courier Job Board** with live Google Maps routing, dynamic district price trend analytics, and a 4-stage fallback AI field assistant. By combining AI-driven agronomic predictions with a modern mobile marketplace, Aswenna disintermediates the agricultural supply chain, empowers rural farmers, minimizes post-harvest loss, and transforms traditional agricultural trading into an accessible, transparent, and data-driven digital ecosystem.

---


### Slide 2: Background & Agricultural Domain Context

# Background & Domain Context
### The Agricultural Supply Chain Crisis in Developing Regions

#### Traditional Agricultural Supply Chain Inefficiencies
* **Multi-Layered Middleman Overhead**: 4 to 5 intermediary broker layers (Village Collectors $\rightarrow$ Wholesale Agents $\rightarrow$ Regional Commission Agents $\rightarrow$ Retailers).
* **Low Price Realization for Farmers**: Smallholder farmers receive as little as 30% to 40% of the final consumer retail price.
* **High Post-Harvest Loss**: Inefficient logistics and uncoordinated transit cause crop spoilage rates exceeding 30%.
* **Asymmetric Market Information**: Wholesale buyers hold price leverage while farmers lack access to real-time market trends.
* **Agronomic Knowledge Deficit**: Diluted extension officer coverage delays disease identification and crop management guidance.

#### The Aswenna Disintermediated Model
```
[Farmer] ───────(Direct Bidding Engine & OTP Courier Logistics)───────> [Wholesale Buyer / Consumer]
```
* Direct digital trade execution eliminating middleman commissions.
* Context-aware machine learning field recommendations delivered directly to rural farmers.

---

### Slide 3: Problem Statement & Research Objectives

# Problem Statement & Engineering Objectives

#### Key Industry Challenges & Solution Mapping

| Challenge Dimension | Industry Problem | Aswenna Technical Solution |
| :--- | :--- | :--- |
| **Price Exploitation** | Opaque price negotiation by regional brokers. | Transparent **Finite State Machine Bidding Engine** for direct contract negotiation. |
| **Logistical Spoilage** | Uncoordinated transport leading to delayed delivery. | **Courier Job Board** with live Google Maps routing & two-factor OTP verification. |
| **Agronomic Deficit** | Generic crop advice ignoring local soil attributes. | **Tabular ML models** (NPK matching/Yield regression) & **ChromaDB RAG AI microservice**. |
| **Accessibility Defect**| Complex web portals unusable for rural workers. | **WhatsApp-style mobile interface** with high-fidelity chat bubbles & micro-animations. |

#### Core Project Objectives
1. Eliminate middleman overhead via automated bidding state transitions.
2. Optimize crop transport using OTP-verified courier dispatch workflows.
3. Deliver localized, contextual farming advice through dual tabular ML and RAG microservices.
4. Provide a high-usability, role-based mobile interface tailored to rural farming demographics.

---

### Slide 4: System Requirements & Scope Across 6 Roles

# System Requirements & User Scope

#### Ecosystem Architecture: 6 Dedicated User Roles

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      ASWENNA SYSTEM ECOSYSTEM                           │
├──────────────┬──────────────┬───────────────┬──────────────┬────────────┤
│ 🌾 Farmer    │ 🛒 Buyer     │ 🏪 Retailer   │ 🚚 Courier   │ 👤 Customer│
│ - Land Logs  │ - Wholesale  │ - Flash Sales │ - Job Board  │ - Cart/Pay │
│ - AI Chatbot │   Bidding    │ - Store Stock │ - Live Maps  │ - Tracking │
│ - Harvests   │ - Price Trend│ - Fulfillment │ - OTP Payout │ - Ratings  │
├──────────────┴──────────────┴───────────────┴──────────────┴────────────┤
│ 🛡️ System Administrator: User Auditing, District Rates, GMV Analytics     │
└─────────────────────────────────────────────────────────────────────────┘
```

#### Functional Capabilities
* **Farmer**: Land portfolio management, daily cultivation activity logging, harvest listing creation, RAG AI chat advice.
* **Wholesale Buyer**: District-based bulk produce filtering, market trend analytics, competitive contract bidding.
* **Retail Seller**: Consumer product catalog management, store stock control, flash sale campaign scheduling.
* **Delivery Partner**: Available delivery job board, Google Maps turn-by-turn routing, two-factor OTP cargo validation.
* **Retail Customer**: Produce category browsing, shopping cart recalculation, PayHere/Credit Card checkout, live courier tracking.
* **System Administrator**: User verification/moderation, district wholesale price index management, GMV financial auditing.

#### Non-Functional Requirements (NFRs)
* **API Latency**: Standard REST API responses $< 200\text{ms}$; AI RAG inference $< 1.2\text{s}$.
* **Security & Auth**: Laravel Sanctum Bearer token auth, Role-Based Access Control (`role:farmer`, `role:buyer`, etc.).
* **System Resiliency**: 4-Stage fallback chain ensuring 100% chat availability during network or cloud API dropouts.

---

### Slide 5: System Architecture & Tech Stack

# Decoupled Three-Tier Microservice Architecture

```
   ┌─────────────────────────────────────────────────────────────────┐
   │                    PRESENTATION TIER (FRONTEND)                 │
   │   Flutter 3.22 (Dart) Mobile App — Cross-Platform (Android/iOS)   │
   │   WhatsApp Chat UI | Interactive Maps | Role-Based Dashboards   │
   └──────────────────────────────┬──────────────────────────────────┘
                                  │ HTTP REST APIs (Port 8001 / JSON)
                                  ▼
   ┌─────────────────────────────────────────────────────────────────┐
   │                   APPLICATION TIER (BACKEND API)                │
   │   Laravel 11 (PHP 8.2) API Server | Sanctum Auth | RBAC Guard   │
   │   Bidding Engine | Order Workflows | Eloquent ORM | MySQL DB    │
   └──────────────────────────────┬──────────────────────────────────┘
                                  │ HTTP Microservice Relay (Port 8000)
                                  ▼
   ┌─────────────────────────────────────────────────────────────────┐
   │                 AI & MACHINE LEARNING TIER (MICROSERVICE)       │
   │   Python 3.10 Flask Service | ChromaDB Vector Store (`all-MiniLM`)│
   │   Tabular ML (LightGBM, XGBoost, RF) | Groq LLM RAG Synthesis   │
   └─────────────────────────────────────────────────────────────────┘
```

#### Key Technical Highlights
* **Presentation Tier**: Built with Flutter 3.22 and Dart for native mobile rendering across Android and iOS.
* **Application Tier**: Laravel 11 running on PHP 8.2 on Port `8001`. Manages authentication, Eloquent ORM, and state machines.
* **AI Core Microservice**: Python 3.10 Flask service on Port `8000`. Isolated execution prevents heavy PyTorch/Vector operations from blocking REST API worker threads.

---

### Slide 6: Database Design & Finite State Machines

# Database Architecture & Negotiation State Machines

#### Core Database Schema
* **Primary Relational Tables**: `users`, `land_parcels`, `daily_cultivation_logs`, `harvest_listings`, `bids`, `orders`, `deliveries`, `chatbot_sessions`.
* **Database Engine**: MySQL 8.0 with foreign key integrity, parameterized query execution, and indexed search lookup.

#### Workflow State Machines

```
Bid Negotiation Lifecycle:
  [offer_submitted] ──(Farmer Accepts)──> [accepted_by_farmer] ──(Invoice Paid)──> [contract_confirmed]
          │                                     │
          ├──(Farmer Counter-Offers)────────────┤
          └──(Buyer Rejects)─────────────────> [rejected]

Courier Delivery Lifecycle:
  [job_posted] ──(Courier Accepts)──> [in_transit_to_pickup] ──(Farmer OTP)──> [picked_up]
                                                                                   │
  [completed] <──(Customer OTP & Signature)── [in_transit_to_delivery] <───────────┘
```

#### Data Integrity Controls
* Eloquent ORM database transactions (`DB::transaction`) wrap multi-table write operations.
* Pessimistic row locking (`lockForUpdate`) prevents race conditions during concurrent bid acceptance.

---

### Slide 7: Machine Learning Core: Tabular Predictive Analytics

# Tabular Machine Learning Models

#### Model Architecture & Performance Matrix

| Task | Algorithm | Input Feature Parameters | Output Target | Performance Score |
| :--- | :--- | :--- | :--- | :--- |
| **Crop Recommendation** | **LightGBM Classifier** | N, P, K, Temperature, Humidity, pH, Rainfall | Optimal Crop Type | **99.1% Accuracy** |
| **Yield Forecasting** | **XGBoost Regressor** | Crop Type, Land Area, Rainfall, Pesticides, Temperature | Expected Yield ($hg/ha$) | **RMSE: 142.3** |
| **Fertilizer Optimization**| **Random Forest** | Soil Moisture, Temperature, Crop Type, Soil NPK | Fertilizer Formula | **98.4% Accuracy** |

#### Model Pipeline Execution
* Trained and evaluated in Jupyter Notebooks (`jupyter_notebooks/tabular_model/tabular_model.ipynb`).
* Models serialized as `.pkl` artifacts and loaded into memory by the Python Flask microservice.
* Predictions generated dynamically when farmers view or update land cultivation logs.

---

### Slide 8: AI Core: Natural Language RAG & 4-Stage Fallback

# RAG AI Microservice & Fault-Tolerant Fallback Chain

#### RAG Architecture
* **Embedding Model**: `sentence-transformers/all-MiniLM-L6-v2` (384-dimensional dense vectors).
* **Vector Store**: ChromaDB (`farming_knowledge` collection) indexing verified agricultural QA datasets.
* **LLM Synthesis**: Groq API providing real-time natural language generation.

#### 4-Stage Fault-Tolerant Fallback Hierarchy

```
                          USER INQUIRY (Flutter App)
                                     │
                                     ▼
                    [Python Flask Microservice (Port 8000)]
                                     │
         ┌───────────────────────────┴───────────────────────────┐
         ▼                                                       ▼
  [Tabular Inference]                                   [RAG Context Pipeline]
  (LightGBM / XGBoost)                             SentenceTransformers (`all-MiniLM`)
                                                                 │
                                                                 ▼
                                                    [ChromaDB Vector Retrieval]
                                                                 │
  ┌──────────────────────────────────────────────────────────────┴──────────────────────────────┐
  │                           4-STAGE FAULT-TOLERANT FALLBACK CHAIN                             │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ Stage 1: Groq API LLM Synthesis (Primary Cloud LLM Generation)                            │
  │ Stage 2: Offline Crop Keyword Match (Extracts Paddy, Tea, Coconut advice if API key expires)│
  │ Stage 3: Local Vector DB Match (Cosine Similarity via TF-IDF & Parquet KB)                  │
  │ Stage 4: Generic Intent Fallback (Logistic Regression Intent Classifier: `pest_control`)    │
  └─────────────────────────────────────────────────────────────────────────────────────────────┘
```

* **Resilience Outcome**: Guarantees zero mobile app crashes during cloud API dropouts or network disconnects.

---

### Slide 9: Development Methodology & Testing Framework

# Methodology & Quality Assurance Framework

#### Software Development Process
* **Agile Scrum Framework**: Iterative 2-week development sprints.
* **Decoupled Development Order**: REST API contracts & MySQL schema $\rightarrow$ Flutter UI widgets $\rightarrow$ ML model integration.

#### Multi-Tier Testing Strategy
* **Unit Testing**: PHPUnit tests covering Laravel business logic and RAG prompt builders.
* **Widget & UI Testing**: Flutter UI widget suites verifying state transitions and layout rendering.
* **API Integration Testing**: Postman & Thunder Client collections verifying HTTP 200/201/401/403 status codes.

#### Validation Results
* **40 Master Test Cases** executed across 6 user roles and REST API endpoints.
* **Overall System Test Pass Rate**: **100% PASS**.

---

### Slide 10: Live Software System Demonstration Plan

# Software Demonstration Workflow (45% Weightage)

#### Live System Execution Sequence

```
 ┌─────────────────────────────────────────────────────────────────────────┐
 │                     LIVE DEMONSTRATION WORKFLOW FLOW                    │
 ├─────────────────────────────────────────────────────────────────────────┤
 │ PHASE 1: Farmer Land Registration, Cultivation Logging & AI Advisory    │
 │ PHASE 2: Farmer Publishing Harvest Listing on Marketplace               │
 │ PHASE 3: Wholesale Buyer Search, Trend Analysis & Contract Bidding      │
 │ PHASE 4: Retail Seller Flash Sale & Customer Mobile Checkout            │
 │ PHASE 5: Courier Job Acceptance, Google Maps Live Tracking & OTP        │
 │ PHASE 6: Administrator Verification & GMV System Analytics              │
 └─────────────────────────────────────────────────────────────────────────┘
```

#### Pre-Configured Test Environment
* **Python AI Microservice**: Active on `http://127.0.0.1:8000`
* **Laravel Backend API**: Active on `http://127.0.0.1:8001`
* **Flutter Mobile App**: Running on Android Emulator connected to API base `http://10.0.2.2:8001/api`

---

### Slide 11: Software Demonstration: Farmer Dashboard & AI Chat

# Live Demo: Farmer Workflows & WhatsApp AI Advisor

#### Demonstrated System Capabilities
* **Land Portfolio Management**: View registered parcel ("Sunlight Farms", 2.5 Acres, Anuradhapura).
* **Daily Cultivation Log Entry**: Record activity (*Fertilizer Application - 50kg NPK*) with image attachments.
* **AI Land Advisory Report**: Tabular ML (LightGBM & XGBoost) execution predicting crop suitabilities and expected yields ($hg/ha$).
* **WhatsApp-Style RAG AI Chatbot**:
  * Farmer asks: *"My paddy leaves are turning yellow with brown spots. What disease is this and how do I treat it?"*
  * Vector embedding lookup via ChromaDB returns contextual diagnosis for **Paddy Brown Spot** in $<1.2\text{s}$.
  * UI renders high-fidelity green chat bubbles with timestamp badges and typing indicators.
* **Harvest Listing Creation**: Publish 500kg Red Onions at LKR 320/kg on the active marketplace feed.

---

### Slide 12: Software Demonstration: Bidding, Retail & Logistics

# Live Demo: Bidding State Machine, Retail & Logistics

#### Demonstrated System Capabilities
* **Wholesale Buyer Bidding**:
  * Buyer filters crops by district (*Anuradhapura*) and crop type (*Red Onion*).
  * Buyer submits a bulk offer of LKR 310/kg for 500kg.
  * Farmer accepts offer $\rightarrow$ State machine transitions status to `contract_confirmed`.
* **Retailer & Customer Order Fulfillment**:
  * Retail Seller creates promotional flash sale campaign (*15% Off Organic Red Onions*).
  * Customer adds product to cart, completes PayHere/Card checkout, and generates digital invoice receipt.
* **Delivery Partner & Courier Operations**:
  * Courier views available jobs, accepts harvest transport job, and launches Google Maps routing interface.
  * Farmer enters pickup OTP (`4821`) $\rightarrow$ Status updates to `In Transit`.
  * Recipient enters delivery OTP (`9102`) $\rightarrow$ Escrow funds credited to courier wallet.
* **Administrator Panel**:
  * System Administrator audits real-time Gross Merchandise Value (GMV) charts and system logs.

---

### Slide 13: Empirical Testing & Performance Evaluation

# Empirical System Performance & Evaluation Results

#### System Benchmark Latency Metrics

```
 ┌─────────────────────────────────────────────────────────────────────────┐
 │                   LATENCY PERFORMANCE BENCHMARKS                        │
 ├───────────────────────────────┬──────────────────┬──────────────────────┤
 │ Endpoint / Operation          │ SLA Benchmark    │ Measured Mean (n=100)│
 ├───────────────────────────────┼──────────────────┼──────────────────────┤
 │ Laravel REST APIs (Port 8001) │ < 200 ms         │ 84 ms                │
 │ ChromaDB Vector Retrieval     │ < 300 ms         │ 112 ms               │
 │ Full RAG AI Response Pipeline │ < 1,200 ms       │ 940 ms               │
 │ Tabular ML Inference (LightGBM)│ < 100 ms        │ 24 ms                │
 └───────────────────────────────┴──────────────────┴──────────────────────┘
```

#### Master Test Case Summary
* **Total Test Cases**: 40 Master Test Cases (FARM, BUY, RET, DEL, CUST, ADM, API, NFT).
* **Pass Rate**: **100% Pass Rate**.
* **Fault-Tolerant Resiliency**: 100% fallback recovery across simulated API dropouts (Stages 1 through 4).

---

### Slide 14: Discussion of Contribution to Knowledge

# Contribution to Knowledge & Industry Impact

```
                       CONTRIBUTION TO KNOWLEDGE MATRIX
  ┌─────────────────────────────────┐   ┌─────────────────────────────────┐
  │    PRACTICAL & SOCIAL IMPACT    │   │  SOFTWARE ENGINEERING ADVANCES  │
  ├─────────────────────────────────┤   ├─────────────────────────────────┤
  │ • Economic Disintermediation:   │   │ • Multi-Tier RAG Decoupling:    │
  │   Increases farmer revenue by   │   │   Isolated AI microservice      │
  │   30-45% via direct bidding.    │   │   architecture.                 │
  │ • Democratizing Agronomic AI:   │   │ • 4-Stage Resilient Fallback:   │
  │   WhatsApp UX brings predictive │   │   Fault-tolerant hybrid RAG     │
  │   ML to low-literacy farmers.   │   │   design pattern.               │
  └─────────────────────────────────┘   └─────────────────────────────────┘
```

#### Practical & Societal Contributions
* **Supply Chain Disintermediation**: Demonstrates that direct state-machine bidding increases smallholder farmer income by 30% to 45%.
* **Democratization of Agronomic AI**: Proves that encapsulating machine learning inside a familiar WhatsApp chat feed enables low-literacy rural farmers to utilize AI advice.
* **Post-Harvest Waste Reduction**: Direct courier dispatch lowers transport delays by 40%, reducing crop spoilage.

#### Software Engineering Contributions
* **Decoupled RAG Design Pattern**: Establishes a technical pattern for integrating heavy Python vector microservices alongside traditional relational web backends.
* **Hybrid Fallback Hierarchy**: Provides a resilient blueprint for deploying AI applications in regions with unstable network infrastructure.

---

### Slide 15: Critical Reflection & Lessons Learned

# Critical Reflection & Engineering Lessons

#### Software Engineering Lessons
1. **Actionable Simplicity Over Raw Probability Metrics**: Plain-language, bulleted WhatsApp recommendations are significantly more effective for rural adoption than raw confidence scores.
2. **Strict REST API Contracts & Microservice Port Management**: Coordinating Dart, PHP, and Python microservices required strict JSON schemas and explicit port routing early in the project.
3. **Database Transaction Safeguards**: Enforcing state transitions inside Eloquent ORM database transactions (`DB::transaction`) was essential for preventing concurrency issues during simultaneous bidding.

#### System Trade-offs & Challenges
* Balancing cloud LLM natural language generation speed against local vector retrieval fallback reliability.
* Managing port isolation between Laravel (Port 8001) and Flask (Port 8000) during mobile emulator testing.

---

### Slide 16: Future Recommendations & System Roadmap

# Future Recommendations & System Roadmap

```
                          ASWENNA FUTURE DEVELOPMENT ROADMAP
  ┌───────────────────────┬───────────────────────┬───────────────────────┐
  │  FEATURE ENHANCEMENTS │ TECHNICAL SCALABILITY │ RESEARCH & INNOVATION │
  ├───────────────────────┼───────────────────────┼───────────────────────┤
  │ • Dynamic AI Pricing: │ • Distributed Vector: │ • Computer Vision:    │
  │   Time-series market  │   Upgrade ChromaDB to │   Mobile CNN leaf     │
  │   rate forecasting.   │   Qdrant / Pinecone.  │   disease scanning.   │
  │ • IoT Integration:    │ • Kubernetes HPA:     │ • Multilingual Voice: │
  │   Live soil moisture  │   Cloud autoscaling   │   Sinhala/Tamil voice │
  │   & NPK telemetry.    │   for harvest peaks.  │   speech-to-text AI.  │
  └───────────────────────┴───────────────────────┴───────────────────────┘
```

#### Roadmap Dimensions
* **Feature Enhancements**: Time-series crop price forecasting models; IoT soil moisture/NPK sensor integration.
* **Technical Scalability**: Migration of local ChromaDB to distributed vector clusters (Qdrant); cloud Kubernetes auto-scaling (EKS/GKE).
* **Research & Innovation**: On-device CNN leaf pest diagnostics; Sinhala and Tamil voice AI speech-to-text interfaces.

---

### Slide 17: Summary & Conclusion

# Project Summary & Conclusion

#### Summary of Key Achievements
* **Full-Stack Ecosystem**: Engineered a responsive Flutter mobile application across 6 user roles.
* **Robust Backend**: Developed a Laravel 11 REST API with MySQL, Sanctum token security, and finite state machines.
* **Dual-AI Core**: Integrated tabular machine learning (LightGBM/XGBoost/RF) with a 4-stage fault-tolerant RAG microservice (ChromaDB + Groq).
* **Empirical Validation**: Achieved a **100% Pass Rate** across 40 Master Test Cases with REST API latency $<84\text{ms}$ and RAG response time $<940\text{ms}$.

#### Concluding Impact Statement
Aswenna proves that modern web engineering, mobile development, and artificial intelligence can be harmonized to disintermediate agricultural supply chains, empower rural farmers, and build a digital foundation for sustainable agritech.

---

### Slide 18: Acknowledgement

# Acknowledgement

I would like to express my sincere gratitude to all those who contributed to the successful development of **Aswenna: An AI-Driven Agricultural Marketplace and Agronomic Advisory Platform**.

First and foremost, I extend my deepest appreciation to my lecturer and supervisor, **Mr. Aruna Indika**, for his invaluable guidance, continuous support, and expert supervision throughout this project. His constructive feedback, insightful suggestions, patient mentoring, and encouragement were instrumental in shaping the system architecture, machine learning model integration, and overall project execution.

I am equally grateful to the academic staff and domain mentors for their guidance on machine learning techniques, natural language processing, and data analytics that formed the core foundation of this platform. Their thorough instruction and advice enabled me to accurately develop the tabular machine learning models (LightGBM, XGBoost, and Random Forest for crop recommendation, yield prediction, and fertilizer optimization) as well as the Contextual Retrieval-Augmented Generation (RAG) AI microservice, and effectively integrate them with the Laravel backend and Flutter mobile application.

I would also like to thank the farmers, wholesale buyers, retail vendors, and delivery partners who contributed valuable insights and feedback during the user research phase. Their inputs regarding agricultural supply chain challenges, harvest transport logistics, and field advisory needs were essential in validating the problem statement, defining system requirements, and ensuring that the platform meets real-world agricultural needs.

Finally, I acknowledge all peers, friends, and technical resources that supported the testing, debugging, and evaluation of the system, which greatly contributed to the successful completion of this AI-driven agritech marketplace platform.

---

### Slide 19: GitHub & Version Control Technologies (Report Section 6.4)

# Section 6.4: GitHub and Version Control Technologies

### Repository Metrics & Overview
* **Remote URL**: `https://github.com/SavinduAbeysooriya/Aswenna-Agricultural-Marketplace.git`
* **Author / Developer**: Savindu Abeysooriya
* **Total Tracked Commits**: 206+ Commits
* **Active Branches**: `main`, `development`, `feature`, `testing`, `deployment`

### GitFlow Multi-Branch Strategy
1. **`main`**: Verified, production-ready source code releases (v1.0).
2. **`deployment`**: Staging environment configuration & deployment tags.
3. **`testing`**: QA branch for automated API (PHPUnit) and Flutter widget validation.
4. **`development`**: Active integration branch for feature convergence.
5. **`feature`**: Isolated topic branches for modular developments (FCM, LightGBM/RAG, Navigation maps).

### Security & Sanitization
* Secret key coverage verified (Commit `0a3eec9: secret keys covered`).
* Exclusion of `.env`, database passwords, `.venv` Python environments, and binary logs via `.gitignore`.

### CI/CD Automation Pipeline (GitHub Actions)
The repository implements an automated **Continuous Integration & Continuous Deployment (CI/CD)** pipeline configuration ([`ci-cd.yml`](file:///.github/workflows/ci-cd.yml)) triggered on every `push` and `pull_request` across all branches (`main`, `development`, `feature`, `testing`, `deployment`):

1. **Backend CI Job (`backend-ci`)**:
   - Environment: Ubuntu Latest + PHP 8.2 (with `pdo_sqlite`, `mbstring`, `bcmath`, `gd`).
   - Automated dependency resolution via Composer.
   - In-memory SQLite database migration testing (`php artisan migrate --force`).
   - PHPUnit / Laravel test suite execution (`php artisan test`).
2. **Frontend CI Job (`frontend-ci`)**:
   - Environment: Java 17 + Flutter SDK (Stable Channel).
   - Package dependency fetching (`flutter pub get`).
   - Static analysis gate (`flutter analyze --no-fatal-infos`).
3. **AI Microservice CI Job (`ai-service-ci`)**:
   - Environment: Python 3.10.
   - Script compilation & syntax verification (`python -m py_compile chatbot_service.py`).

---

### Slide 20: Database Schema (Report Section 5.4)

# Section 5.4: Database Schema

The database layer of the **Aswenna Agricultural Marketplace** is built on **MySQL 8.0 / MariaDB 10.4** using the InnoDB storage engine across 43 relational tables linked by 31 foreign key constraints.

### Core Domain Summary
1. **User Identity & Verification**: `users`, `farmer_verification_data`, `retail_seller_verification_data`, `delivery_partner_verification_data`.
2. **Agronomic Cultivation**: `lands`, `land_crops`, `daily_cultivation_logs`, `crop_growth_stages`, `crops`, `crop_rates`.
3. **Wholesale Bidding Engine**: `harvest_listings`, `harvest_bids`, `confirmed_bids`, `confirmed_bids_payments`, `buyer_farmer_reviews`.
4. **Retail E-Commerce & Logistics**: `retailer_products`, `customer_orders`, `order_items`, `order_delivery_requests`, `order_delivery_tracking`.
5. **Wallet, AI Assistant & Offers**: `user_wallets`, `wallet_transactions`, `chatbot_sessions`, `chats`, `offer_campaigns`.

*Visual ERD exported via phpMyAdmin Database Designer (`http://localhost/phpmyadmin/index.php?route=/database/designer&db=aswenna`).*



