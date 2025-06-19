import os
import time
import json
import sqlite3
import numpy as np
import faiss
from fastapi import FastAPI, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import List, Optional
from sentence_transformers import SentenceTransformer

# Fast mode flag - set to True to skip model loading for faster startup
FAST_MODE = os.getenv('FAST_MODE', 'false').lower() == 'true'

# Initialize FastAPI app
app = FastAPI()

# Initialize sentence transformer model (only if not in fast mode)
model = None
if not FAST_MODE:
    print("🤖 Loading sentence transformer model...")
    model = SentenceTransformer('all-MiniLM-L6-v2')

# Load prebuilt FAISS index + ids
index = None
ids = []
if not FAST_MODE:
    print("📊 Loading pre-built FAISS index...")
    try:
        index = faiss.read_index('index.faiss')
        ids = np.load('ids.npy').tolist()
        print(f"✅ Loaded FAISS index with {index.ntotal} vectors")
    except Exception as e:
        print(f"⚠️ Could not load pre-built index: {e}")
        print("🔄 Falling back to runtime index creation...")
        # Fallback to original runtime index creation
        index, ids = create_faiss_index()

# Database setup
def init_db():
    conn = sqlite3.connect('statistics.db')
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS statistics
                 (id INTEGER PRIMARY KEY,
                  title TEXT,
                  subject TEXT,
                  description TEXT,
                  link TEXT,
                  date TEXT,
                  teaser_image_url TEXT)''')
    conn.commit()
    conn.close()

# Load data into database (without embeddings)
def load_data():
    if FAST_MODE:
        print("Fast mode enabled - skipping data loading")
        return
        
    with open('statistics.json', 'r') as f:
        data = json.load(f)
    
    conn = sqlite3.connect('statistics.db')
    c = conn.cursor()
    
    # Check if data is already loaded
    c.execute("SELECT COUNT(*) FROM statistics")
    if c.fetchone()[0] == 0:
        print("📥 Loading statistics data into database...")
        for item in data:
            c.execute('''INSERT INTO statistics 
                        (id, title, subject, description, link, date, teaser_image_url)
                        VALUES (?, ?, ?, ?, ?, ?, ?)''',
                     (item['id'], item['title'], item['subject'], item['description'],
                      item['link'], item['date'], item['teaser_image_url']))
        print(f"✅ Loaded {len(data)} records into database")
    
    conn.commit()
    conn.close()

# Fallback function for runtime index creation (if pre-built index fails)
def create_faiss_index():
    if FAST_MODE:
        print("Fast mode enabled - skipping FAISS index creation")
        return None, []
        
    print("🔄 Creating FAISS index at runtime...")
    conn = sqlite3.connect('statistics.db')
    c = conn.cursor()
    
    # Get all data
    c.execute("SELECT id, title, subject, description FROM statistics")
    results = c.fetchall()
    
    if not results:
        return None, []
    
    # Create embeddings
    texts = [f"{row[1]} {row[2]} {row[3]}" for row in results]
    embeddings = model.encode(texts, batch_size=64, show_progress_bar=True)
    
    # Create FAISS index
    dimension = model.get_sentence_embedding_dimension()
    index = faiss.IndexFlatL2(dimension)
    index.add(embeddings.astype('float32'))
    
    ids = [row[0] for row in results]
    
    conn.close()
    print(f"✅ Created runtime FAISS index with {index.ntotal} vectors")
    return index, ids

# Initialize database and load data
init_db()
load_data()

class SearchQuery(BaseModel):
    query: str
    limit: Optional[int] = 5

@app.get("/")
async def root():
    mode = "fast" if FAST_MODE else "normal"
    return {
        "message": "Welcome to the Statistics Search API",
        "mode": mode,
        "search_available": not FAST_MODE,
        "index_loaded": index is not None if not FAST_MODE else False
    }

@app.post("/find")
async def find_statistics(query: SearchQuery):
    if FAST_MODE:
        raise HTTPException(status_code=503, detail="Search functionality not available in fast mode. Set FAST_MODE=false to enable search.")
    
    if not index:
        raise HTTPException(status_code=500, detail="Search index not initialized")
    
    # Encode query
    query_embedding = model.encode(query.query)
    
    # Search in FAISS index
    k = min(query.limit, len(ids))
    distances, indices = index.search(np.array([query_embedding]), k)
    
    # Get results from database
    conn = sqlite3.connect('statistics.db')
    c = conn.cursor()
    
    results = []
    for idx in indices[0]:
        c.execute("SELECT * FROM statistics WHERE id = ?", (ids[idx],))
        result = c.fetchone()
        if result:
            results.append({
                "id": result[0],
                "title": result[1],
                "subject": result[2],
                "description": result[3],
                "link": result[4],
                "date": result[5],
                "teaser_image_url": result[6]
            })
    
    conn.close()
    return results

@app.post("/stream/find")
async def stream_find_statistics(query: SearchQuery):
    if FAST_MODE:
        raise HTTPException(status_code=503, detail="Search functionality not available in fast mode. Set FAST_MODE=false to enable search.")
    
    if not index:
        raise HTTPException(status_code=500, detail="Search index not initialized")
    
    # Encode query
    query_embedding = model.encode(query.query)
    
    # Search in FAISS index
    k = min(10, len(ids))  # Always return top 10 for streaming
    distances, indices = index.search(np.array([query_embedding]), k)
    
    # Get results from database
    conn = sqlite3.connect('statistics.db')
    c = conn.cursor()
    
    async def generate():
        for idx in indices[0]:
            c.execute("SELECT * FROM statistics WHERE id = ?", (ids[idx],))
            result = c.fetchone()
            if result:
                item = {
                    "id": result[0],
                    "title": result[1],
                    "subject": result[2],
                    "description": result[3],
                    "link": result[4],
                    "date": result[5],
                    "teaser_image_url": result[6]
                }
                yield f"data: {json.dumps(item)}\n\n"
                time.sleep(0.1)  # Small delay to demonstrate streaming
    
    conn.close()
    return StreamingResponse(generate(), media_type="text/event-stream")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000) 