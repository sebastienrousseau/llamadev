#!/bin/bash
# Start Ollama server in background
echo "Starting Ollama server..."
nohup ollama serve > /dev/null 2>&1 &

# Wait for Ollama to be fully ready
echo "Waiting for Ollama to be ready..."
for i in {1..30}; do
    if curl -s http://localhost:11434/ > /dev/null; then
        echo "Ollama is running after ${i} seconds!"
        break
    fi
    sleep 1
done

# Check if Ollama failed to start
if ! curl -s http://localhost:11434/ > /dev/null; then
    echo "Error: Ollama did not start within 30 seconds."
    exit 1
fi

# Run deepseek-coder in the background (change to foreground if needed)
echo "Starting Deepseek-coder..."
ollama run deepseek-coder > /dev/null 2>&1 &
echo "Deepseek-coder is running!"

# Start interactive bash session
exec /bin/bash --login
