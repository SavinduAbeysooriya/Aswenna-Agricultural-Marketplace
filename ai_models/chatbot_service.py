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

# Initialize Flask app
app = Flask(__name__)
CORS(app)

GROQ_API_KEY = "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"
GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"

# Paths to the newly trained NLP models
NLP_DIR = os.path.join(os.path.dirname(__file__), "nlp")
intent_classifier = None
intent_vectorizer = None
kb_vectorizer = None
kb_matrix = None
kb_database = None

def init_nlp_models():
    global intent_classifier, intent_vectorizer, kb_vectorizer, kb_matrix, kb_database
    try:
        print("Loading newly trained NLP models...")
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
        
        payload = {
            "model": "llama-3.3-70b-versatile",
            "messages": [
                {"role": "user", "content": prompt}
            ],
            "temperature": 0.1,
            "max_tokens": 20
        }
        response = requests.post(GROQ_URL, headers=headers, json=payload, timeout=5)
        if response.status_code == 200:
            optimized = response.json()['choices'][0]['message']['content'].strip().strip('"')
            print(f"Original Query: '{raw_query}' -> Optimized: '{optimized}'")
            return optimized
    except Exception as e:
        print(f"Failed to optimize query: {e}")
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
        payload = {
            "model": "llama-3.3-70b-versatile",
            "messages": [
                {"role": "user", "content": prompt}
            ],
            "temperature": 0.5,
            "max_tokens": 800
        }
        
        response = requests.post(GROQ_URL, headers=headers, json=payload, timeout=20)
        if response.status_code == 200:
            return response.json()['choices'][0]['message']['content']
    except Exception as e:
        print(f"Exception during Groq generation: {e}")

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
    data = request.get_json()
    if not data or 'question' not in data:
        return jsonify({"error": "Missing 'question' in request body"}), 400
        
    question = data['question']
    image_path = data.get('image_path')
    
    image_desc = None
    if image_path and os.path.exists(image_path):
        print(f"Processing uploaded image: {image_path}")
        image_desc = analyze_image_with_groq(image_path)
        print(f"Image analysis result: {image_desc}")
        
    # Optimize query for database search using Groq
    optimized_query = optimize_query_with_groq(question)
    
    # Combine optimized query and visual details for retrieval lookup
    search_query = f"{optimized_query}. {image_desc}" if image_desc else optimized_query
    
    # Retrieve local knowledge context
    kb_match, intent = retrieve_kb_context(search_query)
    
    # Generate RAG response
    answer = generate_response_with_groq(
        question=question,
        image_description=image_desc,
        kb_match=kb_match,
        intent=intent
    )
    
    return jsonify({
        "answer": answer,
        "intent": intent,
        "matched": kb_match is not None
    })

if __name__ == '__main__':
    init_nlp_models()
    app.run(host='127.0.0.1', port=8000, debug=False)
