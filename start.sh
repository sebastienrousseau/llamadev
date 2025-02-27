#!/bin/bash
# Start Ollama server in background
ollama serve &

# Wait for Ollama to start
until curl -s http://localhost:11434/> /dev/null; do
    echo "Waiting for Ollama to start..."
    sleep 1
done

echo "Ollama is running!"
ollama run deepseek-coder
# ollama run hhao/qwen2.5-coder-tools:0.5b

echo "Deepseek-coder is running!"

# Start bash
exec /bin/bash --login