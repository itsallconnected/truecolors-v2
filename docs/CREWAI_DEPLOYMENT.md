# CrewAI Deployment Guide

This document provides comprehensive instructions for deploying the CrewAI integration with Ollama for TrueColors.

## Prerequisites

- Python 3.10+
- PostgreSQL
- Redis
- At least 8GB RAM for Ollama

## Installation Steps

### 1. Install Python Dependencies

```bash
cd /home/mastodon/live
pip install -r lib/crewai/requirements.txt
```

### 2. Install and Configure Ollama

```bash
# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Pull the Mixtral model (this will take some time)
ollama pull mixtral
```

Configure Ollama to start on boot:

```bash
# Enable systemd user service
systemctl --user enable ollama
systemctl --user start ollama
```

### 3. Configure Environment Variables

Add these to your `.env.production` file:

