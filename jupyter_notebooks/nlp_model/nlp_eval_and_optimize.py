import os
import joblib
import pandas as pd
import numpy as np
import shutil
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import GridSearchCV, StratifiedKFold
from sklearn.metrics import classification_report, accuracy_score
from sklearn.metrics.pairwise import cosine_similarity

# Paths
CWD = os.path.dirname(os.path.abspath(__file__))
PROCESSED_DATA_PATH = os.path.join(CWD, "datasets", "processed", "cleaned_agriculture_qa.csv")
MODELS_DIR = os.path.join(CWD, "models")
DEPLOY_DIR = r"C:\Users\Savi Aby\Desktop\New folder (2)\Aswenna Agricultural Marketplace\ai_models\nlp"

def fine_tune_and_evaluate():
    print("--------------------------------------------------")
    print("STEP 1: Loading Processed QA Dataset...")
    print("--------------------------------------------------")
    if not os.path.exists(PROCESSED_DATA_PATH):
        raise FileNotFoundError(f"Processed dataset not found at {PROCESSED_DATA_PATH}")
        
    df = pd.read_csv(PROCESSED_DATA_PATH).dropna()
    print(f"Dataset shape: {df.shape}")
    print(f"Intent distribution:\n{df['intent'].value_counts()}\n")

    X = df['question']
    y = df['intent']

    print("--------------------------------------------------")
    print("STEP 2: Grid Search & Hyperparameter Fine-Tuning...")
    print("--------------------------------------------------")
    
    # Define hyperparameter grid for TF-IDF and Logistic Regression
    # We want to tune max_features, n-gram ranges, sublinear TF scaling, and regularization C strength
    skf = StratifiedKFold(n_splits=3, shuffle=True, random_state=42)
    
    best_acc = 0.0
    best_params = {}
    best_vectorizer = None
    best_classifier = None

    # Grid parameters
    max_features_options = [2000, 3500]
    ngram_range_options = [(1, 1), (1, 2)]
    sublinear_options = [True, False]
    C_options = [0.1, 1.0, 10.0]

    for max_feat in max_features_options:
        for ngram in ngram_range_options:
            for sublinear in sublinear_options:
                # Vectorize text
                vec = TfidfVectorizer(max_features=max_feat, ngram_range=ngram, sublinear_tf=sublinear, stop_words='english')
                X_vec = vec.fit_transform(X)
                
                for c_val in C_options:
                    # Run Cross-Validation
                    scores = []
                    for train_idx, val_idx in skf.split(X_vec, y):
                        X_tr, X_val = X_vec[train_idx], X_vec[val_idx]
                        y_tr, y_val = y.iloc[train_idx], y.iloc[val_idx]
                        
                        clf = LogisticRegression(C=c_val, max_iter=800, random_state=42)
                        clf.fit(X_tr, y_tr)
                        preds = clf.predict(X_val)
                        scores.append(accuracy_score(y_val, preds))
                        
                    mean_score = np.mean(scores)
                    print(f"Tuning -> max_features: {max_feat}, ngram: {ngram}, sublinear: {sublinear}, C: {c_val} | Mean Accuracy: {mean_score:.4f}")
                    
                    if mean_score > best_acc:
                        best_acc = mean_score
                        best_params = {"max_features": max_feat, "ngram_range": ngram, "sublinear_tf": sublinear, "C": c_val}
                        best_vectorizer = vec
                        best_classifier = clf

    print("\n--------------------------------------------------")
    print(f"BEST CONFIGURATION FOUND (Mean CV Accuracy: {best_acc:.4f})")
    print(best_params)
    print("--------------------------------------------------")

    # Fit best model on all training data
    print("Refitting best model on full dataset...")
    X_vec_best = best_vectorizer.fit_transform(X)
    clf_best = LogisticRegression(C=best_params["C"], max_iter=800, random_state=42)
    clf_best.fit(X_vec_best, y)

    # Save intent models
    os.makedirs(MODELS_DIR, exist_ok=True)
    joblib.dump(best_vectorizer, os.path.join(MODELS_DIR, "intent_vectorizer.pkl"))
    joblib.dump(clf_best, os.path.join(MODELS_DIR, "intent_classifier.pkl"))

    print("\n--------------------------------------------------")
    print("STEP 3: Indexing Semantic Knowledge Retrieval Matrix...")
    print("--------------------------------------------------")
    # Standardize KB Vectorizer with optimized sublinear TF scaling
    kb_vectorizer = TfidfVectorizer(ngram_range=(1, 2), sublinear_tf=True, stop_words='english')
    kb_matrix = kb_vectorizer.fit_transform(df['question'])
    
    # Save Knowledge Base Models
    joblib.dump(kb_vectorizer, os.path.join(MODELS_DIR, "kb_vectorizer.pkl"))
    joblib.dump(kb_matrix, os.path.join(MODELS_DIR, "kb_matrix.pkl"))
    df[['question', 'answer', 'intent']].to_parquet(os.path.join(MODELS_DIR, "kb_database.parquet"), index=False)
    print("Knowledge base index saved successfully.")

    print("\n--------------------------------------------------")
    print("STEP 4: External Validation Testing...")
    print("--------------------------------------------------")
    # Define unseen agricultural query test suite
    test_queries = [
        "What is the organic method to manage paddy bug infestations?",
        "My garden soil is too sandy and dry, how do I retain moisture?",
        "Which fertilizer contains nitrogen and should be applied during tillering?",
        "Can you suggest spacing guidelines for rice planting?",
        "what is the price of tomatoes today in economic centers?"
    ]

    for q in test_queries:
        intent_vec = best_vectorizer.transform([q])
        pred_intent = clf_best.predict(intent_vec)[0]
        
        # Test semantic retrieval
        q_vec = kb_vectorizer.transform([q])
        sims = cosine_similarity(q_vec, kb_matrix).flatten()
        best_idx = np.argmax(sims)
        score = sims[best_idx]
        matched_doc = df.iloc[best_idx]
        
        print(f"Test Query: '{q}'")
        print(f"-> Predicted Intent: {pred_intent}")
        print(f"-> Local RAG Match: '{matched_doc['question']}' (Similarity Score: {score:.4f})")
        print("-" * 50)

    print("\n--------------------------------------------------")
    print("STEP 5: Deploying Optimized Models to ai_models/nlp...")
    print("--------------------------------------------------")
    os.makedirs(DEPLOY_DIR, exist_ok=True)
    for filename in ["intent_classifier.pkl", "intent_vectorizer.pkl", "kb_vectorizer.pkl", "kb_matrix.pkl", "kb_database.parquet"]:
        src = os.path.join(MODELS_DIR, filename)
        dst = os.path.join(DEPLOY_DIR, filename)
        shutil.copy2(src, dst)
        print(f"Deployed: {filename} -> {DEPLOY_DIR}")
        
    print("Fine-tuning and deployment completed successfully!")

if __name__ == "__main__":
    fine_tune_and_evaluate()
