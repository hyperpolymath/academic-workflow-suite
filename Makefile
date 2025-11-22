# Makefile for Academic Workflow Suite
# Provides convenient commands for Docker operations

.PHONY: help docker-build docker-up docker-down docker-logs docker-test docker-reset \
        docker-dev docker-prod docker-ps docker-exec docker-shell clean

# Default target
.DEFAULT_GOAL := help

# Colors
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
WHITE  := $(shell tput -Txterm setaf 7)
CYAN   := $(shell tput -Txterm setaf 6)
RESET  := $(shell tput -Txterm sgr0)

# Variables
DOCKER_COMPOSE := docker-compose
DOCKER_COMPOSE_DEV := $(DOCKER_COMPOSE) -f docker-compose.yml -f docker-compose.dev.yml
DOCKER_COMPOSE_TEST := $(DOCKER_COMPOSE) -f docker-compose.yml -f docker-compose.test.yml
DOCKER_COMPOSE_PROD := $(DOCKER_COMPOSE) -f docker-compose.yml -f docker-compose.prod.yml

##@ Help

help: ## Display this help message
	@echo ''
	@echo '$(GREEN)Academic Workflow Suite - Docker Commands$(RESET)'
	@echo ''
	@echo 'Usage:'
	@echo '  $(YELLOW)make$(RESET) $(CYAN)<target>$(RESET)'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*##"; printf "\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  $(CYAN)%-20s$(RESET) %s\n", $$1, $$2 } /^##@/ { printf "\n$(YELLOW)%s$(RESET)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Docker - Build

docker-build: ## Build all Docker images
	@echo "$(GREEN)Building all Docker images...$(RESET)"
	$(DOCKER_COMPOSE) build

docker-build-core: ## Build Core Engine image
	@echo "$(GREEN)Building Core Engine image...$(RESET)"
	$(DOCKER_COMPOSE) build core

docker-build-backend: ## Build Backend Service image
	@echo "$(GREEN)Building Backend Service image...$(RESET)"
	$(DOCKER_COMPOSE) build backend

docker-build-ai-jail: ## Build AI Jail image
	@echo "$(GREEN)Building AI Jail image...$(RESET)"
	$(DOCKER_COMPOSE) build ai-jail

docker-build-nginx: ## Build Nginx image
	@echo "$(GREEN)Building Nginx image...$(RESET)"
	$(DOCKER_COMPOSE) build nginx

##@ Docker - Start/Stop

docker-up: docker-dev ## Start development environment (alias for docker-dev)

docker-dev: ## Start development environment
	@echo "$(GREEN)Starting development environment...$(RESET)"
	./docker/scripts/docker-up.sh dev

docker-prod: ## Start production environment
	@echo "$(GREEN)Starting production environment...$(RESET)"
	./docker/scripts/docker-up.sh prod

docker-down: ## Stop all services
	@echo "$(GREEN)Stopping all services...$(RESET)"
	./docker/scripts/docker-down.sh dev

docker-down-prod: ## Stop production services
	@echo "$(GREEN)Stopping production services...$(RESET)"
	./docker/scripts/docker-down.sh prod

docker-restart: docker-down docker-up ## Restart development environment

##@ Docker - Testing

docker-test: ## Run tests in Docker containers
	@echo "$(GREEN)Running tests in Docker...$(RESET)"
	./docker/scripts/docker-up.sh test

docker-test-core: ## Run Core Engine tests
	@echo "$(GREEN)Running Core Engine tests...$(RESET)"
	$(DOCKER_COMPOSE_TEST) run --rm core cargo test

docker-test-backend: ## Run Backend Service tests
	@echo "$(GREEN)Running Backend Service tests...$(RESET)"
	$(DOCKER_COMPOSE_TEST) run --rm backend mix test

docker-test-integration: ## Run integration tests
	@echo "$(GREEN)Running integration tests...$(RESET)"
	$(DOCKER_COMPOSE_TEST) run --rm test-runner

##@ Docker - Logs & Status

docker-logs: ## View logs for all services
	@echo "$(GREEN)Viewing logs for all services...$(RESET)"
	./docker/scripts/docker-logs.sh

docker-logs-core: ## View Core Engine logs
	@echo "$(GREEN)Viewing Core Engine logs...$(RESET)"
	./docker/scripts/docker-logs.sh core

docker-logs-backend: ## View Backend Service logs
	@echo "$(GREEN)Viewing Backend Service logs...$(RESET)"
	./docker/scripts/docker-logs.sh backend

docker-logs-ai-jail: ## View AI Jail logs
	@echo "$(GREEN)Viewing AI Jail logs...$(RESET)"
	./docker/scripts/docker-logs.sh ai-jail

docker-ps: ## Show status of all services
	@echo "$(GREEN)Service Status:$(RESET)"
	$(DOCKER_COMPOSE) ps

##@ Docker - Access

docker-exec: ## Execute command in a service (usage: make docker-exec SERVICE=core CMD="bash")
	@echo "$(GREEN)Executing command in $(SERVICE)...$(RESET)"
	$(DOCKER_COMPOSE) exec $(SERVICE) $(CMD)

docker-shell-core: ## Open shell in Core Engine container
	@echo "$(GREEN)Opening shell in Core Engine...$(RESET)"
	$(DOCKER_COMPOSE) exec core /bin/bash

docker-shell-backend: ## Open shell in Backend Service container
	@echo "$(GREEN)Opening shell in Backend Service...$(RESET)"
	$(DOCKER_COMPOSE) exec backend /bin/bash

docker-shell-postgres: ## Open psql shell in PostgreSQL container
	@echo "$(GREEN)Opening PostgreSQL shell...$(RESET)"
	$(DOCKER_COMPOSE) exec postgres psql -U aws_user -d academic_workflow

docker-shell-redis: ## Open redis-cli in Redis container
	@echo "$(GREEN)Opening Redis shell...$(RESET)"
	$(DOCKER_COMPOSE) exec redis redis-cli

##@ Docker - Database

docker-db-migrate: ## Run database migrations
	@echo "$(GREEN)Running database migrations...$(RESET)"
	$(DOCKER_COMPOSE) exec backend mix ecto.migrate

docker-db-rollback: ## Rollback last database migration
	@echo "$(GREEN)Rolling back last migration...$(RESET)"
	$(DOCKER_COMPOSE) exec backend mix ecto.rollback

docker-db-reset: ## Reset database
	@echo "$(GREEN)Resetting database...$(RESET)"
	$(DOCKER_COMPOSE) exec backend mix ecto.reset

docker-db-seed: ## Seed database
	@echo "$(GREEN)Seeding database...$(RESET)"
	$(DOCKER_COMPOSE) exec backend mix run priv/repo/seeds.exs

docker-db-backup: ## Backup PostgreSQL database
	@echo "$(GREEN)Backing up database...$(RESET)"
	docker-compose exec -T postgres pg_dump -U aws_user academic_workflow | gzip > backups/postgres/backup_$$(date +%Y%m%d_%H%M%S).sql.gz

##@ Docker - Cleanup

docker-reset: ## Reset all Docker data (WARNING: deletes all data)
	@echo "$(YELLOW)WARNING: This will delete ALL Docker data!$(RESET)"
	./docker/scripts/docker-reset.sh

docker-clean: ## Clean up dangling images and containers
	@echo "$(GREEN)Cleaning up Docker...$(RESET)"
	docker system prune -f

docker-clean-volumes: ## Clean up all volumes (WARNING: deletes data)
	@echo "$(YELLOW)WARNING: This will delete all volumes!$(RESET)"
	./docker/scripts/docker-down.sh dev --volumes

##@ Docker - Monitoring

docker-stats: ## Show container resource usage
	@echo "$(GREEN)Container Resource Usage:$(RESET)"
	docker stats --no-stream

docker-prometheus: ## Open Prometheus dashboard
	@echo "$(GREEN)Opening Prometheus at http://localhost:9090$(RESET)"
	@which xdg-open > /dev/null && xdg-open http://localhost:9090 || open http://localhost:9090 || echo "Please open http://localhost:9090 in your browser"

docker-grafana: ## Open Grafana dashboard
	@echo "$(GREEN)Opening Grafana at http://localhost:3000$(RESET)"
	@which xdg-open > /dev/null && xdg-open http://localhost:3000 || open http://localhost:3000 || echo "Please open http://localhost:3000 in your browser"

docker-adminer: ## Open Adminer database UI
	@echo "$(GREEN)Opening Adminer at http://localhost:8081$(RESET)"
	@which xdg-open > /dev/null && xdg-open http://localhost:8081 || open http://localhost:8081 || echo "Please open http://localhost:8081 in your browser"

##@ Development

dev-format: ## Format code in all components
	@echo "$(GREEN)Formatting code...$(RESET)"
	cd components/core && cargo fmt
	cd components/backend && mix format
	cd components/ai-jail && cargo fmt

dev-lint: ## Lint code in all components
	@echo "$(GREEN)Linting code...$(RESET)"
	cd components/core && cargo clippy -- -D warnings
	cd components/backend && mix credo
	cd components/ai-jail && cargo clippy -- -D warnings

dev-deps: ## Update dependencies
	@echo "$(GREEN)Updating dependencies...$(RESET)"
	cd components/core && cargo update
	cd components/backend && mix deps.update --all
	cd components/ai-jail && cargo update

##@ CI/CD

ci-test: docker-test ## Run CI tests

ci-build: docker-build ## Build for CI

ci-lint: dev-lint ## Lint for CI

##@ Information

docker-version: ## Show Docker and Docker Compose versions
	@echo "$(GREEN)Docker Version:$(RESET)"
	@docker --version
	@echo "$(GREEN)Docker Compose Version:$(RESET)"
	@docker-compose --version

docker-config: ## Show Docker Compose configuration
	@echo "$(GREEN)Docker Compose Configuration:$(RESET)"
	$(DOCKER_COMPOSE) config

docker-images: ## List all AWS images
	@echo "$(GREEN)AWS Docker Images:$(RESET)"
	@docker images | grep -E "REPOSITORY|aws-"

docker-volumes: ## List all AWS volumes
	@echo "$(GREEN)AWS Docker Volumes:$(RESET)"
	@docker volume ls | grep -E "DRIVER|academic-workflow-suite"

docker-networks: ## List all AWS networks
	@echo "$(GREEN)AWS Docker Networks:$(RESET)"
	@docker network ls | grep -E "NAME|academic-workflow-suite"
