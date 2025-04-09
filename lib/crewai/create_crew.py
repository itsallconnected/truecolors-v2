#!/usr/bin/env python

import os
import sys
import json
import uuid
import pickle
import tempfile
from pathlib import Path
from glob import glob

try:
    from crewai import Crew, Agent, Task
    from langchain_ollama import ChatOllama
    
    # Create a persistent storage directory
    storage_dir = Path(tempfile.gettempdir()) / "crewai_storage"
    storage_dir.mkdir(exist_ok=True)
    
    # Load crew data from command line argument
    crew_data = json.loads(sys.argv[1]) if len(sys.argv) > 1 else {}
    
    # Extract crew parameters
    agent_ids = crew_data.get('agents', [])
    task_ids = crew_data.get('tasks', [])
    verbose = crew_data.get('verbose', False)
    
    # Load agents from files
    agents = []
    for agent_id in agent_ids:
        agent_file = storage_dir / f"agent_{agent_id}.pkl"
        if agent_file.exists():
            try:
                with open(agent_file, 'rb') as f:
                    agent = pickle.load(f)
                    agents.append(agent)
            except Exception as e:
                print(f"Warning: Could not load agent {agent_id}: {e}", file=sys.stderr)
    
    # Create a default agent if none were found
    if not agents:
        llm = ChatOllama(
            model=os.environ.get('OLLAMA_MODEL', 'phi3'),
            temperature=0.7,
            base_url=os.environ.get('OLLAMA_HOST', 'http://localhost:11434'),
        )
        
        # Create a default agent
        agent = Agent(
            role="Assistant",
            goal="Help complete tasks",
            verbose=verbose,
            llm=llm
        )
        agents.append(agent)
    
    # Load tasks from files
    tasks = []
    for task_id in task_ids:
        task_file = storage_dir / f"task_{task_id}.pkl"
        if task_file.exists():
            try:
                with open(task_file, 'rb') as f:
                    task = pickle.load(f)
                    tasks.append(task)
            except Exception as e:
                print(f"Warning: Could not load task {task_id}: {e}", file=sys.stderr)
    
    # Create the crew
    crew = Crew(
        agents=agents,
        tasks=tasks,
        verbose=verbose
    )
    
    # Generate a unique ID for the crew to reference it later
    crew_id = str(uuid.uuid4())
    
    # Store the crew in a file for persistence
    crew_file = storage_dir / f"crew_{crew_id}.pkl"
    with open(crew_file, 'wb') as f:
        pickle.dump(crew, f)
    
    # Return the crew ID
    result = {
        "status": "success",
        "message": "Crew created successfully",
        "crew_id": crew_id,
        "agent_count": len(agents),
        "task_count": len(tasks)
    }
    print(json.dumps(result))
    
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
        "message": f"Error creating crew: {str(e)}"
    }
    print(json.dumps(error), file=sys.stderr)
    sys.exit(1) 