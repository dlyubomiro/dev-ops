# Books API - Complete DevOps Pipeline Project

## Overview

This project demonstrates a complete automated software delivery process with CI/CD pipelines covering multiple DevOps topics. The application is a simple REST API for managing books, built with Go.

## Topics Covered

1. **Source Control** - Git repository with proper branching strategy
2. **Building Pipelines** - Complete CI/CD pipeline with GitHub Actions
3. **Continuous Integration** - Automated testing, linting, and code quality checks
4. **Continuous Delivery** - Automated deployment to Kubernetes
5. **Security** - SAST scanning and vulnerability assessment
6. **Docker** - Containerized application with multi-stage builds
7. **Kubernetes** - Container orchestration with rolling deployments
8. **Infrastructure as Code** - Terraform for Kubernetes resources
9. **Database Changes** - SQL migrations with testing

## Architecture

### High-Level Design

```
Developer → Git Repository → CI/CD Pipeline → Docker Registry → Kubernetes Cluster
                ↓
         Feature Branch → PR → Automated Tests → Build → Scan → Deploy
```

### Components

- **Application**: Go REST API for books management
- **Database**: PostgreSQL with migration support
- **Containerization**: Docker with multi-stage builds
- **Orchestration**: Kubernetes with rolling updates
- **CI/CD**: GitHub Actions pipeline
- **Infrastructure**: Terraform for K8s resources
- **Security**: Gosec SAST and Trivy vulnerability scanning

## Project Structure

```
.
├── main.go                 # Main application code
├── main_test.go           # Unit tests
├── Dockerfile             # Docker build configuration
├── docker-compose.yml     # Local development setup
├── go.mod                 # Go dependencies
├── .golangci.yml          # Linter configuration
├── migrations/            # SQL migration files
│   ├── 001_initial_schema.sql
│   └── 002_add_description.sql
├── k8s/                   # Kubernetes manifests
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── secret.yaml
│   ├── postgres-deployment.yaml
│   ├── postgres-service.yaml
│   └── pvc.yaml
├── terraform/             # Infrastructure as Code
│   └── main.tf
└── .github/workflows/     # CI/CD pipeline
    └── ci-cd.yml
```

## Pipeline Flow

1. **Open Issue** - Create issue in GitHub
2. **Create Feature Branch** - Branch from develop/main
3. **Unit Test** - Run Go unit tests
4. **Linter** - golangci-lint code analysis
5. **Style Check** - gofmt format verification
6. **SAST** - Gosec security scanning
7. **Build Docker Image** - Multi-stage Docker build
8. **Scan for Vulnerabilities** - Trivy container scanning
9. **Test SQL Deltas** - Validate database migrations
10. **Push to Registry** - GitHub Container Registry (GHCR)
11. **Rolling Deploy to Kubernetes** - Automated K8s deployment

## Local Development

### Prerequisites

- Go 1.21+
- Docker and Docker Compose
- PostgreSQL (or use docker-compose)

### Setup

1. Clone the repository
2. Start local services:
   ```bash
   docker-compose up -d
   ```
3. Run the application:
   ```bash
   go run main.go
   ```
4. Test the API:
   ```bash
   curl http://localhost:8080/health
   curl http://localhost:8080/books
   ```

### Running Tests

```bash
go test -v ./...
```

### Running Linter

```bash
golangci-lint run
```

## CI/CD Pipeline

The pipeline is defined in `.github/workflows/ci-cd.yml` and includes:

- **Unit Tests**: Automated test execution
- **Linter**: Code quality checks
- **Style Check**: Code formatting verification
- **SAST**: Static Application Security Testing (see SAST_DEEP_DIVE.md)
- **Build**: Docker image creation
- **Vulnerability Scan**: Container image scanning with Trivy
- **SQL Testing**: Migration validation with PostgreSQL
- **Deploy**: Kubernetes rolling deployment using Kind

## Kubernetes Deployment

### Manual Deployment

```bash
kubectl apply -f k8s/pvc.yaml
kubectl apply -f k8s/postgres-deployment.yaml
kubectl apply -f k8s/postgres-service.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

### Using Terraform

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

## Branching Strategy

- **main**: Production-ready code
- **develop**: Integration branch
- **feature/***: Feature development branches
- **hotfix/***: Emergency fixes

## API Endpoints

- `GET /health` - Health check
- `GET /books` - List all books
- `GET /books/{id}` - Get book by ID
- `POST /books` - Create new book
- `PUT /books/{id}` - Update book
- `DELETE /books/{id}` - Delete book

## Database Migrations

Migrations are located in `migrations/` directory. The pipeline automatically tests all migrations before deployment.

## Security

- **SAST**: Gosec scans for security vulnerabilities in code
- **Container Scanning**: Trivy scans Docker images for known vulnerabilities
- **Secrets Management**: Kubernetes secrets for sensitive data

## Future Improvements

1. Add monitoring and logging (Prometheus, Grafana)
2. Implement service mesh (Istio)
3. Add blue-green deployment strategy
4. Implement feature flags
5. Add performance testing in pipeline
6. Implement chaos engineering tests
7. Add API documentation (Swagger/OpenAPI)
8. Implement rate limiting
9. Add caching layer (Redis)
10. Implement distributed tracing

## Deep Dive: SAST

See [SAST_DEEP_DIVE.md](SAST_DEEP_DIVE.md) for detailed explanation of Static Application Security Testing implementation.

## License

This project is for educational purposes.
