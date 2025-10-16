// TODO: Configurações de ambiente (BASE_URL, timeouts). Pode ler .env ou usar consts por flavor.

abstract class EnvKeys {
	static const baseUrl = 'BASE_URL';
	static const connectTimeoutMs = 'CONNECT_TIMEOUT_MS';
	static const receiveTimeoutMs = 'RECEIVE_TIMEOUT_MS';
}

/// Leitor de env (placeholder)
class EnvConfig {
	// TODO: integrar flutter_dotenv; por ora, valores padrão
	String get baseUrl => const String.fromEnvironment(EnvKeys.baseUrl, defaultValue: 'http://localhost:8000');
	int get connectTimeoutMs => const int.fromEnvironment(EnvKeys.connectTimeoutMs, defaultValue: 10000);
	int get receiveTimeoutMs => const int.fromEnvironment(EnvKeys.receiveTimeoutMs, defaultValue: 15000);
}
