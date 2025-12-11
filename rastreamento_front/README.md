# Rastreamento Front-End

Flutter web/mobile client for the vehicle tracking project.

## Requisitos

- Flutter 3.8.1 ou superior (garante suporte a `--dart-define-from-file`).
- Conta no [Render](https://render.com/) e repositório GitHub com acesso ao projeto.
- Tokens/URLs:
  - `API_BASE_URL`: URL base do backend (https://... sem barra final).
  - `GOOGLE_MAPS_API_KEY`: chave JavaScript do Google Maps liberada para o domínio do Render.

## Preparando variáveis de ambiente

1. Copie o arquivo `.env.example` para o nome que preferir (ex.: `.env.local`).
2. Preencha os valores reais:

	```env
	API_BASE_URL=https://seu-backend.com
	GOOGLE_MAPS_API_KEY=chave_google_maps
	```

3. Execute o projeto apontando para o arquivo escolhido:

	```powershell
	flutter pub get
	flutter run --dart-define-from-file=.env.local
	```

> `.env` e variantes já estão ignorados pelo Git, mantendo os segredos fora do repositório.

## Build de produção local (opcional)

Para gerar os artefatos web localmente:

```powershell
flutter build web --release --dart-define-from-file=.env.local
```

Os arquivos finais ficam em `build/web`.

## Deploy no Render (Static Site)

1. **Push no GitHub**: garanta que as alterações (incluindo `.env.example`) estejam na branch principal que será usada no Render.
2. **Criar o serviço**: em *Dashboard → New → Static Site*, conecte o repositório GitHub e escolha a branch de deploy.
3. **Configurar variáveis** (Settings → Environment):
	- `API_BASE_URL` → URL pública do backend.
	- `GOOGLE_MAPS_API_KEY` → chave do Google Maps (habilite o domínio `<seu-serviço>.onrender.com`).
4. **Build Command**:

	```bash
	flutter pub get && \
	flutter build web --release \
	  --dart-define=API_BASE_URL=$API_BASE_URL \
	  --dart-define=GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY
	```

5. **Publish Directory**: `build/web`.
6. **Regras de rota (opcional, mas recomendado)**: adicione um rewrite `/* → /index.html` (Status `200`) para que o SPA funcione em refresh direto.
7. Salve as configurações e aguarde o primeiro build. A cada push nessa branch o Render rebuildará automaticamente.

### Observações importantes

- Ajuste as restrições de referer da chave Google Maps para incluir o domínio do Render.
- Caso o backend utilize WebSocket, o URL será derivado automaticamente a partir de `API_BASE_URL`.
- Para ambientes adicionais, crie novos arquivos `.env.<ambiente>` e utilize `--dart-define-from-file` apropriado.
- Se mudar o domínio do backend, basta atualizar a variável no Render (não é necessário novo commit).

## Scripts úteis

- `flutter analyze lib` – análise estática.
- `flutter format .` – formata o código.
- `flutter test` – executa os testes existentes.
