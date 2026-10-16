# API externa para automação

As rotas abaixo são o contrato técnico destinado ao fluxo da automação/chatbot. Elas não usam sessão de admin ou profissional.

## Autenticação

Use um Bearer Token de integração:

```http
Authorization: Bearer <integration-token>
```

O token pode ser criado pela task:

```bash
TOKEN_LABEL=nexa docker compose exec api bin/rails gallani:integration_token
```

Prefixo base:

```text
/api/v1/integrations/nexa
```

## 1. Buscar serviços ativos

```http
GET /services
```

Retorna os serviços disponíveis para o fluxo.

## 2. Buscar profissionais

```http
GET /professionals
GET /professionals?service_id=1
```

Retorna somente profissionais ativos. Quando `service_id` é informado, retorna somente profissionais vinculados ao serviço.

## 3. Consultar cliente pelo telefone

```http
GET /customers?phone=11988887777
```

O telefone é normalizado no backend.

Quando o cliente não existe:

```json
{
  "data": []
}
```

Quando for necessário cadastrar um cliente novo:

```http
POST /customers
Content-Type: application/json

{
  "customer": {
    "name": "João",
    "phone": "11988887777",
    "email": "joao@example.com"
  }
}
```

## 4. Consultar horários disponíveis

```http
GET /availability?professional_id=10&date=2026-11-01
```

Retorna apenas horários realmente disponíveis depois de aplicar grade semanal, exceções, bloqueios e agendamentos ativos.

## 5. Criar agendamento

```http
POST /appointments
Content-Type: application/json

{
  "appointment": {
    "customer_id": 20,
    "professional_id": 10,
    "service_id": 3,
    "date": "2026-11-01",
    "time": "10:00"
  }
}
```

O preço não deve ser enviado. O backend copia o preço atual do serviço e grava esse valor no agendamento.

## 6. Buscar agendamentos ativos do cliente

Necessário para o fluxo localizar o agendamento que será remarcado ou cancelado.

```http
GET /appointments?customer_id=20
```

Retorna somente agendamentos futuros em status `scheduled` ou `confirmed`, ordenados por data e horário.

## 7. Consultar um agendamento

```http
GET /appointments/:id
```

## 8. Remarcar

```http
PATCH /appointments/:id/reschedule
Content-Type: application/json

{
  "date": "2026-11-02",
  "time": "11:00"
}
```

A remarcação volta o agendamento para `scheduled` e respeita disponibilidade, bloqueios e concorrência.

## 9. Cancelar

```http
PATCH /appointments/:id/cancel
```

O registro permanece no histórico com status `cancelled`.

## Rotas que não devem ser usadas pela automação

O fluxo não deve chamar diretamente rotas administrativas de:

- criação/edição de serviços;
- criação/edição de profissionais;
- disponibilidade semanal;
- exceções;
- bloqueios;
- caixa;
- dashboard;
- usuários e sessões.

Esses recursos pertencem ao sistema administrativo.
