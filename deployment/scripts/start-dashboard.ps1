# Display setup banner
Write-Host "========================================="
Write-Host "Setting up Streamlit Environment"
Write-Host "========================================="

# Path to the Python virtual environment
$venvPath = ".\venv"

# Check whether the virtual environment already exists
if (-not (Test-Path $venvPath)) {
    Write-Host "Virtual environment not found. Creating one..."

    # Create a new Python virtual environment
    python -m venv venv

    Write-Host "Activating virtual environment..."

    # Activate the virtual environment for the current PowerShell session
    & ".\venv\Scripts\Activate.ps1"

    # Install project dependencies if requirements.txt exists
    if (Test-Path "requirements.txt") {
        Write-Host "Installing requirements..."

        # Install all required Python packages
        pip install -r requirements.txt
    } else {
        # Stop execution if dependency file is missing
        Write-Host "ERROR: requirements.txt not found!"
        exit 1
    }
}
else {
    # Skip setup if the virtual environment already exists
    Write-Host "Virtual environment already exists. Skipping setup..."
}

# Launch the Streamlit application
Write-Host "Starting Streamlit..."
streamlit run .\src\app.py