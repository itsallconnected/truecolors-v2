#!/usr/bin/env python

import os
import sys
import json
import uuid
import pickle
import tempfile
from pathlib import Path

try:
    from crewai import Agent
    from langchain_ollama import ChatOllama
    
    # Create a persistent storage directory
    storage_dir = Path(tempfile.gettempdir()) / "crewai_storage"
    storage_dir.mkdir(exist_ok=True)
    
    # Load agent data from command line argument
    agent_data = json.loads(sys.argv[1]) if len(sys.argv) > 1 else {}
    
    # Extract agent parameters
    role = agent_data.get('role', 'Assistant')
    goal = agent_data.get('goal', 'Help the user')
    backstory = agent_data.get('backstory', '')
    verbose = agent_data.get('verbose', False)
    memory_config = agent_data.get('memory')
    
    # Extract LLM settings
    llm_config = agent_data.get('llm', {})
    provider = llm_config.get('provider', 'ollama')
    model = llm_config.get('model', os.environ.get('OLLAMA_MODEL', 'phi3'))
    temperature = float(llm_config.get('temperature', 0.7))
    
    # Set up the language model
    if provider == 'ollama':
        llm = ChatOllama(
            model=model,
            temperature=temperature,
            base_url=os.environ.get('OLLAMA_HOST', 'http://localhost:11434'),
        )
    else:
        # Default to Ollama if provider not supported
        llm = ChatOllama(
            model=model,
            temperature=temperature,
            base_url=os.environ.get('OLLAMA_HOST', 'http://localhost:11434'),
        )
    
    # Create the agent
    agent = Agent(
        role=role,
        goal=goal,
        backstory=backstory,
        verbose=verbose,
        memory=memory_config is not None,
        llm=llm
    )
    
    # Generate a unique ID for the agent to reference it later
    agent_id = str(uuid.uuid4())
    
    # Store the agent in a file for persistence between calls
    agent_file = storage_dir / f"agent_{agent_id}.pkl"
    with open(agent_file, 'wb') as f:
        pickle.dump(agent, f)
    
    # Return the agent ID
    result = {
        "status": "success",
        "message": "Agent created successfully",
        "agent_id": agent_id
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
        "message": f"Error creating agent: {str(e)}"
    }
    print(json.dumps(error), file=sys.stderr)
    sys.exit(1) 