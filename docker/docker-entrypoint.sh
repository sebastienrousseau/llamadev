#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

# Ensure the script runs as the correct user
USERNAME=${USERNAME:-defaultuser}  # Assign a default value if USERNAME is not set
user_id=$(id -u)
if [[ "${user_id}" -ne 1000 ]]; then
    echo "Switching to user: ${USERNAME}"
    exec gosu "${USERNAME}" "$0" "$@"
fi

# Activate Python virtual environment
if [[ -d "/opt/venv" ]]; then
    echo "Activating virtual environment..."
    # shellcheck disable=SC1091
    source /opt/venv/bin/activate
fi

# Ensure correct working directory
cd /home/llamadev/code || exit 1

# Print environment details
echo "Starting container as: $(whoami)"
python_version=$(python --version)
echo "Python version: ${python_version}"
OLLAMA_HOST=${OLLAMA_HOST:-localhost}
echo "OLLAMA is listening on ${OLLAMA_HOST}"

# Execute the provided command or default to /bin/bash
exec "$@"
