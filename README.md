# Bank AI Use Case

A demo banking application showcasing an AI-powered advisor built with Spring AI, MCP (Model Context Protocol), and OpenAI GPT-4o-mini.

## Architecture

```
bank-ai-advisor (port 8095)        ← Chat UI + Spring AI ChatClient
        │
        │  MCP (SSE)
        ▼
bank-mcp-server (port 8092)        ← MCP tools: transactions, accounts, disputes
        │
        │  REST + JWT
        ▼
bank-portal (port 9081)            ← Core banking API + PostgreSQL + pgvector RAG
```

### Components

| Module | Port | Description |
|---|---|---|
| `bank-portal` | 9081 | Core banking REST API. Manages customers, accounts, transactions, disputes. Uses PostgreSQL with pgvector for RAG-based transaction categorization. |
| `bank-mcp-server` | 8092 | MCP server exposing banking tools (`getTransactionsByCustomer`, `raiseDispute`, etc.) to the AI advisor via SSE. |
| `bank-ai-advisor` | 8095 | AI chat interface. Uses Spring AI `ChatClient` with GPT-4o-mini, MCP tool calling, and in-memory conversation history. |

## Prerequisites

- Java 21+
- Maven 3.9+
- PostgreSQL with `pgvector` extension
- OpenAI API key

## Setup

### 1. Database

```bash
psql -c "CREATE DATABASE bank_db;"
psql bank_db -f bank-portal/src/main/resources/scripts/schema.sql
```

### 2. Environment Variables

```bash
export SPRING_AI_OPENAI_API_KEY=your-openai-api-key
export JWT_SECRET=your-jwt-secret-min-32-chars
```

### 3. Start Servers (in order)

```bash
# Terminal 1 — start bank-portal first
cd bank-portal && mvn spring-boot:run

# Terminal 2 — start MCP server after bank-portal is ready
cd bank-mcp-server && mvn spring-boot:run

# Terminal 3 — start AI advisor
cd bank-ai-advisor && mvn spring-boot:run
```

> **Important:** Start `bank-portal` before `bank-mcp-server`. The MCP server authenticates against bank-portal at startup to obtain a service JWT. If bank-portal isn't ready, restart the MCP server after bank-portal is up.

Open **http://localhost:8095** to use the AI advisor.

## How Tool Selection Works

The AI advisor sends every user message to GPT-4o-mini along with:
- A system prompt defining the advisor's role and capabilities
- All MCP tool definitions (fetched from `bank-mcp-server` at startup)
- Conversation history (last 20 messages)

GPT-4o-mini reads the `@Tool(description=...)` on each tool and decides which to call based on the user's intent. Spring AI handles the tool execution loop automatically — calling tools and feeding results back to the LLM until it returns a final response.

## Demo Customers

| Customer ID | Name | Accounts |
|---|---|---|
| 1 | John Smith | CHECKING: 4012001234567890, SAVINGS: 4012001234567891 |
| 2 | Sarah Johnson | CHECKING: 4012009876543210, SAVINGS: 4012009876543211 |

## Tech Stack

- **Spring Boot 3** / **Spring AI**
- **OpenAI GPT-4o-mini**
- **MCP (Model Context Protocol)** — SSE transport
- **PostgreSQL** + **pgvector** (RAG transaction categorization)
- **JWT** authentication between services
