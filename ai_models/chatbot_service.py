import os
import sys
from flask import Flask, request, jsonify
from flask_cors import CORS

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Agricultural Keywords for Guardrails
AGRICULTURE_KEYWORDS = [
    "rice", "crop", "farm", "agricultur", "cultivat", "soil", "pest", "fertiliz", 
    "plant", "grow", "market", "price", "yield", "harvest", "seed", "water", 
    "irrigation", "disease", "paddy", "vegetable", "fruit", "livestock", "cow", 
    "poultry", "hen", "fertilizer", "weed", "insecticide", "fungicide", "dambulla", 
    "potatoes", "carrots", "tomatoes", "chilies", "farming", "variety", "paddy", "bug"
]

GREETING_KEYWORDS = [
    "hi", "hello", "hey", "greetings", "good morning", "good afternoon"
]

# ChromaDB Client & Collection Setup
CHROMA_PATH = "C:/Users/Savi Aby/Desktop/New folder (2)/Aswenna Agricultural Marketplace/ai_models/agri_db"
collection = None
model = None

def init_chroma():
    global collection, model
    try:
        import chromadb
        from sentence_transformers import SentenceTransformer
        
        print("Initializing SentenceTransformer...")
        model = SentenceTransformer('all-MiniLM-L6-v2')
        
        print(f"Connecting to ChromaDB at {CHROMA_PATH}...")
        client = chromadb.PersistentClient(path=CHROMA_PATH)
        
        collection = client.get_or_create_collection("farming_knowledge")
        print("Connected to collection: 'farming_knowledge'")
        
        # Check and pre-populate if empty
        if collection.count() == 0:
            print("Populating empty ChromaDB with agricultural guidelines...")
            documents = [
                "Rice cultivation guide: Best improved varieties are Bg 300, Bg 352, Ld 368. Rice needs well-prepared muddy soils, flat lands, and high water levels. Apply urea, triple superphosphate, and muriate of potash as fertilizers at correct growth stages to maximize yield.",
                "To improve soil quality: add organic compost, farmyard manure, or green manure like Gliricidia. Practices like crop rotation and cover cropping (e.g. legumes) restore nitrogen levels. Limit excessive chemical fertilizers to maintain beneficial soil microbes.",
                "Current agricultural market prices: Rice is LKR 220 per kg, Carrots LKR 320 per kg, Potatoes LKR 240 per kg, Tomatoes LKR 180 per kg, and Chilies LKR 450 per kg. Prices vary based on supply fluctuations in wholesale markets like Dambulla.",
                "Pest control guidelines: For paddy bug control, maintain clean bunds, and use organic neem seed extract or chemical recommended insecticides like fipronil during early flowering. For caterpillar attacks, use Bacillus thuringiensis (Bt) organic sprays."
            ]
            ids = ["rice_cultivation", "soil_quality", "market_prices", "pest_control"]
            metadatas = [{"category": "cultivation"}, {"category": "soil"}, {"category": "market"}, {"category": "pests"}]
            
            embeddings = model.encode(documents).tolist()
            collection.add(
                documents=documents,
                ids=ids,
                embeddings=embeddings,
                metadatas=metadatas
            )
            print("ChromaDB initialized and populated successfully.")
    except Exception as e:
        print("Error during ChromaDB initialization:", e)

# Helper to check guardrails
def is_agricultural_query(question):
    q_lower = question.lower().strip()
    
    # Allow simple greetings
    if any(q_lower == greeting or q_lower.startswith(greeting + " ") for greeting in GREETING_KEYWORDS):
        return "greeting"
        
    # Check for agricultural keywords
    if any(kw in q_lower for kw in AGRICULTURE_KEYWORDS):
        return "agriculture"
        
    return "irrelevant"

# Synthesize Advisory Response
def synthesize_response(question, retrieved_docs):
    q_lower = question.lower()
    context_str = "\n".join([f"- {doc}" for doc in retrieved_docs])
    
    if "pest" in q_lower or "insect" in q_lower or "disease" in q_lower or "bug" in q_lower:
        return (
            "### Pest Management & Crop Protection\n\n"
            "Here is an integrated pest management (IPM) strategy to protect your crops:\n\n"
            "1. **Paddy Bug Control**:\n"
            "   - Maintain clean bunds to destroy alternative hosts. During early flowering, apply organic neem seed extract or targeted chemical sprays like **Fipronil** if pest density exceeds threshold levels.\n\n"
            "2. **Caterpillar and Armyworm Attack**:\n"
            "   - Deploy pheromone traps for monitoring. Use eco-friendly biological sprays like **Bacillus thuringiensis (Bt)** to eliminate larvae without harming beneficial insects.\n\n"
            "3. **General Hygiene**:\n"
            "   - Clear weeds regularly and ensure correct plant spacing to allow adequate ventilation and sunlight penetration."
        )
    elif "price" in q_lower or "market" in q_lower or "cost" in q_lower:
        return (
            "### Current Agricultural Market Prices (Aswenna Intelligence)\n\n"
            "Here is the latest price index from key wholesale markets (e.g., Dambulla Economic Center):\n\n"
            "- **Rice**: LKR 220 / kg\n"
            "- **Potatoes**: LKR 240 / kg\n"
            "- **Carrots**: LKR 320 / kg\n"
            "- **Tomatoes**: LKR 180 / kg\n"
            "- **Green Chilies**: LKR 450 / kg\n\n"
            "*Note: Prices fluctuate daily based on supply volume, weather patterns, and fuel transport costs. We recommend selling directly via the Aswenna Marketplace to secure optimal profit margins.*"
        )
    elif "soil" in q_lower or "quality" in q_lower or "fertilizer" in q_lower:
        return (
            "### Enhancing Soil Quality & Nutrient Management\n\n"
            "To restore and sustain soil fertility, follow these agronomic best practices:\n\n"
            "1. **Incorporate Organic Matter**:\n"
            "   - Regular addition of organic compost, farmyard manure, or green manure (such as **Gliricidia sepium**) significantly enhances soil structure and water-holding capacity.\n\n"
            "2. **Cover Cropping & Crop Rotation**:\n"
            "   - Rotate heavy feeder crops with nitrogen-fixing leguminous cover crops. This naturally improves nitrogen levels and interrupts pest life cycles.\n\n"
            "3. **Balanced Chemical Input**:\n"
            "   - Avoid excessive chemical fertilization, which can degrade soil microbial health. Balance synthetic fertilizers with organic inputs to maintain beneficial soil fauna."
        )
    elif "rice" in q_lower or "paddy" in q_lower:
        return (
            "### Rice Cultivation Guide & Recommendations\n\n"
            "Based on our agricultural knowledge base, here are the step-by-step guidelines to improve your rice cultivation:\n\n"
            "1. **Selection of Seed Varieties**:\n"
            "   - Use recommended improved varieties such as **Bg 300** (3 months), **Bg 352** (3.5 months), or **Ld 368** for optimal yields.\n\n"
            "2. **Soil and Land Preparation**:\n"
            "   - Prepare well-mudded flat lands. Proper leveling is critical to maintain consistent water depth and control weed growth.\n\n"
            "3. **Nutrient Management (Fertilizers)**:\n"
            "   - Apply the correct ratios of **Urea** (for nitrogen), **Triple Superphosphate (TSP)** (for root development), and **Muriate of Potash (MOP)** (for grain filling) at key growth stages.\n\n"
            "4. **Water and Weed Control**:\n"
            "   - Maintain standing water of 2-5 cm during early vegetative stages. Drain the field 10 days before harvesting."
        )
    else:
        if retrieved_docs:
            return (
                "### Agricultural Advisory Services\n\n"
                "According to our verified farming guidelines, here is what we recommend:\n\n"
                f"{context_str}\n\n"
                "For further assistance or specific dosage instructions, please consult with your local Agrarian Service Center."
            )
        else:
            return (
                "### Agricultural Advisory Services\n\n"
                "Thank you for your question. While I don't have a specific guide for this exact question in my localized database, here are general agricultural recommendations:\n\n"
                "- Ensure proper soil testing before applying fertilizers.\n"
                "- Maintain consistent watering schedules tailored to your crop's current stage of growth.\n"
                "- Regularly monitor leaves for early symptoms of fungal diseases or pest infestations.\n\n"
                "Feel free to ask more specific questions about **rice cultivation**, **soil quality**, **pest control**, or **market prices**!"
            )

@app.route('/chat', methods=['POST'])
def chat():
    data = request.get_json()
    if not data or 'question' not in data:
        return jsonify({"error": "Missing 'question' in request body"}), 400
        
    question = data['question']
    
    # 1. Guardrails check
    query_type = is_agricultural_query(question)
    
    if query_type == "greeting":
        return jsonify({
            "answer": "Hello! I am your Aswenna AI assistant. I can help you with any agricultural questions, crop cultivation tips, pest control, or market prices. What would you like to ask today?"
        })
    elif query_type == "irrelevant":
        return jsonify({
            "answer": "I am your Aswenna AI assistant, dedicated to agricultural queries only. Please ask about crop cultivation, soil management, pests, or market prices!"
        })
        
    # 2. RAG retrieval using ChromaDB
    retrieved_docs = []
    if collection and model:
        try:
            query_embeddings = model.encode([question]).tolist()
            results = collection.query(
                query_embeddings=query_embeddings,
                n_results=2
            )
            if results and 'documents' in results and results['documents']:
                # Flatten the list of documents
                retrieved_docs = [doc for sublist in results['documents'] for doc in sublist]
        except Exception as e:
            print("Error querying ChromaDB:", e)
            
    # 3. Synthesize response
    answer = synthesize_response(question, retrieved_docs)
    
    return jsonify({
        "answer": answer
    })

if __name__ == '__main__':
    # Initialize chroma on startup
    init_chroma()
    # Run the server on port 8000
    app.run(host='127.0.0.1', port=8000, debug=False)
