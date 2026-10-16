# Gallani Back

API Rails da operação da Gallani.

## Stack

- Ruby 3.2.3
- Rails 7.1
- PostgreSQL 16
- Docker Compose

## Subindo o projeto

```bash
docker compose up -d
docker compose exec api bundle install
docker compose exec api bin/rails db:migrate
```

Copie `.env.example` para `.env` e preencha localmente os valores sensíveis. O arquivo `.env` não deve ser versionado.

## Login da plataforma

Somente administradores e profissionais possuem conta na plataforma.

O primeiro administrador pode ser preparado pela task:

```bash
ADMIN_NAME="Administrador" \
ADMIN_EMAIL="admin@example.com" \
ADMIN_PASSWORD="$ADMIN_PASSWORD" \
docker compose exec api bin/rails gallani:bootstrap_admin
```

Login:

```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "admin@example.com",
  "password": "<senha-do-usuario>"
}
```

A resposta contém um Bearer Token revogável e com expiração.

Rotas auxiliares:

- `GET /api/v1/auth/me`
- `DELETE /api/v1/auth/logout`

## Acesso administrativo

Prefixo: `/api/v1/admin`

Administradores gerenciam usuários, serviços, profissionais, disponibilidade, agenda, caixa e dashboard.

## Acesso do profissional

Prefixo: `/api/v1/professional`

O profissional só acessa o próprio contexto e não altera cadastro, serviços ou disponibilidade.

- `GET /profile`
- `GET /agenda?from=&to=`
- `GET /customers?query=`
- `POST /customers`
- `POST /appointments`

Ao criar um agendamento, o backend ignora qualquer `professional_id` enviado e usa o profissional autenticado.

## Integração Nexa

A integração do chatbot usa token técnico separado de login humano.

Criação do token:

```bash
TOKEN_LABEL=nexa docker compose exec api bin/rails gallani:integration_token
```

Prefixo: `/api/v1/integrations/nexa`

- `GET /services`
- `GET /professionals?service_id=`
- `GET|POST /customers`
- `GET /availability?professional_id=&date=YYYY-MM-DD`
- `GET|POST /appointments`
- `PATCH /appointments/:id/cancel`
- `PATCH /appointments/:id/reschedule`

## Regras principais

- Serviços e profissionais são desativados, não excluídos pela interface atual.
- Profissional desativado perde acesso às rotas autenticadas de profissional.
- Agendamentos cancelados permanecem armazenados.
- Horários são cadastrados explicitamente; não há geração automática por duração.
- Exceções de disponibilidade substituem os horários semanais da data.
- A combinação profissional + data + horário não aceita dois agendamentos ativos.
- A conclusão de um agendamento cria uma única entrada financeira.
- O preço do agendamento fica armazenado no próprio agendamento.
