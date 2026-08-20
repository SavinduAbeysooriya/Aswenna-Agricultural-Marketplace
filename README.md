# 🌾 Aswenna Agricultural Marketplace

> **An Enterprise-Grade, Multi-Tier Digital Agritech Ecosystem & Contextual RAG AI Supply Chain Platform**

[![Laravel](https://img.shields.io/badge/Laravel-11.x-FF2D20?style=for-the-badge&logo=laravel&logoColor=white)](https://laravel.com)
[![Flutter](https://img.shields.io/badge/Flutter-3.22-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Python](https://img.shields.io/badge/Python-3.10-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://python.org)
[![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?style=for-the-badge&logo=mysql&logoColor=white)](https://mysql.com)
[![Groq AI](https://img.shields.io/badge/Groq_AI-Llama_3.3_70B-F05032?style=for-the-badge&logo=openai&logoColor=white)](https://groq.com)
[![ChromaDB](https://img.shields.io/badge/ChromaDB-Vector_DB-FF6600?style=for-the-badge)](https://www.trychroma.com/)
[![LightGBM](https://img.shields.io/badge/LightGBM-Tabular_ML-2B579A?style=for-the-badge)](https://lightgbm.readthedocs.io/)
[![CI/CD](https://img.shields.io/badge/GitHub_Actions-CI%2FCD_Passing-2088FF?style=for-the-badge&logo=githubactions&logoColor=white)](https://github.com/SavinduAbeysooriya/Aswenna-Agricultural-Marketplace/actions)

---

## 📑 Table of Contents
- [Executive Overview](#-executive-overview)
- [System Architecture Topology](#-system-architecture-topology)
- [High-Tech Core Innovations](#-high-tech-core-innovations)
- [Stakeholder Ecosystem & Role Matrix](#-stakeholder-ecosystem--role-matrix)
- [Detailed Technology Stack](#-detailed-technology-stack)
- [Port Assignments & Microservices](#-port-assignments--microservices)
- [Local Installation & Setup Guide](#-local-installation--setup-guide)
- [API Endpoints Directory](#-api-endpoints-directory)
- [Database Schema & Spatial Indexing](#-database-schema--spatial-indexing)
- [CI/CD DevOps & Security Specification](#-cicd-devops--security-specification)
- [License & Authorship](#-license--authorship)

---

## 🚀 Executive Overview

The **Aswenna Agricultural Marketplace** is an advanced, multi-tier digital agritech ecosystem engineered to disintermediate traditional agricultural supply chains in Sri Lanka. By interconnecting **Farmers, Wholesale Buyers, Retail Sellers, Delivery Partners, Retail Customers, and System Admins** into a real-time digital network, Aswenna addresses key structural inefficiencies:

1. **Eliminating Multi-Layered Middleman Exploitation**: Direct state-machine-driven auction bidding between farmers and buyers.
2. **Contextual Agronomic Field Advisory**: A 4-stage fallback **Retrieval-Augmented Generation (RAG)** AI assistant powered by **ChromaDB Vector DB** and **Groq LLM API** (`llama-3.3-70b-versatile`).
3. **Logistics Security & OTP Verification**: Digital contract enforcement with OTP pickup/delivery signatures, cargo photo validation, and Google Maps Haversine distance routing.
4. **Market Transparency & Price Seeding**: Automated daily price discovery engine calculating grade-based rates (Grades A, B, C) across 100+ crop varieties.
5. **Real-Time Financial Wallet Analytics**: Dedicated buyer and customer wallet ledgers tracking total spent metrics, available balances, pending holds, and transaction histories.

---

## 🏗️ System Architecture Topology

```
                                 ┌─────────────────────────────────────────────────────────┐
                                 │              FLUTTER 3.22 CROSS-PLATFORM CLIENT         │
                                 │       (Android APK / iOS / Web - Custom Material 3)     │
                                 └────────────────────────────┬────────────────────────────┘
                                                              │
                                                   HTTPS / Sanctum Bearer Token
                                                              │
                                                              ▼
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                           LARAVEL 11 RESTFUL API GATEWAY (Port 8001)                                      │
├─────────────────────────────────────────────────────────────┬────────────────────────────────────────────────────────────┤
│  • Auth & User Verification (NIC/Passport Docs)             │  • Digital Contract Generator & Dompdf PDF Renderer        │
│  • Finite State Machine Harvest Bidding Engine              │  • FCM HTTP v1 Push Notification Dispatcher                │
│  • Financial Wallet & Analytics Ledger                      │  • Haversine Spatial Distance Calculator                   │
└──────────────────────────────┬──────────────────────────────┴──────────────────────────────┬─────────────────────────────┘
                               │                                                             │
                  SQL Queries / InnoDB Transactions                                 REST HTTP / JSON Payload
                               │                                                             │
                               ▼                                                             ▼
┌──────────────────────────────────────────────┐                         ┌─────────────────────────────────────────────────┐
│       MYSQL 8.0 / MARIADB DATABASE           │                         │     PYTHON 3.10 AI MICROSERVICE (Port 5000)     │
│       (43 Relational Tables, 31 Foreign Keys)│                         ├─────────────────────────────────────────────────┤
│  • users, user_wallets, wallet_txs           │                         │ • ChromaDB Vector DB (all-MiniLM-L6-v2 Embeds)  │
│  • crops, crop_rates (100 crops daily)       │                         │ • Groq LLM Engine (Llama 3.3 70B & Qwen 27B)    │
│  • harvest_listings, confirmed_bids          │                         │ • LightGBM Crop Recommendation Model            │
│  • customer_orders, digital_contracts        │                         │ • XGBoost Yield Prediction Regression Model     │
└──────────────────────────────────────────────┘                         └─────────────────────────────────────────────────┘
```

---

## 🧬 High-Tech Core Innovations

### 1. Contextual RAG AI Agronomist (Retrieval-Augmented Generation)
- **Vector Embeddings**: Documents and agronomic knowledge bases are embedded using `SentenceTransformers (all-MiniLM-L6-v2)` into a persistent **ChromaDB Vector Database**.
- **Query Optimization**: Natural language queries are sanitized and transformed into optimized keywords via a Groq LLM pre-processor before semantic vector search.
- **Fault-Tolerant Fallback Matrix**: If primary LLM rates limit, the service seamlessly cascades across model tiers (`llama-3.3-70b-versatile` $\rightarrow$ `qwen/qwen3.6-27b` $\rightarrow$ `openai/gpt-oss-120b`).

### 2. Tabular Machine Learning Intelligence
- **Crop Recommendation**: Powered by **LightGBM**, evaluating soil pH, nitrogen, phosphorus, potassium, rainfall, and temperature parameters to recommend top 3 optimal crops.
- **Yield Prediction Regression**: **XGBoost** model predicting harvest yield per hectare in metric tons.
- **Soil Fertilizer Optimization**: **Random Forest** classifier providing customized NPK fertilizer dosages.

### 3. Spatial Haversine Routing & Courier OTP Protocol
- **Spatial Distance Engine**: Calculates real-time geographical distance ($d$) between sellers and delivery destinations using spatial SQL math:
  $$d = 2r \arcsin\left(\sqrt{\sin^2\left(\frac{\Delta \phi}{2}\right) + \cos(\phi_1) \cos(\phi_2) \sin^2\left(\frac{\Delta \lambda}{2}\right)}\right)$$
- **Cryptographic OTP Verification**: Deliveries require a 4-digit `pickup_otp` from the farmer and a 4-digit `delivery_otp` from the recipient, accompanied by cargo photo proof and recipient signature image capture.

---

## 👥 Stakeholder Ecosystem & Role Matrix

| Stakeholder Role | Primary Capabilities | Technical Interface |
| :--- | :--- | :--- |
| 🧑‍🌾 **Farmer** | Harvest listing, bid acceptance, crop log updates, RAG AI agronomist chat. | Flutter Farmer Dashboard |
| 🏢 **Wholesale Buyer** | Reverse auction bidding, digital contract execution, **Total Spent & Wallet Analytics**. | Flutter Market Rates & Buyer Profile |
| 🏬 **Retail Seller** | Produce listing, offer campaign discount creation, customer order fulfillment. | Flutter Retailer Dashboard |
| 🛒 **Retail Customer** | Product search, grade filtering, cart checkout, **Customer Wallet & Order History**. | Flutter Customer Dashboard & Profile |
| 🚚 **Delivery Partner** | Job board acceptance, Google Maps route navigation, **OTP Pickup/Delivery Verification**. | Flutter Delivery Dashboard |
| 🛡️ **System Admin** | User identity verification (NIC/Passport), campaign moderation, platform analytics. | Blade Web Admin Portal |

---

## 🛠️ Detailed Technology Stack

### **Backend Framework & Services**
- **Framework**: Laravel 11.x (PHP 8.2)
- **Database Engine**: MySQL 8.0 / MariaDB 10.4 (InnoDB, Spatial Indexing)
- **API Security**: Laravel Sanctum Token Authentication & Rate Limiting
- **Notifications**: Firebase Cloud Messaging (FCM) v1 HTTP API & Curl Dispatcher
- **PDF Engine**: Dompdf (Automated Digital Contract, Invoice & Purchase Report rendering)

### **Frontend Application**
- **Framework**: Flutter 3.22 (Dart 3.4)
- **Platforms**: Android (SDK 34), iOS, Web Browser
- **Mapping**: Google Maps Flutter SDK (`google_maps_flutter`), Geolocator
- **UI Design**: Custom Dark Leaf-Green Aesthetic, Glassmorphism, Material 3 Design System

### **AI & Machine Learning Microservice**
- **Microservice Runtime**: Python 3.10 (Flask CORS API)
- **Vector Database**: ChromaDB Vector Store
- **Embeddings Model**: `sentence-transformers/all-MiniLM-L6-v2`
- **LLM API**: Groq Cloud API (`llama-3.3-70b-versatile`)
- **ML Frameworks**: LightGBM, XGBoost, Scikit-Learn, Pandas, NumPy

---

## 🖥️ Port Assignments & Microservices

| Service Name | Port | Base URL | Launch Command |
| :--- | :--- | :--- | :--- |
| **Laravel REST API** | **8001** | `http://localhost:8001/api` | `php artisan serve --port=8001` |
| **Python AI Microservice** | **5000** | `http://localhost:5000/api` | `python chatbot_service.py` |
| **MySQL Database** | **3306** | `localhost:3306` (`aswenna`) | MySQL Service / XAMPP / WampServer |
| **Flutter Mobile App** | Dynamic | Android / iOS / Chrome | `flutter run -d chrome` / `flutter run` |

---

## ⚡ Local Installation & Setup Guide

### **1. Clone Repository**
```bash
git clone https://github.com/SavinduAbeysooriya/Aswenna-Agricultural-Marketplace.git
cd "Aswenna Agricultural Marketplace"
```

### **2. Configure Backend REST API (Port 8001)**
```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php seed_30day_market_rates.php
php artisan serve --port=8001
```

### **3. Configure Python AI Microservice (Port 5000)**
```bash
cd ../ai_models
pip install -r requirements.txt
python chatbot_service.py
```

### **4. Launch Flutter Mobile Application**
```bash
cd ../frontend
flutter pub get
flutter run
```

---

## 📑 API Endpoints Directory

### **Authentication & Buyer/Customer Profile**
- `POST /api/auth/login` — Authenticate user & return Sanctum bearer token.
- `GET /api/buyer/profile` — Fetch profile, verified state, **wallet data, total_spent, completed deals & recent transactions**.
- `POST /api/buyer/profile/update` — Upload profile photo, NIC front/back verification documents.

### **Harvest Bidding & Marketplace**
- `GET /api/harvest-listings` — List active farmer crop harvests with grade & location data.
- `POST /api/harvest-bids/place` — Place wholesale bid on crop harvest.
- `POST /api/harvest-bids/{id}/accept` — Accept bid & generate digital contract.

### **Orders, OTP Logistics & Wallet**
- `GET /api/user/wallet` — Retrieve wallet balance, total earned, total spent, and transaction logs.
- `POST /api/orders/verify-pickup-otp` — Verify 4-digit pickup OTP from farmer upon cargo loading.
- `POST /api/orders/verify-delivery-otp` — Verify 4-digit delivery OTP & save recipient signature.

### **AI Chatbot & Agronomic Assistant (Port 5000)**
- `POST /api/chatbot/query` — Send farmer query to RAG pipeline (returns contextual agronomic response).
- `POST /api/ml/predict-crop` — Run LightGBM model to predict optimal crop recommendation.

---

## 🗄️ Database Schema & Spatial Indexing

The database layer consists of **43 relational tables** linked by **31 foreign keys**:

```
[users] ───<1:N>─── [user_wallets] ───<1:N>─── [wallet_transactions]
   │
   ├───<1:N>─── [harvest_listings] ───<1:N>─── [harvest_bids] ───<1:1>─── [confirmed_bids]
   │                                                                           │
   ├───<1:N>─── [customer_orders] <────────────────────────────────────────────┘
   │                  │
   │                  └───<1:1>─── [digital_contracts]
   │
   └───<1:N>─── [crop_rates] (Daily seeded rates across 100 crops & 7 buyer IDs)
```

- **Daily Rate Seeding**: Bulk chunked insertion script (`seed_30day_market_rates.php`) seeds **21,000+ daily market rate entries** across 100 crops and 7 buyer IDs for today and past 30 days.

---

## 🔄 CI/CD DevOps & Security Specification

This project utilizes an automated **GitHub Actions CI/CD Pipeline** ([`ci-cd.yml`](.github/workflows/ci-cd.yml)) triggered on pushes to `main` and `development` branches:

- **Backend CI**: Ubuntu Latest, PHP 8.2, MySQL 8.0 Docker container service, Artisan migrations, and PHPUnit testing.
- **Frontend CI**: Java 17, Flutter SDK, `flutter pub get`, and `flutter analyze` static code quality gate.
- **AI Service CI**: Python 3.10 module syntax compilation check.

---

## 👨‍💻 License & Authorship

* **Author / Lead Developer**: **Savindu Abeysooriya**
* **Repository**: [SavinduAbeysooriya/Aswenna-Agricultural-Marketplace](https://github.com/SavinduAbeysooriya/Aswenna-Agricultural-Marketplace)
* **Branch**: `development`
* **License**: Open Source for Academic & Educational Research Evaluation
