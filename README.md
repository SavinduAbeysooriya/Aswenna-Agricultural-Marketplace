# Aswenna Agricultural Marketplace — Complete Setup & Run Guide

Aswenna is a state-of-the-art, cross-platform agricultural marketplace connecting farmers, buyers, delivery partners, and retail sellers. The platform facilitates crop trading, secure order transactions, and features a premium, WhatsApp-style AI farming agent.

---

## 🏗️ Architecture Overview

The system is built on a scalable, three-tier architecture:
1. **Frontend (Flutter)**: Cross-platform mobile app providing premium user interfaces, WhatsApp-style dynamic messaging feeds, and real-time dashboard analytics.
2. **Backend (Laravel)**: A high-performance API backend handling user profiles, authentication (via Sanctum), order workflows, land portfolios, and chat logs.
3. **AI Core (Python RAG Microservice)**: A Flask service utilizing a **ChromaDB vector database** and the **SentenceTransformers (`all-MiniLM-L6-v2`)** model to provide real-time agricultural advice.

---

## 🛠️ Step-by-Step Installation & Setup

Ensure you have the following prerequisites installed on your system:
- PHP 8.2+ & Composer
- Python 3.10+ & Pip
- Flutter SDK & Android Emulator / iOS Simulator

### 1. Python RAG AI Service Setup
1. Open your terminal and navigate to the `ai_models` directory:
   ```bash
   cd "ai_models"
   ```
2. Install the required packages:
   ```bash
   pip install flask flask-cors chromadb sentence-transformers torch
   ```
   *(ChromaDB will automatically download and set up its sqlite3 vector segment indexing engine.)*

### 2. Laravel Backend Setup
1. Open a new terminal and navigate to the `backend` directory:
   ```bash
   cd "backend"
   ```
2. Install the PHP dependencies:
   ```bash
   composer install
   ```
3. Configure your local database in the `.env` file.
4. Execute the database migration to build the fresh chatbot session tables and other schema elements:
   ```bash
   php artisan migrate:refresh
   ```

### 3. Flutter Mobile App Setup
1. Open a new terminal and navigate to the `frontend` directory:
   ```bash
   cd "frontend"
   ```
2. Fetch the Flutter package dependencies:
   ```bash
   flutter pub get
   ```

---

## 📡 Port Configuration

To prevent port conflicts (since both Laravel `artisan serve` and the Python service default to port `8000`), we route them on adjacent ports:
- **Port 8000**: Reserved for **Python AI Microservice** (accessed locally by Laravel at `http://127.0.0.1:8000/chat`).
- **Port 8001**: Reserved for **Laravel Backend** (accessed by the Android Emulator at `http://10.0.2.2:8001/api`).

---

## 🚀 Running the Project Step-by-Step

Follow this exact order of execution to start your development workspace:

### Step 1: Start the Python AI Agent Microservice
Open a terminal, navigate to `ai_models`, and run:
```bash
cd "ai_models"
python chatbot_service.py
```
- **Validation**: You should see logs confirming:
  - `Initializing SentenceTransformer...`
  - `Connected to collection: 'farming_knowledge'`
  - `Running on http://127.0.0.1:8000`

### Step 2: Start the Laravel Backend API Server
Open a second terminal, navigate to `backend`, and start PHP serve on port `8001`:
```bash
cd "backend"
php artisan serve --port=8001
```
- **Validation**: You should see output confirming:
  - `Server running on [http://127.0.0.1:8001]`

### Step 3: Run the Flutter Mobile App
Make sure your Android Emulator or iOS Simulator is active, navigate to `frontend` in a third terminal, and boot the application:
```bash
cd "frontend"
flutter run
```
- **Validation**: Under `lib/services/api_service.dart`, verify that the endpoints are set to the correct Laravel port:
  ```dart
  static const String baseUrl = 'http://10.0.2.2:8001/api';
  static const String appUrl = 'http://10.0.2.2:8001';
  ```

---

## 🧠 Chatbot Capabilities & Safety Guardrails

- **WhatsApp UI Styling**: High-fidelity, vibrant green chat bubbles with time formatting, dynamically scrolling list view, and smooth typing indicators.
- **RAG-based Semantic Advisor**: Embeds prompts and matches them against ChromaDB guidelines to formulate rich crop guidance.
- **Agricultural Safeguards**: Rejects non-farming topics (e.g., politics, coding) with a friendly reminder, and handles friendly user greetings gracefully.
- **Failure Tolerant**: Automatically falls back to high-quality instructions if the Python microservice goes offline, preventing mobile app crashes.
