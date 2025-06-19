import json
import numpy as np
import faiss
from sentence_transformers import SentenceTransformer

MODEL_NAME = 'all-MiniLM-L6-v2'
JSON_PATH  = 'statistics.json'
INDEX_OUT  = 'index.faiss'
IDS_OUT    = 'ids.npy'

def main():
    print("🔍 Loading statistics data...")
    data = json.load(open(JSON_PATH, 'r'))
    texts = [f"{item['title']} {item['subject']} {item['description']}" for item in data]
    ids   = [item['id'] for item in data]

    print(f"📊 Processing {len(texts)} documents...")
    model = SentenceTransformer(MODEL_NAME)
    embeddings = model.encode(texts, batch_size=64, show_progress_bar=True)

    # build FAISS index flat L2
    dim   = embeddings.shape[1]
    print(f"🏗️ Building FAISS index (dimension: {dim})...")
    index = faiss.IndexFlatL2(dim)
    index.add(embeddings.astype('float32'))

    # serialize
    print("💾 Saving index and IDs...")
    faiss.write_index(index, INDEX_OUT)
    np.save(IDS_OUT, np.array(ids, dtype=np.int64))
    print(f"✅ Saved FAISS index to {INDEX_OUT} and ids to {IDS_OUT}")
    print(f"📈 Index contains {index.ntotal} vectors")

if __name__ == '__main__':
    main() 