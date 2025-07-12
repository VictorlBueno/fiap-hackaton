.PHONY: help deploy-all destroy-all status-all clean-all

# Configurações do projeto
PROJECT_NAME = fiap-hack
AWS_REGION = us-east-1
ENVIRONMENT = production

help: ## Mostra esta ajuda
	@echo "🚀 FIAP Hack - Sistema de Processamento de Vídeos"
	@echo ""
	@echo "📋 Comandos disponíveis:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# =============================================================================
# DEPLOY COMPLETO
# =============================================================================

deploy-all: ## Deploy completo de toda a infraestrutura
	@echo "🚀 Iniciando deploy completo..."
	@echo "📋 Ordem: VPC → EKS → Database → Redis → RabbitMQ → Service → Monitoring"
	@echo ""
	@echo "1️⃣ Deploy da VPC..."
	cd vpc && make deploy
	@echo ""
	@echo "2️⃣ Deploy do EKS..."
	cd eks && make deploy
	@echo ""
	@echo "3️⃣ Deploy do Database..."
	cd database && make deploy
	@echo ""
	@echo "4️⃣ Deploy do Redis..."
	cd redis && make deploy
	@echo ""
	@echo "5️⃣ Deploy do RabbitMQ..."
	cd rabbitmq && make deploy
	@echo ""
	@echo "6️⃣ Deploy do Video Service..."
	cd service && make deploy
	@echo ""
	@echo "7️⃣ Deploy do Sistema de Monitoramento..."
	cd monitoring && make deploy-all
	@echo ""
	@echo "✅ Deploy completo finalizado!"

deploy-infra: ## Deploy apenas da infraestrutura (VPC, EKS, DB, Redis, RabbitMQ)
	@echo "🏗️ Deploy da infraestrutura..."
	cd vpc && make deploy
	cd eks && make deploy
	cd database && make deploy
	cd redis && make deploy
	cd rabbitmq && make deploy
	@echo "✅ Infraestrutura deployada!"

deploy-services: ## Deploy apenas dos serviços (Auth, Video)
	@echo "🔧 Deploy dos serviços..."
	cd auth && make deploy
	cd service && make deploy
	@echo "✅ Serviços deployados!"

# =============================================================================
# STATUS E MONITORAMENTO
# =============================================================================

status-all: ## Status de todos os componentes
	@echo "📊 Status de todos os componentes:"
	@echo ""
	@echo "🏗️ VPC:"
	cd vpc && make output
	@echo ""
	@echo "☸️ EKS:"
	cd eks && make output
	@echo ""
	@echo "🗄️ Database:"
	cd database && make output
	@echo ""
	@echo "🔴 Redis:"
	cd redis && make status
	@echo ""
	@echo "🐰 RabbitMQ:"
	cd rabbitmq && make status
	@echo ""
	@echo "🎥 Video Service:"
	cd service && make k8s-status 2>/dev/null || echo "Video service não deployado"
	@echo ""
	@echo "📊 Sistema de Monitoramento:"
	cd monitoring && make status 2>/dev/null || echo "Sistema de monitoramento não deployado"

get-credentials: ## Obtém todas as credenciais
	@echo "🔑 Credenciais do sistema:"
	@echo ""
	@echo "🗄️ Database:"
	cd database && make get-credentials
	@echo ""
	@echo "🐰 RabbitMQ:"
	cd rabbitmq && make get-credentials

test-connections: ## Testa todas as conexões
	@echo "🔍 Testando conexões:"
	@echo ""
	@echo "🗄️ Database:"
	cd database && make test-connection
	@echo ""
	@echo "🐰 RabbitMQ:"
	cd rabbitmq && make test-connection

# =============================================================================
# DESTRUIR INFRAESTRUTURA
# =============================================================================

destroy-all: ## Destroi toda a infraestrutura
	@echo "⚠️  ATENÇÃO: Isso irá destruir TODA a infraestrutura!"
	@echo "📋 Ordem: Monitoring → Service → RabbitMQ → Redis → Database → EKS → VPC"
	@read -p "Confirma a destruição? (digite 'sim' para confirmar): " confirm; \
	if [ "$$confirm" = "sim" ]; then \
		echo "🗑️ Destruindo infraestrutura..."; \
		cd monitoring && make destroy-all; \
		cd ../service && make terraform-destroy; \
		cd ../rabbitmq && make destroy; \
		cd ../redis && make destroy; \
		cd ../database && make destroy; \
		cd ../eks && make destroy; \
		cd ../vpc && make destroy; \
		echo "✅ Infraestrutura destruída!"; \
	else \
		echo "❌ Operação cancelada."; \
	fi

terraform-destroy-all: ## Destroi TODOS os Terraforms sem confirmação
	@echo "🗑️ Destruindo TODA a infraestrutura Terraform..."
	@echo "📋 Ordem: Monitoring → Service → RabbitMQ → Redis → Database → EKS → VPC"
	cd monitoring && make destroy-all
	cd service && make terraform-destroy
	cd rabbitmq && make destroy
	cd redis && make destroy
	cd database && make destroy
	cd eks && make destroy
	cd vpc && make destroy
	@echo "✅ TODA a infraestrutura Terraform destruída!"

rebuild-all: ## Destroi e reconstrói toda a infraestrutura
	@echo "🔄 Reconstruindo toda a infraestrutura..."
	@echo "📋 Ordem: Destroy → Deploy"
	@echo ""
	@echo "1️⃣ Destruindo infraestrutura atual..."
	$(MAKE) terraform-destroy-all
	@echo ""
	@echo "2️⃣ Reconstruindo infraestrutura..."
	$(MAKE) deploy-all
	@echo ""
	@echo "✅ Reconstrução completa finalizada!"

destroy-services: ## Destroi apenas os serviços
	@echo "🗑️ Destruindo serviços..."
	cd service && make terraform-destroy
	cd rabbitmq && make destroy
	cd redis && make destroy
	@echo "✅ Serviços destruídos!"

destroy-infra: ## Destroi apenas a infraestrutura
	@echo "🗑️ Destruindo infraestrutura..."
	cd database && make destroy
	cd eks && make destroy
	cd vpc && make destroy
	@echo "✅ Infraestrutura destruída!"

# =============================================================================
# DESENVOLVIMENTO
# =============================================================================

dev-setup: ## Configura ambiente de desenvolvimento
	@echo "🔧 Configurando ambiente de desenvolvimento..."
	@echo "📦 Instalando dependências..."
	cd app && npm install
	cd service && npm install
	cd auth && npm install
	@echo "✅ Ambiente configurado!"

dev-start: ## Inicia ambiente de desenvolvimento
	@echo "🚀 Iniciando ambiente de desenvolvimento..."
	@echo "📱 Frontend: http://localhost:3000"
	@echo "🔧 Service: http://localhost:3001"
	@echo "🔐 Auth: http://localhost:3002"
	@echo ""
	@echo "Use 'make dev-stop' para parar todos os serviços"
	cd app && npm start &
	cd service && npm run start:dev &
	cd auth && npm run start:dev &

dev-stop: ## Para ambiente de desenvolvimento
	@echo "🛑 Parando ambiente de desenvolvimento..."
	pkill -f "npm start" || true
	pkill -f "npm run start:dev" || true
	@echo "✅ Serviços parados!"

# =============================================================================
# TESTES
# =============================================================================

test-all: ## Executa todos os testes
	@echo "🧪 Executando todos os testes..."
	@echo ""
	@echo "🔧 Service Tests:"
	cd service && npm test
	@echo ""
	@echo "🔐 Auth Tests:"
	cd auth && npm test
	@echo ""
	@echo "📱 Frontend Tests:"
	cd app && npm test
	@echo "✅ Todos os testes executados!"

# =============================================================================
# MONITORAMENTO
# =============================================================================

monitoring-deploy: ## Deploy do sistema de monitoramento
	@echo "📊 Deploy do sistema de monitoramento..."
	cd monitoring && make deploy-all

monitoring-status: ## Status do sistema de monitoramento
	@echo "📊 Status do sistema de monitoramento..."
	cd monitoring && make status

monitoring-logs: ## Logs do sistema de monitoramento
	@echo "📋 Logs do sistema de monitoramento..."
	cd monitoring && make logs-all

monitoring-grafana: ## Acesso ao Grafana
	@echo "🌐 Acessando Grafana..."
	cd monitoring && make get-grafana-url

monitoring-port-forward: ## Port-forward para Grafana (desenvolvimento)
	@echo "🌐 Port-forward para Grafana..."
	cd monitoring && make port-forward-grafana

monitoring-test: ## Testa conectividade do monitoramento
	@echo "🔍 Testando conectividade do monitoramento..."
	cd monitoring && make test-connectivity

monitoring-destroy: ## Destroi sistema de monitoramento
	@echo "🗑️ Destruindo sistema de monitoramento..."
	cd monitoring && make destroy-all