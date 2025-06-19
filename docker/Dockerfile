FROM python:3.11-slim

RUN apt-get update && apt-get install -y \
    curl \
    build-essential \
    swig \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY devops-demo-app/ .

# Create cache directory for huggingface models
RUN mkdir -p /app/.cache

# Set environment variables for cache directories
ENV HF_HOME=/app/.cache
ENV TRANSFORMERS_CACHE=/app/.cache
ENV SENTENCE_TRANSFORMERS_HOME=/app/.cache

# Install pip + requirements
RUN pip install --upgrade pip \
 && pip install --no-cache-dir -r requirements.txt

# Download the model (will be skipped if FAST_MODE=true at runtime)
# This ensures the model is available for production deployments
RUN python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('all-MiniLM-L6-v2')"

EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8000/ || exit 1
CMD ["python", "app.py"]
