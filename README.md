# 🌾 Aswenna Agricultural Marketplace

> **A Next-Generation Digital Agritech Ecosystem & AI-Powered Supply Chain Platform**

[![Laravel](https://img.shields.io/badge/Laravel-11.x-FF2D20?style=for-the-badge&logo=laravel&logoColor=white)](https://laravel.com)
[![Flutter](https://img.shields.io/badge/Flutter-3.22-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Python](https://img.shields.io/badge/Python-3.10-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://python.org)
[![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?style=for-the-badge&logo=mysql&logoColor=white)](https://mysql.com)
[![Groq AI](https://img.shields.io/badge/Groq_AI-Llama_3.3_70B-F05032?style=for-the-badge&logo=openai&logoColor=white)](https://groq.com)
[![CI/CD](https://img.shields.io/badge/GitHub_Actions-CI%2FCD_Passing-2088FF?style=for-the-badge&logo=githubactions&logoColor=white)](https://github.com/SavinduAbeysooriya/Aswenna-Agricultural-Marketplace/actions)

---

## 🚀 Project Overview

**Aswenna Agricultural Marketplace** is an enterprise-grade, multi-tier digital agritech ecosystem designed to disintermediate traditional agricultural supply chains in Sri Lanka. By connecting **Farmers, Wholesale Buyers, Retail Sellers, Delivery Partners, Retail Customers, and System Admins** in a single unified platform, Aswenna eliminates middleman exploitation, reduces post-harvest loss, provides real-time market price discovery, and offers localized AI-driven agronomic field advice.

---

## 🛠️ Technology Stack & Architecture

### **Backend Core (REST API)**
- **Framework**: Laravel 11.x (PHP 8.2)
- **Database**: MySQL 8.0 / MariaDB 10.4 (43 Tables, 31 Foreign Keys)
- **Authentication**: Laravel Sanctum Token-based Auth
- **Push Notifications**: Firebase Cloud Messaging (FCM) & Google FCM HTTP v1 API
- **Document & Media Storage**: Local Storage with Symlink Storage Disk
- **PDF Generation**: Dompdf (Invoices, Purchases & Sales Analytics Reports)

### **Frontend App (Cross-Platform)**
- **Framework**: Flutter 3.22 (Dart)
- **Platforms**: Android, iOS, Web
- **State & Networking**: Custom Reactive Provider / API Services
- **Mapping & Location**: Google Maps SDK, Geolocator, Dynamic Coordinates Picker
- **UI & Themes**: Custom Dark/Leaf Green Theme, Glassmorphism, Material 3 Design

### **AI & Machine Learning Microservice**
- **Runtime**: Python 3.10 Flask Microservice
- **LLM Engine**: Groq API (`llama-3.3-70b-versatile`, `qwen/qwen3.6-27b` failovers)
- **RAG Vector Search**: ChromaDB Vector DB & SentenceTransformers (`all-MiniLM-L6-v2`)
- **Tabular ML Models**: 
  - **LightGBM**: Recommended Crop Selection Engine
  - **XGBoost**: Expected Yield Prediction Regression
  - **Random Forest**: Soil Fertilizer Optimization

---

## 🖥️ System Requirements & Port Assignments

| Component | Technology | Default Port / Endpoint | Running Command |
| :--- | :--- | :--- | :--- |
| **Backend REST API** | Laravel 11 (PHP 8.2) | `http://localhost:8001` (**Port 8001**) | `php artisan serve --port=8001` |
| **AI Chatbot Service** | Python 3.10 Flask | `http://localhost:5000` (**Port 5000**) | `python chatbot_service.py` |
| **Frontend Application** | Flutter SDK | Mobile Device / Web Browser | `flutter run -d chrome` / `flutter run` |
| **MySQL Database** | MySQL 8.0 | `localhost:3306` (Database: `aswenna`) | `mysql -u root` / XAMPP / WampServer |

---

## ⚡ Quick Start Guide (How to Run Locally)

### **1. Clone the Repository**
```bash
git clone https://github.com/SavinduAbeysooriya/Aswenna-Agricultural-Marketplace.git
cd "Aswenna Agricultural Marketplace"
```

### **2. Setup & Launch Backend Server**
```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php seed_30day_market_rates.php
php artisan serve --port=8001
```
> 📍 **Backend running at**: `http://localhost:8001`

### **3. Setup & Launch AI Microservice**
```bash
cd ../ai_models
pip install -r requirements.txt
python chatbot_service.py
```
> 📍 **AI Service running at**: `http://localhost:5000`

### **4. Launch Frontend Application**
```bash
cd ../frontend
flutter pub get
flutter run
```

---

## 🌟 Key Platform Features

- **🛒 Multi-Tier Marketplace**: Separate specialized dashboards for Farmers, Wholesale Buyers, Retailers, Delivery Partners, Customers, and System Administrators.
- **💰 Financial Wallet & Analytics**: Real-time wallet balance tracking, total spent metrics, pending/available balance management, and automated transaction history logs.
- **🌾 Real-Time District Crop Market Rates**: Daily price discovery engine for 100+ crops seeded across Grade A, B, and C standards.
- **📜 Digital Contracts & Cargo OTP**: Legal digital agreement generation with OTP-verified cargo pickup/delivery signatures.
- **🤖 Contextual RAG AI Agronomist**: WhatsApp-style conversational AI field advisor providing localized crop disease diagnosis and soil management.
- **📦 Logistics & Live Map Routing**: Delivery job board with Google Maps route optimization and distance calculation.

---

## 📂 Project Repository Structure

```
Aswenna-Agricultural-Marketplace/
├── backend/                  # Laravel 11 REST API Backend
│   ├── app/Http/Controllers/ # REST Controllers (Auth, Bids, Wallet, Orders)
│   ├── database/migrations/  # 43 Relational Database Migrations
│   ├── database/seeders/     # Data Seeders & Market Rate Generators
│   ├── resources/views/      # Admin Blade Views & Dompdf Templates
│   └── routes/api.php        # API Endpoint Registry
├── frontend/                 # Flutter Cross-Platform Application
│   ├── lib/screens/          # Dashboards (Farmer, Buyer, Retailer, Customer)
│   ├── lib/services/         # ApiService HTTP Layer & Storage Handlers
│   └── lib/theme/            # AppTheme Color System & Typography
├── ai_models/                # Python RAG & Machine Learning Microservices
│   ├── chatbot_service.py    # Flask Groq LLM & ChromaDB RAG Service
│   └── model_training/       # LightGBM & XGBoost Training Notebooks
└── .github/workflows/        # CI/CD GitHub Actions Pipeline Configs
    └── ci-cd.yml             # Automated Build, Test, & Analyze Jobs
```

---

## 🔄 CI/CD Pipeline & DevOps

This project features an automated **GitHub Actions CI/CD Pipeline** ([`ci-cd.yml`](.github/workflows/ci-cd.yml)) triggered on pushes to `main` and `development` branches:

- **Backend CI**: PHP 8.2 environment, MySQL 8.0 container service, Artisan migrations, and test execution.
- **Frontend CI**: Java 17 + Flutter SDK setup, package resolution, and `flutter analyze` static quality gate.
- **AI Service CI**: Python 3.10 syntax compilation and module health checks.

---

## 👨‍💻 Developer & Maintainer

* **Author**: **Savindu Abeysooriya**
* **Repository**: [SavinduAbeysooriya/Aswenna-Agricultural-Marketplace](https://github.com/SavinduAbeysooriya/Aswenna-Agricultural-Marketplace)
* **Active Branch**: `development`
