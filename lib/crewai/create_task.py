#!/usr/bin/env python

import os
import sys
import json
import uuid
import pickle
import tempfile
from pathlib import Path

try:
    from crewai import Task, Agent
    from langchain_ollama import ChatOllama
    
    # Create a persistent storage directory
    storage_dir = Path(tempfile.gettempdir()) / "crewai_storage"
    storage_dir.mkdir(exist_ok=True)
    
    # Load task data from command line argument
    task_data = json.loads(sys.argv[1]) if len(sys.argv) > 1 else {}
    
    # Extract task parameters
    description = task_data.get('description', 'Default task description')
    expected_output = task_data.get('expected_output', 'text')
    agent_id = task_data.get('agent_id')
    tools = task_data.get('tools', [])
    
    # Load the agent from file if it exists
    agent = None
    agent_file = storage_dir / f"agent_{agent_id}.pkl"
    
    if agent_file.exists():
        try:
            with open(agent_file, 'rb') as f:
                agent = pickle.load(f)
        except Exception as e:
            print(f"Warning: Could not load agent from file: {e}", file=sys.stderr)
    
    # Create a default agent if we couldn't load the specified one
    if agent is None:
        # Create a default agent
        llm = ChatOllama(
            model=os.environ.get('OLLAMA_MODEL', 'phi3'),
            temperature=0.7,
            base_url=os.environ.get('OLLAMA_HOST', 'http://localhost:11434'),
        )
        
        agent = Agent(
            role="Assistant",
            goal="Help complete tasks",
            verbose=os.environ.get('RAILS_ENV') == 'development',
            llm=llm
        )
    
    # Create the task
    task = Task(
        description=description,
        expected_output=expected_output,
        agent=agent,
        tools=tools
    )
    
    # Generate a unique ID for the task to reference it later
    task_id = str(uuid.uuid4())
    
    # Store the task in a file for persistence
    task_file = storage_dir / f"task_{task_id}.pkl"
    with open(task_file, 'wb') as f:
        pickle.dump(task, f)
    
    # Return the task ID
    result = {
        "status": "success",
        "message": "Task created successfully",
        "task_id": task_id
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
        "message": f"Error creating task: {str(e)}"
    }
    print(json.dumps(error), file=sys.stderr)
    sys.exit(1) 