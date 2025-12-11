FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV APP_HOME /app

WORKDIR $APP_HOME

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libpq-dev gcc \
    && rm -rf /var/lib/apt/lists/*

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install gunicorn

# Copy project files
COPY . .

# ⚠️ FAIL-SAFE START COMMAND:
# This finds the wsgi.py file dynamically and launches gunicorn with the correct module name.
# It handles folder names like 'store_api', 'config', 'backend', etc. automatically.
CMD export WSGI_PATH=$(find . -name "wsgi.py" -maxdepth 2 | head -n 1) && \
    export WSGI_MODULE=$(echo $WSGI_PATH | sed 's|^\./||' | sed 's|/|\.|g' | sed 's|\.py||') && \
    echo "Starting Gunicorn with module: $WSGI_MODULE" && \
    exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 "$WSGI_MODULE:application"
