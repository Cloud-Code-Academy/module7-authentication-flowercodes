/**
 * Service class to handle OAuth 2.0 authentication with Salesforce
 * STUDENT VERSION - Complete the method implementations
 */
public class SFAuthenticationManager {
	private static final String TOKEN_ENDPOINT = '/services/oauth2/token';
	private static final String AUTHORIZE_ENDPOINT = '/services/oauth2/authorize';
	private static final String PKCE_GENERATOR_ENDPOINT = '/services/oauth2/pkce/generator';

	// Configuration values
	public static final String DEFAULT_CLIENT_ID = 'fakeclientid';
	public static final String DEFAULT_CLIENT_SECRET = 'fakeclientsecret';
	public static final String DEFAULT_LOGIN_URL = 'https://resourceful-wolf-s9a1a-dev-ed.trailblaze.my.salesforce.com';
	public static final String DEFAULT_REDIRECT_URL = 'https://playful-narwhal-eu8yy0-dev-ed.trailblaze.my.site.com/callback';

	/**
	 * Central method to make OAuth token requests
	 * TODO: Complete this method implementation
	 * @param params Map of parameters to include in the request
	 * @param tokenUrl The full URL to the token endpoint
	 * @return Authentication response with token details or error
	 */
	private static AuthResponse makeTokenRequest(Map<String, String> params, String tokenUrl) {
		// TODO: Create HTTP request
		HttpRequest request = new HttpRequest();
		Http http = new Http();
		// TODO: Set endpoint, method, and headers
		request.setEndpoint(tokenUrl);
		request.setMethod('POST');
		request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
		request.setHeader('Accept', 'application/json');
		// TODO: Convert parameters to URL encoded string
		List<String> paramList = new List<String>();
		for (String key : params.keySet()) {
			String encodedKey = EncodingUtil.urlEncode(key, 'UTF-8');
			String encodedValue = EncodingUtil.urlEncode(params.get(key), 'UTF-8');
			paramList.add(encodedKey + '=' + encodedValue);
		}
		String requestBody = String.join(paramList, '&');
		// TODO: Set request body
		request.setBody(requestBody);
		// TODO: Send the request and handle response
		HttpResponse response;
		try {
			response = http.send(request);
		} catch (Exception e) {
			// Handle exceptions
			AuthResponse authResponse = new AuthResponse();
			authResponse.isSuccess = false;
			authResponse.errorMessage = 'Exception during token request: ' + e.getMessage();
			return authResponse;
		}

		// TODO: Parse success and error responses
		AuthResponse authResponse = new AuthResponse();
		if (response.getStatusCode() == 200) {
			// Parse successful response
			Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(
				response.getBody()
			);
			authResponse.isSuccess = true;
			authResponse.accessToken = (String) responseMap.get('access_token');
			authResponse.refreshToken = (String) responseMap.get('refresh_token');
			authResponse.instanceUrl = (String) responseMap.get('instance_url');
			authResponse.tokenType = (String) responseMap.get('token_type');
			authResponse.expiresIn = (Integer) responseMap.get('expires_in');
		} else {
			// Parse error response
			Map<String, Object> errorMap = (Map<String, Object>) JSON.deserializeUntyped(
				response.getBody()
			);
			authResponse.isSuccess = false;
			authResponse.errorMessage = (String) errorMap.get('error_description');
			authResponse.errorDetails = (String) errorMap.get('error');
		}

		return authResponse;
	}

	/**
	 * Authenticate using username and password flow (grant_type=password)
	 * TODO: Complete this method implementation
	 * @param username Username for the org
	 * @param password Password + Security Token
	 * @param securityToken Security Token
	 * @return Authentication response with token details or error
	 */
	public static AuthResponse authenticateWithPassword(
		String username,
		String password,
		String securityToken
	) {
		// TODO: Prepare parameters map with:
		// - grant_type: 'password'
		// - client_id: DEFAULT_CLIENT_ID
		// - client_secret: DEFAULT_CLIENT_SECRET
		// - username: username
		// - password: password + securityToken
		Map<String, String> params = new Map<String, String>{
			'grant_type' => 'password',
			'client_id' => DEFAULT_CLIENT_ID,
			'client_secret' => DEFAULT_CLIENT_SECRET,
			'username' => username,
			'password' => password + securityToken
		};

		// TODO: Call makeTokenRequest with params and token URL
		String tokenUrl = DEFAULT_LOGIN_URL + TOKEN_ENDPOINT;
		AuthResponse authResponse = SFAuthenticationManager.makeTokenRequest(params, tokenUrl);

		return authResponse;
	}

	/**
	 * Authenticate using client credentials flow (grant_type=client_credentials)
	 * TODO: Complete this method implementation
	 * @return Authentication response with token details or error
	 */
	public static AuthResponse authenticateWithClientCredentials() {
		// TODO: Prepare parameters map with:
		Map<String, String> params = new Map<String, String>{
			'grant_type' => 'client_credentials',
			'client_id' => DEFAULT_CLIENT_ID,
			'client_secret' => DEFAULT_CLIENT_SECRET
		};

		// TODO: Call makeTokenRequest with params and token URL
		String tokenUrl = DEFAULT_LOGIN_URL + TOKEN_ENDPOINT;
		AuthResponse authResponse = SFAuthenticationManager.makeTokenRequest(params, tokenUrl);

		return authResponse;
	}

	/**
	 * JWT Bearer Token Flow authentication
	 * TODO: Complete this method implementation
	 * @param username Username for the org
	 * @return Authentication response with token details or error
	 */
	public static AuthResponse authenticateWithJWT(String username) {
		// TODO: Create JWT using Auth.JWT class
		// TODO: Set sub (username), aud (audience), and iss (client_id)
		// TODO: Create JWS (JSON Web Signature) with the JWT
		// TODO: Get the compact serialization (token string)
		// TODO: Create JWTBearerTokenExchange and get access token

		Auth.JWT jwt = new Auth.JWT();
		jwt.setSub(username);
		jwt.setAud('https://login.salesforce.com');
		jwt.setIss(DEFAULT_CLIENT_ID);

		Auth.JWS jws = new Auth.JWS(jwt, 'jwtsource');
		String token = jws.getCompactSerialization();
		String tokenEndpoint = DEFAULT_LOGIN_URL + '/services/oauth2/token';
		Auth.JWTBearerTokenExchange bearer = new Auth.JWTBearerTokenExchange(tokenEndpoint, jws);
		String accessToken = bearer.getAccessToken();
		if (String.isBlank(accessToken)) {
			AuthResponse authResponse = new AuthResponse();
			authResponse.isSuccess = false;
			authResponse.errorMessage = 'Failed to obtain access token using JWT';
			return authResponse;
		}

		// Return AuthResponse with token details
		AuthResponse authResponse = new AuthResponse();
		authResponse.accessToken = accessToken;
		authResponse.isSuccess = true;
		authResponse.instanceUrl = DEFAULT_LOGIN_URL; // Assuming instance URL is the same as login URL
		return authResponse;
	}

	/**
	 * Generate the authorization URL for Web Server Flow
	 * TODO: Complete this method implementation
	 * @param state Optional state parameter for CSRF protection
	 * @return Full authorization URL
	 */
	@AuraEnabled
	public static String generateAuthorizationUrl(String state) {
		// TODO: Build authorization URL with:
		// - DEFAULT_LOGIN_URL + AUTHORIZE_ENDPOINT
		// - client_id parameter (URL encoded)
		// - redirect_uri parameter (URL encoded)
		// - response_type=code
		// - state parameter if provided (URL encoded)
		String baseUrl = DEFAULT_LOGIN_URL + AUTHORIZE_ENDPOINT;
		String urlBuilder;
		urlBuilder = baseUrl + '?';
		urlBuilder += 'client_id=' + EncodingUtil.urlEncode(DEFAULT_CLIENT_ID, 'UTF-8');
		urlBuilder += '&redirect_uri=' + EncodingUtil.urlEncode(DEFAULT_REDIRECT_URL, 'UTF-8');
		urlBuilder += '&response_type=code';
		if (!String.isBlank(state)) {
			urlBuilder += '&state=' + EncodingUtil.urlEncode(state, 'UTF-8');
		}

		// STUB: Return placeholder URL for now
		return urlBuilder;
	}

	/**
	 * Generate PKCE data for OAuth 2.0 authorization
	 * TODO: Complete this method implementation
	 * @return PkceResponse containing code verifier and challenge
	 */
	@AuraEnabled
	public static PkceResponse generatePkceData() {
		// TODO: Create HTTP request to PKCE generator endpoint
		// TODO: Set method to GET and content-type header
		// TODO: Send request and handle response
		// TODO: Parse response for code_verifier, code_challenge, and code_challenge_method
		HttpRequest request = new HttpRequest();
		Http http = new Http();
		String pkceUrl = DEFAULT_LOGIN_URL + PKCE_GENERATOR_ENDPOINT;
		request.setEndpoint(pkceUrl);
		request.setMethod('GET');
		request.setHeader('Content-Type', 'application/json');
		HttpResponse response;
		try {
			response = http.send(request);
		} catch (Exception e) {
			PkceResponse pkceResponse = new PkceResponse();
			pkceResponse.isSuccess = false;
			pkceResponse.errorMessage = 'Exception during PKCE request: ' + e.getMessage();
			return pkceResponse;
		}

		PkceResponse pkceResponse = new PkceResponse();
		if (response.getStatusCode() == 200) {
			Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(
				response.getBody()
			);
			pkceResponse.isSuccess = true;
			pkceResponse.codeVerifier = (String) responseMap.get('code_verifier');
			pkceResponse.codeChallenge = (String) responseMap.get('code_challenge');
			pkceResponse.codeChallengeMethod = (String) responseMap.get('code_challenge_method');
		} else {
			pkceResponse.isSuccess = false;
			pkceResponse.errorMessage = 'Failed to generate PKCE data: ' + response.getStatus();
		}
		return pkceResponse;
	}

	/**
	 * Generate authorization URL with PKCE support
	 * TODO: Complete this method implementation
	 * @param usePkce Whether to include PKCE parameters
	 * @param codeChallenge Code challenge from PKCE generation
	 * @param codeChallengeMethod Code challenge method from PKCE generation
	 * @return Full authorization URL with PKCE parameters if requested
	 */
	@AuraEnabled
	public static String generateAuthorizationUrlWithPkce(
		Boolean usePkce,
		String codeChallenge,
		String codeChallengeMethod
	) {
		// TODO: Build base authorization URL like generateAuthorizationUrl
		// TODO: Add PKCE parameters if usePkce is true:
		// - code_challenge (URL encoded)
		// - code_challenge_method (URL encoded)
		String baseUrl = DEFAULT_LOGIN_URL + AUTHORIZE_ENDPOINT;
		String urlBuilder = baseUrl + '?';
		urlBuilder += 'client_id=' + EncodingUtil.urlEncode(DEFAULT_CLIENT_ID, 'UTF-8');
		urlBuilder += '&redirect_uri=' + EncodingUtil.urlEncode(DEFAULT_REDIRECT_URL, 'UTF-8');
		urlBuilder += '&response_type=code';
		if (usePkce) {
			urlBuilder += '&code_challenge=' + EncodingUtil.urlEncode(codeChallenge, 'UTF-8');
			urlBuilder +=
				'&code_challenge_method=' + EncodingUtil.urlEncode(codeChallengeMethod, 'UTF-8');
		}

		// STUB: Return placeholder URL for now
		return urlBuilder;
	}

	/**
	 * Exchange authorization code for access token (grant_type=authorization_code)
	 * TODO: Complete this method implementation
	 * @param code Authorization code received from the redirect
	 * @return Authentication response with token details or error
	 */
	@AuraEnabled
	public static AuthResponse exchangeCodeForToken(String code) {
		// TODO: Prepare parameters map with:
		// - grant_type: 'authorization_code'
		// - code: code
		// - client_id: DEFAULT_CLIENT_ID
		// - client_secret: DEFAULT_CLIENT_SECRET
		// - redirect_uri: DEFAULT_REDIRECT_URL
		Map<String, String> params = new Map<String, String>{
			'grant_type' => 'authorization_code',
			'code' => code,
			'client_id' => DEFAULT_CLIENT_ID,
			'client_secret' => DEFAULT_CLIENT_SECRET,
			'redirect_uri' => DEFAULT_REDIRECT_URL
		};

		// TODO: Call makeTokenRequest with params and token URL
		String tokenUrl = DEFAULT_LOGIN_URL + TOKEN_ENDPOINT;
		AuthResponse authResponse = SFAuthenticationManager.makeTokenRequest(params, tokenUrl);

		if (!authResponse.isSuccess) {
			System.debug('Error exchanging code for token: ' + authResponse.errorMessage);
		}
		return authResponse;
	}

	/**
	 * Exchange authorization code for access token with PKCE support
	 * TODO: Complete this method implementation
	 * @param code Authorization code received from the redirect
	 * @param codeVerifier Code verifier for PKCE
	 * @return Authentication response with token details or error
	 */
	@AuraEnabled
	public static AuthResponse exchangeCodeForTokenWithPkce(String code, String codeVerifier) {
		// TODO: Prepare parameters map like exchangeCodeForToken
		// TODO: Add code_verifier parameter if provided
		// TODO: Call makeTokenRequest with params and token URL
		Map<String, String> params = new Map<String, String>{
			'grant_type' => 'authorization_code',
			'code' => code,
			'client_id' => DEFAULT_CLIENT_ID,
			'client_secret' => DEFAULT_CLIENT_SECRET,
			'redirect_uri' => DEFAULT_REDIRECT_URL
		};
		if (!String.isBlank(codeVerifier)) {
			params.put('code_verifier', codeVerifier);
		}
		String tokenUrl = DEFAULT_LOGIN_URL + TOKEN_ENDPOINT;
		AuthResponse authResponse = SFAuthenticationManager.makeTokenRequest(params, tokenUrl);
		if (!authResponse.isSuccess) {
			System.debug('Error exchanging code for token with PKCE: ' + authResponse.errorMessage);
		}
		return authResponse;
	}

	/**
	 * Refresh an existing access token using a refresh token
	 * Extra Credit: Implement this method
	 * TODO: Complete this method implementation
	 * @param refreshToken The refresh token from a previous authentication
	 * @return Authentication response with new token details or error
	 */
	public static AuthResponse refreshToken(String refreshToken) {
		// TODO: Prepare parameters map with:
		// - grant_type: 'refresh_token'
		// - refresh_token: refreshToken
		// - client_id: DEFAULT_CLIENT_ID
		// - client_secret: DEFAULT_CLIENT_SECRET
		Map<String, String> params = new Map<String, String>{
			'grant_type' => 'refresh_token',
			'refresh_token' => refreshToken,
			'client_id' => DEFAULT_CLIENT_ID,
			'client_secret' => DEFAULT_CLIENT_SECRET
		};
		String tokenUrl = DEFAULT_LOGIN_URL + TOKEN_ENDPOINT;

		// TODO: Call makeTokenRequest with params and token URL
		AuthResponse authResponse = SFAuthenticationManager.makeTokenRequest(params, tokenUrl);
		return authResponse;
	}

	/**
	 * Class to encapsulate authentication response
	 */
	public class AuthResponse {
		@AuraEnabled
		public Boolean isSuccess;
		@AuraEnabled
		public String accessToken;
		@AuraEnabled
		public String refreshToken;
		@AuraEnabled
		public String instanceUrl;
		@AuraEnabled
		public String tokenType;
		@AuraEnabled
		public Integer expiresIn;
		@AuraEnabled
		public String errorMessage;
		@AuraEnabled
		public String errorDetails;
	}

	/**
	 * Class to encapsulate PKCE response
	 */
	public class PkceResponse {
		@AuraEnabled
		public Boolean isSuccess;
		@AuraEnabled
		public String codeVerifier;
		@AuraEnabled
		public String codeChallenge;
		@AuraEnabled
		public String codeChallengeMethod;
		@AuraEnabled
		public String errorMessage;
		@AuraEnabled
		public String errorDetails;
	}
}
