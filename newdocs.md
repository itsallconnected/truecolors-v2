# TrueColors: Technology Stack Documentation

## Overview

TrueColors is a free, open-source social network server based on the ActivityPub protocol. It enables users to follow friends, discover new connections, and publish various content types including links, pictures, text, and video. As a federated network, TrueColors instances can seamlessly communicate with other ActivityPub-compatible servers.

## Technology Stack

### Backend

- **Ruby on Rails 8.0**: Powers the REST API and web pages

  - MVC architecture with controllers, models, views, and services
  - Uses Propshaft for asset management
  - PostgreSQL database integration via Active Record
  - Background job processing with Sidekiq

- **Ruby Version**: 3.2+ required

- **PostgreSQL 12+**: Primary database

  - Stores user accounts, posts, relationships, and all application data
  - Uses advanced PostgreSQL features like JSONB fields, arrays, and full-text search

- **Redis 4+**: Used for:

  - Caching
  - Sidekiq job queuing
  - Real-time updates via WebSockets

- **Node.js 18+**: Powers the streaming API

  - Delivers real-time updates to clients

- **XMPP Server (Prosody)**: Provides chat functionality
  - Integrates with the main application through custom XMPP credentials
  - Enables encrypted messaging between users

### Frontend

- **React 18**: For dynamic client-side interfaces

  - Uses Redux for state management
  - Implements Redux Toolkit for improved Redux workflow

- **TypeScript**: For type-safe JavaScript code

- **Modern JavaScript (ES6+)**: Utilizing latest language features

- **SCSS/Sass**: For styling components and pages

- **Webpack 4**: For module bundling and asset pipeline

- **Converse.js**: XMPP chat client
  - Integrated via custom React components
  - Configured for OMEMO end-to-end encryption

### Additional Technologies

- **ActivityPub Protocol**: For federation and communication with other instances
- **WebSockets**: For real-time updates
- **OAuth2**: For authentication and third-party app integration
- **Webpacker**: Rails/Webpack integration
- **HAML**: For server-rendered view templates
- **i18n/react-intl**: For internationalization
- **Chewy/Elasticsearch**: For search functionality
- **Paperclip**: For file attachments/media handling
- **Fernet**: For encrypted data storage

## Chat System & Encryption

### XMPP Integration

TrueColors implements secure chat functionality using the XMPP (eXtensible Messaging and Presence Protocol) standard:

- **Architecture**:

  - Dedicated XMPP server (Prosody) running alongside the main application
  - XMPP credentials automatically created for each user
  - Credentials stored securely in the database with encryption

- **Components**:

  - `XmppCredential` model: Stores user XMPP credentials with encrypted passwords
  - `ChatRoom` model: Represents XMPP multi-user chat rooms (MUC)
  - `ChatMessage` model: Stores messages with encryption support
  - `XmppRoomService`: Handles XMPP room management
  - `CreateXmppRoomWorker`: Background job for creating rooms

- **Frontend Integration**:
  - Converse.js library for XMPP client functionality
  - React components for chat interface
  - Redux actions for managing chat state and settings

### End-to-End Encryption

TrueColors implements multiple layers of encryption for secure communications:

- **OMEMO Encryption**:

  - End-to-end encryption protocol specifically for XMPP
  - Enabled by default for all chat messages
  - Uses double ratchet algorithm with perfect forward secrecy
  - Device verification and key management handled by Converse.js

- **Database-level Encryption**:

  - Chat messages stored encrypted in the database
  - Uses Rails `encrypts` attribute for transparent encryption
  - Separate encryption keys for each chat room

- **Message Transit Encryption**:

  - Chat messages encrypted during transit using XMPP's TLS
  - WebSocket connections secured with TLS
  - API calls protected with HTTPS

- **Encryption Key Management**:
  - Room encryption keys generated securely with `SecureRandom`
  - XMPP passwords generated with high entropy
  - Fernet symmetric encryption for certain data elements

## AI Integration

TrueColors includes comprehensive AI agent functionality for XMPP chatrooms using:

- **CrewAI**: Framework for creating AI agents that can collaborate

  - Implemented via Python integration with Ruby
  - Secure data passing between Ruby and Python environments
  - Uses the `Open3` module for process communication

- **Ollama**: For local model execution

  - Configurable through environment variables
  - Supports multiple LLM models including phi3

- **Integrated Agents**:

  - **Planner**: Helps with planning events and projects
  - **Researcher**: Provides research and information on topics
  - **Strategist**: Assists with outreach and communication strategies
  - **Mediator**: Helps resolve conflicts

- **Agent-specific Features**:

  - Task-based system for defining agent capabilities
  - Memory persistence via PostgreSQL with encryption
  - Rate limiting to prevent abuse
  - Message queuing for handling concurrent requests

- **Implementation Details**:
  - `CrewAgent` model: Defines AI agents and their capabilities
  - `CrewTask` model: Defines tasks that agents can perform
  - `ChatRoom` integration: Rooms can have AI agents assigned
  - Python scripts for creating and running agents
  - XMPP bot implementation for interacting with rooms

## Application Architecture

### Directory Structure

- **app/**: Main application code

  - **controllers/**: Rails controllers
    - **api/v1/chat_rooms_controller.rb**: API endpoints for chat rooms
  - **models/**: Active Record models
    - **xmpp_credential.rb**: XMPP user credentials
    - **chat_room.rb**: Chat room implementation
    - **chat_message.rb**: Chat message storage
    - **crew_agent.rb**: AI agent definition
    - **crew_task.rb**: AI task definition
  - **views/**: HAML views
  - **javascript/**: Frontend React/Redux code
    - **truecolors/actions/chat.js**: Chat-related Redux actions
    - **truecolors/features/chat/**: Chat component implementation
  - **services/**: Business logic services
    - **xmpp_room_service.rb**: XMPP room management
  - **workers/**: Background jobs
    - **create_xmpp_room_worker.rb**: Async XMPP room creation

- **lib/crewai/**: AI integration code

  - **xmpp_bot.py**: Python XMPP bot implementation
  - **pg_memory.py**: Encrypted memory storage
  - **create_crew.py**: Agent crew creation
  - **create_agent.py**: Individual agent creation

- **config/**: Application configuration
  - **initializers/crewai.rb**: CrewAI initialization

### Key Features Implementation

1. **Federation via ActivityPub**:

   - Implements ActivityPub protocol for decentralized social networking
   - Allows communication with other ActivityPub-compatible platforms

2. **Real-time Timeline Updates**:

   - WebSockets for instant delivery of new posts
   - Streaming API built with Node.js

3. **Media Attachments**:

   - Support for images, videos, and GIFs
   - Uses Paperclip for file handling

4. **Secure Chat System**:

   - XMPP-based chat with OMEMO encryption
   - Multi-user chatrooms with AI agent integration
   - End-to-end encryption for private communications
   - Database encryption for stored messages

5. **AI Agent Integration**:

   - CrewAI-based agents for specific tasks
   - Secure Python-Ruby interoperability
   - Task-based system for defining capabilities
   - Encrypted memory storage for conversation context

6. **Moderation Tools**:

   - Comprehensive toolkit for content moderation
   - Includes features like private posts, locked accounts, phrase filtering, muting, blocking, and reporting

7. **OAuth2 API**:
   - REST and Streaming APIs for third-party applications
   - Enables rich app ecosystem

## Deployment Options

TrueColors supports multiple deployment strategies:

- **Docker/docker-compose**: Production-ready containerization
- **Helm charts**: For Kubernetes deployments
- **Platform-specific configs**: For Heroku, Scalingo, etc.
- **Standalone installation**: Traditional server setup

## Development Tools

- **ESLint/Rubocop**: For code linting
- **Jest**: JavaScript testing
- **RSpec**: Ruby testing
- **TypeScript**: Type checking
- **Prettier**: Code formatting
- **Husky**: Git hooks
- **Capybara**: Browser testing

## Database Schema Highlights

The database design centers around key entities:

- **Accounts**: User profiles and authentication
- **Statuses**: Posts/toots with content and metadata
- **Media Attachments**: Files attached to statuses
- **Follows**: Relationships between accounts
- **Conversations**: For direct messaging
- **Notifications**: User alerts for various activities
- **Custom Emojis**: Server-specific emoji
- **Tags**: Hashtags for content discovery
- **XmppCredentials**: XMPP user credentials for chat
- **ChatRooms**: XMPP multi-user chat rooms
- **ChatMessages**: Messages in chat rooms
- **CrewAgents**: AI agent definitions
- **CrewTasks**: AI task definitions

## Authentication, Authorization & Security

- **Devise**: User authentication
- **Two-factor authentication**: Enhanced security
- **OAuth2**: For API access tokens
- **Pundit**: Role-based authorization
- **OMEMO**: End-to-end encryption for chat
- **Fernet**: Symmetric encryption for sensitive data
- **Rails encrypts**: Database-level encryption

## Conclusion

TrueColors represents a modern, full-stack web application combining Ruby on Rails and React. It implements the ActivityPub protocol to participate in the federated social web while offering a rich set of features for users and administrators. The application architecture follows Rails conventions with additional JavaScript frameworks to provide an interactive user experience.

The chat system based on XMPP with OMEMO encryption provides secure communication channels, while the CrewAI integration brings powerful AI capabilities to chatrooms. Multiple layers of encryption ensure data protection both in transit and at rest.
