# Arquitetura por Entidades

Este app organiza o código por entidade (ex.: `auth`, `user`) e, dentro de cada entidade, mantemos `model`, `repository`, `service`, `controller` e, quando aplicável, `views`.

- entities/
  - auth/
    - model.dart
    - repository.dart
    - service.dart
    - controller.dart
    - views/
      - login_view.dart
      - login_controller.dart
      - login_state.dart
  - user/
    - model.dart
    - repository.dart
    - service.dart
    - controller.dart

- core/
  - di/di.dart — composição de dependências (get_it)
  - routing/app_router.dart — rotas (go_router/Navigator 2.0)
  - config/env.dart — configuração de ambiente (ex.: BASE_URL)

- shared/
  - network/http_client.dart — cliente HTTP (Dio)
  - constants/app_constants.dart — constantes
  - theme/app_theme.dart — tema
  - utils/validators.dart — validadores
  - widgets/ — componentes reutilizáveis

Fluxo de login (alto nível):
1. LoginView coleta email/senha e chama LoginController.
2. LoginController orquestra e delega para AuthController.
3. AuthController usa AuthService.
4. AuthService aplica regras (persistência de tokens) e chama AuthRepository.
5. AuthRepository chama FastAPI via shared/network/http_client.
6. Em caso de sucesso, Service salva tokens (secure storage/web storage) e retorna estado atualizado.

Próximos passos de implementação:
- Definir contratos (interfaces) em repository/service/controller para `auth`.
- Implementar http_client com Dio e interceptors (Authorization, refresh token).
- Implementar LoginView responsiva para web e mobile.
- Integrar AppRouter apontando rota inicial para LoginView.

## Escopo dos aplicativos

- App Android (motorista):
  - Tela 1: Login
  - Tela 2: Botão "Ativar Rastreamento" (on/off), exibindo status atual
  - Comunicação com backend para registrar/atualizar estado do rastreamento (futuro)

- App Web (admin):
  - Tela 1: Login
  - Tela 2+: Cadastro de veículos e associação com rastreadores (futuro)

Neste momento, focaremos somente na tela de Login comum aos dois apps (UI responsiva).

## Contrato de autenticação (assumido para FastAPI)

- POST /auth/login
  - Request JSON: { "email": string, "password": string }
  - Response JSON: { "access_token": string, "refresh_token": string }

- POST /auth/refresh
  - Request JSON: { "refresh_token": string }
  - Response JSON: { "access_token": string, "refresh_token": string (opcional) }

Regras:
- access_token será usado no header Authorization: Bearer <token>.
- refresh_token será persistido em storage seguro (mobile) e web storage (web) para renovação transparente.

## Storage

- Mobile (Android): `flutter_secure_storage` para tokens sensíveis; `shared_preferences` para preferências leves (ex.: login lembrado).
- Web: `shared_preferences` (via web) para tokens NÃO sensíveis ou usar estratégia de cookies httpOnly (se backend suportar). Como placeholder, usaremos storage simples até definir a política final.

## Rotas e navegação

- Rota inicial: `/login` -> LoginView
- Após sucesso: `/` (home) — no Android será a tela de rastreamento; no Web, o dashboard/admin (a definir)
- Guardas de rota (futuro): bloquear telas autenticadas sem token válido; refresh automático.

## UI da LoginView (requisitos)

- Campos: email, senha
- Ações: entrar; feedback de loading/erro
- Requisitos de responsividade: layout centralizado no web com largura máxima; no mobile, ocupa tela inteira; acessível a teclado e leitores.
- Erros comuns: credenciais inválidas, rede indisponível; mensagens amigáveis.
