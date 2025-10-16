// Configuração do cliente HTTP (contrato)
// Vamos implementar com Dio posteriormente. Aqui fica só o contrato e TODOs.

typedef Headers = Map<String, String>;
typedef QueryParams = Map<String, dynamic>;

/// Abstração mínima de HTTP usada pelos repositórios
abstract class HttpClient {
	Future<HttpResponse<T>> get<T>(String path, {QueryParams? query, Headers? headers});
	Future<HttpResponse<T>> post<T>(String path, {Object? data, Headers? headers});
	Future<HttpResponse<T>> put<T>(String path, {Object? data, Headers? headers});
	Future<HttpResponse<T>> delete<T>(String path, {Object? data, Headers? headers});
}

class HttpResponse<T> {
	final int statusCode;
	final T data;
	final Headers headers;

	const HttpResponse({required this.statusCode, required this.data, this.headers = const {}});
}

/// Interceptors esperados (a serem configurados na implementação com Dio):
/// - AuthorizationInterceptor: adiciona Authorization: Bearer <access_token> quando disponível
/// - RefreshTokenInterceptor: em 401, tenta refresh uma vez e repete a requisição original
/// - LoggingInterceptor: logs condicionais por ambiente
