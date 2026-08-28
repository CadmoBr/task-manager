# Task Manager

Gerenciador de Tarefas (Task Manager) com Next.js 14 e PostgreSQL.

> Esta branch (`main`) contém só a aplicação. Kubernetes, Terraform, CI/CD e
> observabilidade ficam na branch `dev_aula`, usada na aula.

## Demonstração

![Task Manager UI](https://via.placeholder.com/800x500?text=Task+Manager+UI)

## Funcionalidades

- **CRUD completo** de tarefas (Create, Read, Update, Delete)
- **Status das tarefas**: pendente, em-andamento, concluída
- **Prioridades**: baixa, média, alta
- **Dashboard**: estatísticas e filtros
- **API REST**: endpoints para integração
- **Health check**: endpoint para monitoramento

## Stack Tecnológica

- **Frontend**: Next.js 14 (App Router), Tailwind CSS
- **Backend**: Next.js API Routes
- **Banco de dados**: PostgreSQL 15
- **Containerização**: Docker, Docker Compose
- **Testes**: Jest

## Estrutura do Projeto

```
task-manager/
├── app/              # App Next.js (App Router)
│   ├── api/          # API Routes
│   ├── layout.js     # Layout raiz
│   ├── page.js       # Página principal (UI)
│   └── globals.css   # Estilos globais Tailwind
├── lib/              # Funções de banco de dados
│   ├── db.js         # Pool PostgreSQL
│   └── dbConfig.js   # Configuração de conexão
├── tests/            # Testes Jest para API
├── Dockerfile        # Build da imagem Docker
├── docker-compose.yml # Ambiente local com Docker Compose
├── next.config.js    # Config Next.js
├── tailwind.config.js # Config Tailwind CSS
└── package.json      # Dependências
```

## Instalação e Execução Local

### Pré-requisitos

- Docker e Docker Compose
- Node.js 20+ (opcional, para desenvolvimento local sem Docker)

### Com Docker Compose (Recomendado)

```bash
# Iniciar containers
docker compose up -d

# Acessar a aplicação
open http://localhost:3000

# Verificar health check
curl http://localhost:3000/api/health

# Se precisar resetar o banco de dados
docker compose down -v
docker compose up -d
```

### Desenvolvimento Local

```bash
# Instalar dependências
npm install

# Criar arquivo .env (baseado em .env.example)
cp .env.example .env

# Executar migrations e iniciar servidor
npm run dev
```

## API REST

### Endpoints

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| GET | `/api/tasks` | Listar todas as tarefas |
| GET | `/api/tasks/:id` | Buscar tarefa por ID |
| POST | `/api/tasks` | Criar nova tarefa |
| PUT | `/api/tasks/:id` | Atualizar tarefa |
| DELETE | `/api/tasks/:id` | Deletar tarefa |
| GET | `/api/health` | Health check |

### Exemplo de Request

```bash
# Criar tarefa
curl -X POST http://localhost:3000/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Minha tarefa","description":"Descrição","priority":"alta","status":"pendente"}'

# Listar tarefas
curl http://localhost:3000/api/tasks
```

## Testes

```bash
# Antes de rodar testes, iniciar o servidor
npm run dev &

# Rodar testes
npm test
```

> Nota: Os testes precisam que o servidor esteja rodando em `http://localhost:3000`

## Docker

### Build da Imagem

```bash
docker build -t task-manager .
```

### Executar com Docker

```bash
docker run -p 3000:3000 task-manager
```

## Kubernetes, Terraform e Observabilidade

O diretório `terraform/` provisiona um cluster k3d local, constrói e importa a
imagem da aplicação, instala PostgreSQL e instala via Helm o
`kube-prometheus-stack` (Prometheus + Grafana) e o `loki-stack` (Loki +
Promtail). O dashboard da aplicação combina métricas e logs.

### Executar o ambiente k3d

Pré-requisitos: Docker, k3d, kubectl, Helm e Terraform instalados no WSL.

```bash
terraform -chdir=terraform init
# O primeiro comando cria o cluster e o kubeconfig antes de o provider
# Kubernetes/Helm ser inicializado.
terraform -chdir=terraform apply -target=null_resource.k3d_cluster
terraform -chdir=terraform apply
```

A aplicação fica disponível em `http://localhost:3000` e o Grafana em
`http://localhost:3001` (`admin`/`admin`). Para remover o ambiente:

```bash
terraform -chdir=terraform destroy
```

> O primeiro `apply` precisa ser direcionado ao cluster porque o Terraform
> inicializa os providers antes de executar recursos. Assim, o contexto
> `k3d-task-cluster` ainda não existe no primeiro planejamento completo.

## Branches

- **main**: só a aplicação (Next.js + API + Docker).
- **dev_aula**: aplicação + Kubernetes + Terraform + CI/CD + observabilidade
  (usada na aula).

## Licença

MIT
