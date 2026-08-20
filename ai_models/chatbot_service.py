import os
import sys
import base64
import re
import requests
import joblib
import pandas as pd
import numpy as np
from flask import Flask, request, jsonify
from flask_cors import CORS
from sklearn.metrics.pairwise import cosine_similarity
from dotenv import load_dotenv

# Load environment variables from backend directory
backend_env_path = os.path.join(os.path.dirname(__file__), "..", "backend", ".env")
load_dotenv(dotenv_path=backend_env_path)

# Initialize Flask app
app = Flask(__name__)
CORS(app)

GROQ_API_KEY = os.getenv("GROQ_API_KEY")
GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"

# Paths to the newly trained NLP models
NLP_DIR = os.path.join(os.path.dirname(__file__), "nlp")
intent_classifier = None
intent_vectorizer = None
kb_vectorizer = None
kb_matrix = None
kb_database = None

# Paths to the tabular ML models
TABULAR_DIR = os.path.join(os.path.dirname(__file__), "tabular")
crop_rec_model = None
crop_rec_encoder = None
crop_yield_model = None
crop_yield_area_encoder = None
crop_yield_item_encoder = None
fertilizer_model = None
fertilizer_soil_encoder = None
fertilizer_crop_encoder = None
fertilizer_name_encoder = None

def init_tabular_models():
    global crop_rec_model, crop_rec_encoder, crop_yield_model, crop_yield_area_encoder, crop_yield_item_encoder
    global fertilizer_model, fertilizer_soil_encoder, fertilizer_crop_encoder, fertilizer_name_encoder
    try:
        print("Loading Tabular ML Models...", flush=True)
        crop_rec_model = joblib.load(os.path.join(TABULAR_DIR, "crop_recommendation_model.pkl"))
        crop_rec_encoder = joblib.load(os.path.join(TABULAR_DIR, "crop_recommendation_encoder.pkl"))
        
        crop_yield_model = joblib.load(os.path.join(TABULAR_DIR, "crop_yield_model.pkl"))
        crop_yield_area_encoder = joblib.load(os.path.join(TABULAR_DIR, "crop_yield_area_encoder.pkl"))
        crop_yield_item_encoder = joblib.load(os.path.join(TABULAR_DIR, "crop_yield_item_encoder.pkl"))
        
        fertilizer_model = joblib.load(os.path.join(TABULAR_DIR, "fertilizer_recommendation_model.pkl"))
        fertilizer_soil_encoder = joblib.load(os.path.join(TABULAR_DIR, "fertilizer_soil_encoder.pkl"))
        fertilizer_crop_encoder = joblib.load(os.path.join(TABULAR_DIR, "fertilizer_crop_encoder.pkl"))
        fertilizer_name_encoder = joblib.load(os.path.join(TABULAR_DIR, "fertilizer_name_encoder.pkl"))
        print("Tabular ML Models loaded successfully!", flush=True)
    except Exception as e:
        print(f"Failed to load tabular models: {e}", flush=True)

def init_nlp_models():
    global intent_classifier, intent_vectorizer, kb_vectorizer, kb_matrix, kb_database
    try:
        print("Loading newly trained NLP models...", flush=True)
        print(f"GROQ_API_KEY loaded: {GROQ_API_KEY is not None} (Length: {len(GROQ_API_KEY) if GROQ_API_KEY else 0})", flush=True)
        intent_classifier = joblib.load(os.path.join(NLP_DIR, "intent_classifier.pkl"))
        intent_vectorizer = joblib.load(os.path.join(NLP_DIR, "intent_vectorizer.pkl"))
        kb_vectorizer = joblib.load(os.path.join(NLP_DIR, "kb_vectorizer.pkl"))
        kb_matrix = joblib.load(os.path.join(NLP_DIR, "kb_matrix.pkl"))
        kb_database = pd.read_parquet(os.path.join(NLP_DIR, "kb_database.parquet"))
        print(f"NLP models loaded successfully! Knowledge base size: {len(kb_database)} QA pairs.")
    except Exception as e:
        print(f"Error loading NLP models: {e}")

# Function to encode image to base64
def encode_image(image_path):
    with open(image_path, "rb") as image_file:
        return base64.b64encode(image_file.read()).decode('utf-8')

# Function to describe image using Groq Vision API
def analyze_image_with_groq(image_path):
    try:
        base64_image = encode_image(image_path)
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {GROQ_API_KEY}"
        }
        payload = {
            "model": "llama-3.2-11b-vision-preview",
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": "Describe what is visible in this agricultural image. Specifically list any crops, pests, leaf damage, diseases, or soil condition anomalies. Keep the description focused on factual agricultural details."
                        },
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{base64_image}"
                            }
                        }
                    ]
                }
            ],
            "temperature": 0.2
        }
        
        response = requests.post(GROQ_URL, headers=headers, json=payload, timeout=20)
        if response.status_code == 200:
            return response.json()['choices'][0]['message']['content']
        else:
            print(f"Groq Vision API Error: {response.text}")
    except Exception as e:
        print(f"Exception during image analysis: {e}")
    return "An agricultural image was uploaded but couldn't be analyzed."

def optimize_query_with_groq(raw_query):
    try:
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {GROQ_API_KEY}"
        }
        prompt = f"""You are an agricultural search optimizer. Convert the conversational user query into a clean search-optimized query containing only key nouns and verbs related to the crop and issue. Remove all greetings, punctuation, and typos.
Example:
Input: "Hi in mypaddyfield rice plants color are goes yellow, this now ready for harvest?"
Output: "rice plant harvesting yellow color maturity"

Input: "{raw_query}"
Output (provide ONLY the optimized keyword phrase, no other text):"""
        
        models = ["openai/gpt-oss-120b", "openai/gpt-oss-20b", "qwen/qwen3.6-27b"]
        for m in models:
            payload = {
                "model": m,
                "messages": [
                    {"role": "user", "content": prompt}
                ],
                "temperature": 0.1,
                "max_tokens": 20
            }
            response = requests.post(GROQ_URL, headers=headers, json=payload, timeout=5)
            if response.status_code == 200:
                optimized = response.json()['choices'][0]['message']['content']
                if "<think>" in optimized:
                    optimized = re.sub(r'<think>.*?</think>', '', optimized, flags=re.DOTALL)
                optimized = optimized.strip().strip('"')
                print(f"Original Query: '{raw_query}' -> Optimized: '{optimized}'", flush=True)
                return optimized
            else:
                print(f"Groq Query Optimization API Error ({m}): {response.status_code} - {response.text}", flush=True)
    except Exception as e:
        print(f"Failed to optimize query: {e}", flush=True)
    return raw_query

# Retrieve best matching answer from the local database using TF-IDF similarity
def retrieve_kb_context(query, threshold=0.25):
    if kb_vectorizer is None or kb_matrix is None or kb_database is None:
        return None, "general_crop_advice"
        
    query_vec = kb_vectorizer.transform([query])
    sims = cosine_similarity(query_vec, kb_matrix).flatten()
    best_idx = np.argmax(sims)
    
    intent = "general_crop_advice"
    try:
        intent_vec = intent_vectorizer.transform([query])
        intent = intent_classifier.predict(intent_vec)[0]
    except Exception as e:
        print(f"Intent classification failed: {e}")
        
    if sims[best_idx] >= threshold:
        match_row = kb_database.iloc[best_idx]
        
        # Verify that the retrieved QA doesn't cross crop topics
        query_lower = query.lower()
        matched_q = match_row["question"].lower()
        matched_a = match_row["answer"].lower()
        
        crops = ["banana", "rice", "paddy", "carrot", "potato", "tomato", "chili", "sugarcane", "radish", "coconut"]
        for crop in crops:
            if crop in query_lower:
                # If query is about a crop, check if match covers it. 
                # If match covers OTHER crops but not this crop, discard the match!
                other_crops = [c for c in crops if c != crop]
                has_other_crop = any(oc in matched_q or oc in matched_a for oc in other_crops)
                has_this_crop = (crop in matched_q or crop in matched_a)
                if has_other_crop and not has_this_crop:
                    print(f"Discarding mismatched crop match: query mentions '{crop}', match mentions other crops.")
                    return None, intent

        return {
            "question": match_row["question"],
            "answer": match_row["answer"],
            "intent": match_row.get("intent", intent),
            "score": float(sims[best_idx])
        }, intent
        
    return None, intent

OFFLINE_KNOWLEDGE = {
    "rice": {
        "pest_control": (
            "### Rice Pest & Disease Management\n\n"
            "Based on expert agronomic guidelines, protect your paddy fields with these steps:\n\n"
            "- **Paddy Bug**: Maintain clean bunds to destroy alternate hosts. During early flowering, apply organic neem seed extract or targeted chemical sprays like **Fipronil**.\n"
            "- **Brown Planthopper (BPH)**: Drain the field to disrupt BPH breeding. Avoid excessive nitrogen applications.\n"
            "- **Blast Disease**: Ensure balanced silica and nitrogen fertilization. Spray recommended fungicides if leaf lesions appear."
        ),
        "soil_management": (
            "### Rice Soil & Land Preparation\n\n"
            "To restore and sustain soil fertility in paddy fields:\n\n"
            "- **Puddling**: Prepare well-puddled muddy soil to prevent water percolation and weed growth.\n"
            "- **Organic Matter**: Incorporate straw, compost, or green manure like **Gliricidia** to enhance organic carbon levels.\n"
            "- **pH Control**: Rice grows best in slightly acidic to neutral soils (pH 5.5 - 6.5)."
        ),
        "fertilizer_scheduling": (
            "### Rice Fertilizer Scheduling\n\n"
            "Ensure balanced fertilization at correct crop growth stages:\n\n"
            "- **Basal Dressing**: Apply Phosphorus (TSP) and a portion of Nitrogen (Urea) and Potassium (MOP) during land preparation.\n"
            "- **Top Dressing**: Apply Urea at tillering (2-3 weeks) and panicle initiation (5-7 weeks).\n"
            "- **NPK Ratios**: Follow recommended department guidelines based on your regional soil type."
        ),
        "irrigation": (
            "### Rice Water Management\n\n"
            "Maintain correct irrigation levels for paddy crops:\n\n"
            "- **Vegetative Stage**: Maintain standing water of 2-5 cm to suppress weed germination.\n"
            "- **Harvest Preparation**: Drain the field 10-14 days before harvest to facilitate uniform ripening and easy harvesting."
        ),
        "general_crop_advice": (
            "### Rice Cultivation & Harvesting Guidelines\n\n"
            "- **Harvesting Indicators**: Rice is ready for harvest when grains turn yellow/golden (about 80-85% of the panicles), and moisture content drops to 20-22%. Grain should be firm when squeezed.\n"
            "- **Spacing**: Space transplanted seedlings at 20 x 15 cm or 15 x 15 cm for optimal ventilation and sunlight.\n"
            "- **Seed Selection**: Use certified seed varieties (e.g. Bg 352, Ld 368) suited for your ecological zone."
        )
    },
    "banana": {
        "pest_control": (
            "### Banana Pest & Disease Management\n\n"
            "To protect your banana plantation:\n\n"
            "- **Panama Wilt**: Plant resistant varieties and maintain strict sanitation. Avoid waterlogging.\n"
            "- **Sigatoka Leaf Spot**: Remove diseased leaves regularly. Spray recommended mineral oils or fungicides."
        ),
        "soil_management": (
            "### Banana Soil Requirements\n\n"
            "- **Drainage**: Bananas require rich, deep, well-draining loamy soils. Waterlogging will lead to root rot.\n"
            "- **Organic Compost**: Apply heavy doses of organic manure to supply potassium and nitrogen."
        ),
        "fertilizer_scheduling": (
            "### Banana Fertilization\n\n"
            "- **High Potassium**: Bananas are heavy feeders, especially of potassium. Apply muriate of potash (MOP) regularly during growth."
        ),
        "irrigation": (
            "### Banana Irrigation\n\n"
            "- **Consistent Moisture**: Provide regular irrigation, especially during flowering and fruit development."
        ),
        "general_crop_advice": (
            "### Banana Harvesting & Care\n\n"
            "- **Harvesting Indicators**: Bananas are ready to harvest when fruits become less angular and more rounded, and the top leaves start to dry/yellow.\n"
            "- **Spacing**: Maintain spacing of 2.5 x 2.5 meters to prevent overcrowding."
        )
    },
    "tomato": {
        "pest_control": (
            "### Tomato Pest & Disease Management\n\n"
            "To manage tomato diseases and pests:\n\n"
            "- **Fruit Borer**: Use pheromone traps or spray Bacillus thuringiensis (Bt) or recommended insecticidal sprays.\n"
            "- **Late Blight**: Ensure good spacing and staking to keep leaves dry. Apply copper fungicides if blight is detected."
        ),
        "soil_management": (
            "### Tomato Soil Preparation\n\n"
            "- **pH Range**: Tomato grows best in well-draining sandy loam with pH 6.0 - 6.8.\n"
            "- **Calcium**: Apply dolomite or gypsum to prevent blossom end rot (calcium deficiency)."
        ),
        "fertilizer_scheduling": (
            "### Tomato Fertilization\n\n"
            "- **Nitrogen Balance**: Limit high nitrogen fertilizer during flowering to prevent excessive vine growth at the expense of fruit."
        ),
        "irrigation": (
            "### Tomato Irrigation\n\n"
            "- **Deep Watering**: Water deeply and consistently. Fluctuations in moisture cause fruit cracking."
        ),
        "general_crop_advice": (
            "### Tomato Cultivation & Harvesting\n\n"
            "- **Harvesting Indicators**: Harvest tomatoes when they turn pinkish-red. Pick regularly to encourage more fruit production.\n"
            "- **Support**: Stake or cage tomato plants to keep fruit off the ground and reduce rot and pest infestation."
        )
    },
    "potato": {
        "pest_control": (
            "### Potato Pest & Disease Management\n\n"
            "For potato crop protection:\n\n"
            "- **Late Blight**: Plant certified seed tubers and use prophylactic fungicide sprays during cold, humid weather.\n"
            "- **Potato Tuber Moth**: Hill the plants properly to cover developing tubers from egg-laying moths."
        ),
        "soil_management": (
            "### Potato Soil Preparation\n\n"
            "- **Loose Soil**: Potatoes require loose, well-aerated, sandy loam soils to allow tuber expansion."
        ),
        "fertilizer_scheduling": (
            "### Potato Fertilization\n\n"
            "- **NPK Balance**: High potassium is required for starch synthesis and tuber bulking."
        ),
        "irrigation": (
            "### Potato Irrigation\n\n"
            "- **Even Moisture**: Keep soil evenly moist, particularly during tuber initiation and bulking."
        ),
        "general_crop_advice": (
            "### Potato Harvesting & Care\n\n"
            "- **Harvesting Indicators**: Potatoes are ready for harvest when the vines turn yellow and die back. Leave tubers in soil for 1-2 weeks to cure the skins before digging.\n"
            "- **Greening Safety**: Keep tubers covered with soil (hilling) to prevent greening (solanine production)."
        )
    },
    "carrot": {
        "pest_control": (
            "### Carrot Pest & Disease Management\n\n"
            "- **Root Knot Nematode**: Practice crop rotation with marigolds and keep soil solarized.\n"
            "- **Leaf Blight (Alternaria)**: Space plants correctly to allow airflow and avoid overhead watering. Spray copper-based fungicides if leaf spots appear."
        ),
        "soil_management": (
            "### Carrot Soil Requirements\n\n"
            "- **Soil Type**: Carrots require deep, loose, well-draining sandy loam soils. Stony or heavy clay soils cause root splitting and branching.\n"
            "- **pH Range**: Optimal soil pH is 5.5 - 6.5. Apply organic compost well in advance of planting."
        ),
        "fertilizer_scheduling": (
            "### Carrot Fertilization\n\n"
            "- **NPK Balance**: Avoid excessive nitrogen fertilizers as they cause hairy roots and leaf growth instead of root development. Apply balanced Potassium (MOP) to encourage root sweetening."
        ),
        "irrigation": (
            "### Carrot Irrigation\n\n"
            "- **Consistent Water**: Maintain even soil moisture. Dry soil followed by heavy watering causes root cracking."
        ),
        "general_crop_advice": (
            "### Carrot Cultivation & Climate Guidelines\n\n"
            "- **Suitable Provinces/Locations**: In Sri Lanka, carrots grow best in the **Central Province (Nuwara Eliya)** and the **Uva Province (Welimada, Badulla)**.\n"
            "- **Climate & Temperature**: Carrots require a cool climate with optimal temperatures between **15°C to 20°C**.\n"
            "- **Cultivation Zones**: Upcountry wet and intermediate zones (elevations above 1,000 meters)."
        )
    },
    "chili": {
        "pest_control": (
            "### Chili Pest & Disease Management\n\n"
            "- **Thrips & Mites**: Leaf curling is typically caused by thrips (curls upward) or mites (curls downward). Spray organic neem oil or recommended acaricides/insecticides.\n"
            "- **Anthracnose (Fruit Rot)**: Use disease-free seeds and remove affected fruits. Apply copper-based fungicides during humid weather."
        ),
        "soil_management": (
            "### Chili Soil Requirements\n\n"
            "- **Soil Type**: Chilis thrive in well-drained loamy soils rich in organic matter. Waterlogging is highly detrimental to root health."
        ),
        "fertilizer_scheduling": (
            "### Chili Fertilization\n\n"
            "- **Nitrogen & Potassium**: Apply basal fertilizer during land preparation. Apply top dressing of nitrogen and potassium at flowering to increase fruit set."
        ),
        "irrigation": (
            "### Chili Irrigation\n\n"
            "- **Moderate Watering**: Chilis require moderate moisture. Irrigate when the topsoil is dry, but avoid over-irrigation."
        ),
        "general_crop_advice": (
            "### Chili Cultivation Guidelines\n\n"
            "- **Suitable Locations**: Grown extensively in the dry zones of Sri Lanka (Anuradhapura, Puttalam, Jaffna, Vavuniya).\n"
            "- **Climate**: Requires a hot, warm climate with temperatures between **20°C to 30°C**."
        )
    }
}

# Use Groq to synthesize a conversational RAG response grounded in local knowledge
def generate_response_with_groq(question, image_description=None, kb_match=None, intent="general_crop_advice"):
    context_bullet = ""
    if kb_match:
        context_bullet = f"Retrieved Verified Guidelines (Similarity: {kb_match['score']:.2f}):\n- Question: {kb_match['question']}\n- Answer: {kb_match['answer']}"
    else:
        context_bullet = "No direct database match found. Provide general agronomic best practices."

    image_info = f"Uploaded Image Details: {image_description}" if image_description else ""

    prompt = f"""You are 'Aswenna AI Assistant', a premium WhatsApp-style agricultural advisor helper.
Your role is to assist farmers, retailers, and buyers with their agricultural questions.

User Query: {question}
{image_info}
Category Intent: {intent}
{context_bullet}

Instructions:
1. Ground your response in the Retrieved Verified Guidelines if they are relevant to the crop the user is asking about.
2. CRITICAL: If the Retrieved Verified Guidelines discuss a different crop than what the user asked about (e.g. they discuss banana but the user is asking about rice/paddy), DISCARD the guidelines. DO NOT mention bananas in your response. Instead, answer the user's question about their specific crop (e.g. rice) directly using your general agricultural expertise.
3. Keep the response practical, direct, and structured with bullet points.
4. If the query is completely unrelated to agriculture, politely decline and steer back to farming topics.
5. Limit the response to a maximum of 3 concise paragraphs.
"""
    try:
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {GROQ_API_KEY}"
        }
        models = ["openai/gpt-oss-120b", "openai/gpt-oss-20b", "qwen/qwen3.6-27b"]
        last_err = None
        for m in models:
            payload = {
                "model": m,
                "messages": [
                    {"role": "user", "content": prompt}
                ],
                "temperature": 0.5,
                "max_tokens": 800
            }
            response = requests.post(GROQ_URL, headers=headers, json=payload, timeout=20)
            if response.status_code == 200:
                res_content = response.json()['choices'][0]['message']['content']
                if "<think>" in res_content:
                    res_content = re.sub(r'<think>.*?</think>', '', res_content, flags=re.DOTALL)
                return res_content.strip()
            else:
                last_err = f"Groq API Error ({m}): {response.status_code} - {response.text}"
                print(last_err, flush=True)
        
        if last_err:
            raise Exception(last_err)
    except Exception as e:
        print(f"Exception during Groq generation: {e}", flush=True)
        raise e

    # --- OFFLINE/FALLBACK MULTI-STAGE LOGIC ---
    # 1. Check offline crop-specific database first
    query_lower = question.lower()
    for crop_key, crop_intents in OFFLINE_KNOWLEDGE.items():
        aliases = [crop_key]
        if crop_key == "rice":
            aliases.append("paddy")
            
        if any(alias in query_lower for alias in aliases):
            if intent in crop_intents:
                return crop_intents[intent]
            return crop_intents.get("general_crop_advice", list(crop_intents.values())[0])

    # 2. Check local database match if available
    if kb_match:
        return f"### {intent.replace('_', ' ').title()}\n\n{kb_match['answer']}"
        
    # 3. High-quality intent-based direct fallback
    if intent == "pest_control":
        return (
            "### Pest Control & Crop Protection\n\n"
            "Based on verified agronomic practices, here are the recommendations for crop protection:\n\n"
            "- **Organic Controls**: Use neem seed kernel extract (NSKE 5%) or garlic-chili spray to repel insects naturally.\n"
            "- **Cultural Practices**: Maintain clean bunds and weed-free field margins to eliminate alternate hosts.\n"
            "- **Chemical Controls**: If pest thresholds are exceeded, consult with your local extension officer for approved target-specific pesticides."
        )
    elif intent == "soil_management":
        return (
            "### Soil Quality & Health Management\n\n"
            "To restore and sustain soil fertility, follow these agronomic recommendations:\n\n"
            "- **Organic Matter**: Incorporate compost, cow manure, or green leaf manure like Gliricidia to improve soil structure.\n"
            "- **Cover Cropping**: Grow legumes (e.g. mung bean, sunn hemp) between cultivation cycles to naturally fix nitrogen.\n"
            "- **pH Control**: Perform soil testing. Add lime/dolomite for acidic soils or gypsum for alkaline soils as advised."
        )
    elif intent == "fertilizer_scheduling":
        return (
            "### Fertilizer Application Guide\n\n"
            "Ensure balanced fertilizer applications based on your crop growth stage:\n\n"
            "- **Basal Dressing**: Apply Phosphorus (TSP) and a portion of Nitrogen (Urea) and Potassium (MOP) during land preparation.\n"
            "- **Top Dressing**: Apply Nitrogen at key growth stages (e.g., tillering, panicle initiation for rice).\n"
            "- **Micronutrients**: Look for leaf yellowing or stunted growth which may indicate zinc or magnesium deficiencies."
        )
    elif intent == "irrigation":
        return (
            "### Water Management & Irrigation\n\n"
            "Optimal water levels are critical for crop development:\n\n"
            "- **Rice/Paddy**: Keep standing water of 2-5 cm during vegetative phases. Drain the field 10-14 days before harvest.\n"
            "- **Other Crops**: Implement drip or sprinkler irrigation to conserve water and prevent root rot.\n"
            "- **Drainage**: Ensure proper drainage channels to prevent waterlogging during heavy monsoon rains."
        )
    else:
        return (
            "### Agricultural Advisory Services\n\n"
            "Here are general agronomic recommendations to maximize crop output:\n\n"
            "- **Seed Selection**: Use certified seed varieties recommended for your agro-ecological zone.\n"
            "- **Spacing**: Maintain correct planting density to allow adequate sunlight and airflow, reducing fungal risks.\n"
            "- **Monitoring**: Inspect your fields twice a week for early signs of leaf yellowing, spots, or pest activity."
        )

@app.route('/chat', methods=['POST'])
def chat():
    data = request.get_json() or {}
    question = data.get('question') or data.get('message')
    if not question:
        return jsonify({"error": "Missing 'message' or 'question' in request body"}), 400
    image_path = data.get('image_path')
    
    image_desc = None
    debug_info = {}
    if image_path and os.path.exists(image_path):
        try:
            image_desc = analyze_image_with_groq(image_path)
        except Exception as e:
            debug_info["image_error"] = str(e)
            
    # Optimize query for database search using Groq
    optimized_query = question
    try:
        optimized_query = optimize_query_with_groq(question)
    except Exception as e:
        debug_info["optimize_error"] = str(e)
        
    # Combine optimized query and visual details for retrieval lookup
    search_query = f"{optimized_query}. {image_desc}" if image_desc else optimized_query
    
    # Retrieve local knowledge context
    kb_match, intent = retrieve_kb_context(search_query)
    
    # Generate RAG response
    answer = None
    try:
        answer = generate_response_with_groq(
            question=question,
            image_description=image_desc,
            kb_match=kb_match,
            intent=intent
        )
    except Exception as e:
        debug_info["generation_error"] = str(e)
        
        # --- OFFLINE/FALLBACK MULTI-STAGE LOGIC (Local execution on exception) ---
        query_lower = question.lower()
        matched_crop = False
        for crop_key, crop_intents in OFFLINE_KNOWLEDGE.items():
            aliases = [crop_key]
            if crop_key == "rice":
                aliases.append("paddy")
            if any(alias in query_lower for alias in aliases):
                matched_crop = True
                if intent in crop_intents:
                    answer = crop_intents[intent]
                else:
                    answer = crop_intents.get("general_crop_advice", list(crop_intents.values())[0])
                break
                
        if not matched_crop:
            if kb_match:
                answer = f"### {intent.replace('_', ' ').title()}\n\n{kb_match['answer']}"
            else:
                if intent == "pest_control":
                    answer = "### Pest Control & Crop Protection\n\n..."
                else:
                    answer = "### Agricultural Advisory Services\n\n..."
            
    return jsonify({
        "answer": answer,
        "intent": intent,
        "matched": kb_match is not None,
        "debug_info": debug_info,
        "optimized_query": optimized_query
    })

@app.route('/predict', methods=['POST'])
def predict():
    # Allow tabular model predictions
    data = request.get_json() or {}
    
    # 1. Crop Recommendation inputs
    nitrogen = float(data.get("nitrogen", 50))
    phosphorus = float(data.get("phosphorus", 50))
    potassium = float(data.get("potassium", 50))
    temp = float(data.get("temperature", 28.0))
    humidity = float(data.get("humidity", 75.0))
    ph = float(data.get("ph", 6.5))
    rainfall = float(data.get("rainfall", 1000.0))
    
    # 2. Crop Yield inputs
    area_name = data.get("area_name", "Sri Lanka")
    crop_name = data.get("crop_name", "Rice")
    year = int(data.get("year", 2026))
    pesticide_tonnes = float(data.get("pesticide_tonnes", 10.0))
    land_size = float(data.get("land_size", 1.0)) # in hectares/acres for scaling output
    
    # 3. Fertilizer recommendation inputs
    soil_moisture = float(data.get("soil_moisture", 45))
    soil_temp = float(data.get("soil_temperature", temp))
    soil_type = data.get("soil_type", "Loamy")
    
    predictions = {}
    
    # Crop Recommendation Prediction
    if crop_rec_model and crop_rec_encoder:
        try:
            # Features: ['Nitrogen', 'Phosphorus', 'Potassium', 'Temperature', 'Humidity', 'pH_Value', 'Rainfall']
            rec_cols = ['Nitrogen', 'Phosphorus', 'Potassium', 'Temperature', 'Humidity', 'pH_Value', 'Rainfall']
            rec_df = pd.DataFrame([[nitrogen, phosphorus, potassium, temp, humidity, ph, rainfall]], columns=rec_cols)
            rec_class = crop_rec_model.predict(rec_df)[0]
            recommended_crop = crop_rec_encoder.inverse_transform([rec_class])[0]
            predictions["recommended_crop"] = recommended_crop
        except Exception as e:
            predictions["recommended_crop_error"] = str(e)
            
    # Crop Yield Forecasting Prediction
    if crop_yield_model and crop_yield_area_encoder and crop_yield_item_encoder:
        try:
            def safe_encode(encoder, val, fallback_val="Sri Lanka"):
                try:
                    if val not in encoder.classes_:
                        for c in encoder.classes_:
                            if c.lower() == val.lower():
                                return encoder.transform([c])[0]
                        return encoder.transform([fallback_val])[0]
                    return encoder.transform([val])[0]
                except:
                    return 0
            
            enc_area = safe_encode(crop_yield_area_encoder, area_name, "Sri Lanka")
            mapped_crop = crop_name
            if crop_name.lower() in ["rice", "paddy"]:
                mapped_crop = "Rice, paddy"
            elif crop_name.lower() == "potato":
                mapped_crop = "Potatoes"
                
            enc_item = safe_encode(crop_yield_item_encoder, mapped_crop, "Rice, paddy")
            
            # Features: ['Area', 'Item', 'Year', 'average_rain_fall_mm_per_year', 'pesticides_tonnes', 'avg_temp']
            yield_cols = ['Area', 'Item', 'Year', 'average_rain_fall_mm_per_year', 'pesticides_tonnes', 'avg_temp']
            yield_df = pd.DataFrame([[enc_area, enc_item, year, rainfall, pesticide_tonnes, temp]], columns=yield_cols)
            predicted_yield_hg_ha = float(crop_yield_model.predict(yield_df)[0])
            
            # Convert yield: hg/ha to kg/acre
            yield_kg_ha = predicted_yield_hg_ha * 0.1
            yield_kg_acre = yield_kg_ha * 0.404686
            total_yield_kg = yield_kg_acre * land_size
            
            predictions["yield_forecast"] = {
                "yield_hg_ha": predicted_yield_hg_ha,
                "yield_kg_ha": yield_kg_ha,
                "yield_kg_acre": yield_kg_acre,
                "total_expected_yield_kg": total_yield_kg
            }
        except Exception as e:
            predictions["yield_forecast_error"] = str(e)
            
    # Fertilizer Recommendation Prediction
    if fertilizer_model and fertilizer_soil_encoder and fertilizer_crop_encoder and fertilizer_name_encoder:
        try:
            def safe_encode(encoder, val, default_val):
                try:
                    cleaned = val.strip().title()
                    for c in encoder.classes_:
                        if c.lower().strip() == cleaned.lower().strip():
                            return encoder.transform([c])[0]
                    return encoder.transform([default_val])[0]
                except:
                    return 0
                    
            mapped_crop_type = crop_name
            if crop_name.lower() in ["rice", "paddy"]:
                mapped_crop_type = "Paddy"
                
            enc_soil = safe_encode(fertilizer_soil_encoder, soil_type, "Loamy")
            enc_crop = safe_encode(fertilizer_crop_encoder, mapped_crop_type, "Paddy")
            
            # Features: ['Temparature', 'Humidity', 'Moisture', 'Soil Type', 'Crop Type', 'Nitrogen', 'Potassium', 'Phosphorous']
            fert_cols = ['Temparature', 'Humidity', 'Moisture', 'Soil Type', 'Crop Type', 'Nitrogen', 'Potassium', 'Phosphorous']
            fert_df = pd.DataFrame([[soil_temp, humidity, soil_moisture, enc_soil, enc_crop, nitrogen, potassium, phosphorus]], columns=fert_cols)
            fert_class = fertilizer_model.predict(fert_df)[0]
            recommended_fertilizer = fertilizer_name_encoder.inverse_transform([fert_class])[0]
            
            predictions["recommended_fertilizer"] = recommended_fertilizer
        except Exception as e:
            predictions["recommended_fertilizer_error"] = str(e)
            
    return jsonify(predictions)

if __name__ == '__main__':
    init_nlp_models()
    init_tabular_models()
    app.run(host='127.0.0.1', port=8000, debug=False)
