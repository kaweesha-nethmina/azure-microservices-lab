azure-microservices-lab/
│
├── 📄 README.md                    # Main documentation
├── 📄 QUICKSTART.md                # Quick start guide  
├── 📄 DEPLOYMENT_GUIDE.md          # Step-by-step deployment
├── 📄 .gitignore                   # Git ignore rules
├── 📄 .env.local                   # Local development config
├── 📄 .env.production              # Production config
├── 📄 docker-compose.yml           # Local development orchestration
├── 📄 nginx.conf                   # Nginx configuration
├── 🔧 setup-local.sh              # Local setup script
├── 🔧 setup-azure.sh              # Azure deployment script
│
├── 📁 frontend/                    # Frontend application
│   └── 📄 index.html               # UI for microservices
│
├── 📁 gateway/                     # API Gateway service
│   ├── 📄 package.json             # Node.js dependencies
│   ├── 📄 server.js                # Express server
│   └── 📄 Dockerfile               # Container configuration
│
├── 📁 api/                         # Backend API service
│   ├── 📄 package.json             # Node.js dependencies
│   ├── 📄 server.js                # Express server with CRUD
│   └── 📄 Dockerfile               # Container configuration
│
├── 📁 infra/                       # Azure Infrastructure as Code
│   ├── 📄 main.bicep               # Bicep template
│   └── 📄 parameters.json          # Deployment parameters
│
└── 📁 .github/workflows/           # CI/CD Automation
    └── 📄 deploy.yml               # GitHub Actions pipeline

KEY FILES EXPLAINED:

🏗️ INFRASTRUCTURE
- infra/main.bicep: Azure resources (Container Registry, Container Apps, Static Web App)
- infra/parameters.json: Configuration values for deployment

🐳 CONTAINERIZATION
- docker-compose.yml: Local multi-container orchestration
- gateway/Dockerfile: Gateway service container
- api/Dockerfile: API service container
- nginx.conf: Nginx reverse proxy configuration

📝 SERVICES
- frontend/index.html: User interface with service health checks
- gateway/server.js: API Gateway (routes & CORS)
- api/server.js: User management API (CRUD operations)

⚙️ CONFIGURATION
- .env.local: Development environment variables
- .env.production: Production environment variables
- .gitignore: Files to ignore in version control

📚 DOCUMENTATION
- README.md: Complete documentation
- QUICKSTART.md: Get started in 5 minutes
- DEPLOYMENT_GUIDE.md: Detailed step-by-step guide

🚀 AUTOMATION
- .github/workflows/deploy.yml: GitHub Actions CI/CD pipeline
- setup-local.sh: Automated local setup
- setup-azure.sh: Automated Azure deployment

ARCHITECTURE:
                    
    ┌─────────────────────────────────────────────┐
    │              Azure Platform                 │
    ├─────────────────────────────────────────────┤
    │                                             │
    │  Frontend (Static Web App)                  │
    │  http://localhost (local)                   │
    │            ↓                                │
    │  ┌──────────────────────────────┐          │
    │  │    API Gateway (Port 3000)   │          │
    │  │  - CORS handling             │          │
    │  │  - Request routing           │          │
    │  └──────────────────────────────┘          │
    │            ↓                                │
    │  ┌──────────────────────────────┐          │
    │  │   API Service (Port 5000)    │          │
    │  │  - User management           │          │
    │  │  - CRUD operations           │          │
    │  └──────────────────────────────┘          │
    │                                             │
    └─────────────────────────────────────────────┘

DEPLOYMENT OPTIONS:

1️⃣  LOCAL DEVELOPMENT
   docker-compose up -d
   → All services run locally in containers
   → Perfect for testing and debugging

2️⃣  AZURE CLOUD
   ./setup-azure.sh
   → Resources deployed on Azure platform
   → Uses Container Registry, Container Apps, Static Web Apps

3️⃣  CI/CD PIPELINE
   Push to main branch
   → GitHub Actions automatically builds & deploys
   → Complete automation from code to production
