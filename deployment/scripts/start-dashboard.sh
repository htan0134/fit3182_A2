#!/bin/bash

# Display setup banner
echo "========================================="
echo "Setting up Streamlit Environment"
echo "========================================="

# Path to the Python virtual environment
VENV_PATH="./venv"

# Check whether the virtual environment already exists
if [ ! -d "$VENV_PATH" ]; then
    echo "Virtual environment not found. Creating one..."

    # Create a new virtual environment
    python3 -m venv venv

    echo "Activating virtual environment..."

    # Activate the virtual environment
    source venv/bin/activate

    # Install project dependencies if requirements.txt exists
    if [ -f "requirements.txt" ]; then
        echo "Installing requirements..."

        # Install all required Python packages
        pip install -r requirements.txt
    else
        # Stop execution if dependency file is missing
        echo "ERROR: requirements.txt not found!"
        exit 1
    fi
else
    # Skip setup if the virtual environment already exists
    echo "Virtual environment already exists. Skipping setup..."
fi

# Launch the Streamlit application
echo "Starting Streamlit..."
streamlit run ./src/app.py