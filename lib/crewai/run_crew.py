#!/usr/bin/env python

import os
import sys
import json
import pickle
import tempfile
from pathlib import Path

try:
    from crewai import Crew
    
    # Create a persistent storage directory
    storage_dir = Path(tempfile.gettempdir()) / "crewai_storage"
    storage_dir.mkdir(exist_ok=True)
    
    # Load crew ID from command line argument
    crew_id = sys.argv[1] if len(sys.argv) > 1 else None
    
    if not crew_id:
        raise ValueError("Crew ID must be provided as argument")
    
    # Load the crew from file
    crew_file = storage_dir / f"crew_{crew_id}.pkl"
    
    if not crew_file.exists():
        raise FileNotFoundError(f"Crew file not found: {crew_file}")
    
    # Load the crew
    with open(crew_file, 'rb') as f:
        crew = pickle.load(f)
    
    # Run the crew's tasks
    result = crew.kickoff()
    
    # Return the result
    output = {
        "status": "success",
        "message": "Crew tasks completed successfully",
        "result": result
    }
    print(json.dumps(output))
    
except ImportError as e:
    error = {
        "status": "error",
        "message": f"Error importing required Python modules: {str(e)}"
    }
    print(json.dumps(error), file=sys.stderr)
    sys.exit(1)
    
except Exception as e:
    error = {
        "status": "error",
        "message": f"Error running crew: {str(e)}"
    }
    print(json.dumps(error), file=sys.stderr)
    sys.exit(1) 