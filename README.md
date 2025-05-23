# Cloud Code Academy - Integration Developer Program

## Assignment 7: Salesforce Authentication & OAuth Integration

This assignment focuses on implementing secure authentication mechanisms for Salesforce-to-Salesforce integrations using OAuth 2.0 flows, including Web Server Flow and JWT Bearer Token Flow for server-to-server authentication.

## 🎯 Learning Objectives

By the end of this lesson, you will be able to:

- Configure Connected Apps for OAuth authentication flows
- Implement Web Server Flow for user-based authentication
- Set up JWT Bearer Token Flow for server-to-server authentication
- Create and manage self-signed certificates for JWT authentication
- Configure Experience Cloud sites with OAuth components
- Handle secure token management and refresh mechanisms
- Implement proper security configurations for API-only users

## 📋 Assignment Overview

In this assignment, you will be implementing comprehensive authentication mechanisms for Salesforce integrations. You'll work with both user-interactive OAuth flows and server-to-server JWT authentication, ensuring secure and reliable communication between Salesforce orgs.

Your implementation must:

1. Set up Connected Apps with proper OAuth scopes and security settings
2. Implement Web Server Flow authentication in Experience Cloud
3. Configure JWT Bearer Token Flow with certificate-based authentication
4. Create secure API-only user profiles for integration purposes
5. Handle token refresh and error scenarios appropriately

## 🔨 Prerequisites

1. Two Salesforce Developer orgs (source and destination)
2. Experience Cloud license enabled in destination org
3. OpenSSL installed for certificate generation
4. Node.js environment for JWT testing
5. Understanding of OAuth 2.0 authentication flows
6. Basic knowledge of public key cryptography

## ✍️ Assignment Tasks

Your tasks for this assignment include:

### Phase 1: Connected App Configuration

1. Create a Connected App in the destination org with proper OAuth settings
2. Configure callback URLs and OAuth scopes
3. Set up Remote Site Settings for cross-org communication
4. Deploy necessary metadata to both source and destination orgs

### Phase 2: Integration User Setup

1. Create an Integration User with "Salesforce API Only System" profile
2. Configure OAuth scopes for API access, identity, and refresh tokens
3. Assign necessary permissions for cross-org data access

### Phase 3: SFAuthenticationManager Implementation

1. **Complete the `SFAuthenticationManager.cls` implementation**:
    - Implement `makeTokenRequest()` method for HTTP OAuth requests
    - Complete `authenticateWithPassword()` for username/password flow
    - Implement `authenticateWithClientCredentials()` for client credentials flow
    - Complete `authenticateWithJWT()` using self-signed certificates in Salesforce
    - Implement `generateAuthorizationUrl()` for Web Server Flow
    - Complete `generatePkceData()` and `generateAuthorizationUrlWithPkce()` for PKCE support
    - Implement `exchangeCodeForToken()` and `exchangeCodeForTokenWithPkce()` for authorization code exchange

### Phase 4: Web Server Flow Implementation

1. Enable Experience Cloud (LWR) in destination org
2. Deploy OAuth component to the Experience Cloud home page (LWC components are already provided)
3. Create and configure the `/callback` page for OAuth redirects
4. Configure public access settings for guest users
5. Grant access to authentication Apex classes

### Phase 5: JWT Bearer Token Flow

1. Generate self-signed certificates using OpenSSL (Mac/Linux instructions provided)
2. Upload certificate to destination org in Certificate and Key Management
3. Reference the certificate in your `authenticateWithJWT()` implementation
4. Test JWT authentication flow using Salesforce Apex classes

## 🔗 Connected App Configuration

Your Connected App must be configured with the following settings:

### OAuth Settings

- **Callback URL**: `https://{instance}.my.site.com/callback`
- **OAuth Scopes**:
    - Access the identity URL service (id)
    - Access and manage your data (api)
    - Perform requests on your behalf at any time (refresh_token, offline_access)

### Security Settings

- Enable OAuth introspection
- Configure IP restrictions if required
- Set session timeout policies

## 🌐 Experience Cloud Configuration

For the Web Server Flow implementation:

1. **Enable Experience Cloud LWR**

    - Navigate to Setup → Experience Management → Sites
    - Create new Experience Cloud site with Lightning Web Runtime (LWR)

2. **Deploy OAuth Component**

    - Add the provided OAuth LWC component to the home page
    - Configure component properties for your Connected App

3. **Create Callback Page**

    - Create `/callback` page in Experience Builder
    - Add callback handling component to process OAuth responses

4. **Public Access Configuration**
    - Enable "Public Access Enabled" in General Settings
    - Grant Guest User access to `SFAuthenticationManager` and `SFExternalCalloutWithToken` classes

## 🔐 JWT Bearer Token Flow Implementation

### Certificate Generation (Mac/Linux)

Use the following OpenSSL commands to generate your certificates:

```bash
# Generate private key
openssl genrsa -out jwt_private.key 2048

# Generate certificate signing request
openssl req -new -key jwt_private.key -out jwt.csr

# Generate self-signed certificate (valid for 1 year)
openssl x509 -req -days 365 -in jwt.csr -signkey jwt_private.key -out jwt.crt
```

**Note**: For Windows users, you can use Git Bash, WSL, or install OpenSSL for Windows to run these commands.

### JWT Token Implementation in Salesforce Apex

Complete the `authenticateWithJWT()` method in `SFAuthenticationManager.cls` using the following pattern:

```apex
Auth.JWT jwt = new Auth.JWT();
jwt.setSub(username);
jwt.setAud('https://login.salesforce.com');
jwt.setIss(DEFAULT_CLIENT_ID);

// Create the object that signs the JWT bearer token
// 'jwtsource' should be the name of your certificate in Salesforce
Auth.JWS jws = new Auth.JWS(jwt, 'jwtsource');
String token = jws.getCompactSerialization();
String tokenEndpoint = DEFAULT_LOGIN_URL + '/services/oauth2/token';

Auth.JWTBearerTokenExchange bearer = new Auth.JWTBearerTokenExchange(tokenEndpoint, jws);

// Get the access token
String accessToken = bearer.getAccessToken();
```

### Certificate Configuration in Salesforce

1. Upload the generated `.crt` file to your destination org
2. Navigate to Setup → Certificate and Key Management
3. Create a Certificate record and give it a memorable name (e.g., 'jwtsource')
4. Reference this certificate name in your JWT implementation

## 🧪 Testing Your Implementation

### Manual Apex Testing (No Automated Test Classes)

**Important**: This assignment uses manual testing with System.debug statements rather than automated test classes. You'll need to:

1. **Update Configuration Values** in `SFAuthenticationManager.cls`:

    - Replace `DEFAULT_CLIENT_ID` with your Connected App's Consumer Key
    - Replace `DEFAULT_CLIENT_SECRET` with your Connected App's Consumer Secret
    - Replace `DEFAULT_LOGIN_URL` with your org's login URL
    - Replace `DEFAULT_REDIRECT_URL` with your Experience Cloud callback URL

2. **Test Authentication Flows** using the provided test scripts in `/scripts/apex/`:

    - **Quick Test**: Use `hello.apex` for basic authentication testing
    - **Comprehensive Test**: Use `comprehensive-test.apex` for detailed testing with full error handling
    - **Password Flow**: Execute `SFAuthenticationManager.authenticateWithPassword()` in Developer Console
    - **Client Credentials Flow**: Test `SFAuthenticationManager.authenticateWithClientCredentials()`
    - **JWT Flow**: Execute `SFAuthenticationManager.authenticateWithJWT()` with your integration user
    - **Web Server Flow**: Navigate to your Experience Cloud site and test OAuth login
    - **Token Refresh**: Verify that expired tokens are properly refreshed using `refreshToken()`
    - **Integration Testing**: Use `SFExternalCalloutWithToken.cls` methods with your acquired tokens

3. **Use System.debug Statements** to verify:
    - Authentication responses contain valid access tokens
    - Instance URLs are correctly returned
    - External callouts succeed with acquired tokens
    - Error handling works for invalid credentials
    - Token refresh functionality operates correctly

## 🔗 JWT Demo Testing (Extra Credit)

Use the provided Node.js demo to test JWT token generation with local certificates:

1. Navigate to the `node-demo` folder
2. Run `npm install` to install dependencies
3. Place your private key file (`jwt_private.key`) in the `certificates` folder
4. Configure your Consumer Key in `JWT_DEMO.js`
5. Execute `node JWT_DEMO.js` to test local JWT token generation
6. Compare the locally generated tokens with your Salesforce Apex implementation

**Extra Credit Requirements**:

- Successfully generate JWT tokens using Node.js with your local private key
- Demonstrate token validation against your Salesforce org
- Document any differences between local and Salesforce JWT implementations
- Complete `refreshToken()` method for token refresh flow and test it

## ⚙️ Environment Configuration

### env.json Setup

1. Create `env.json` from the provided `env.json.example` template
2. Use the Salesforce CLI to populate org details:
    ```bash
    sf org display env --json > env.json
    ```
3. Add your Consumer Key and private key information
4. Ensure this file is included in `.gitignore` for security

### Required Environment Variables

- `CONSUMER_KEY`: Connected App Consumer Key
- `PRIVATE_KEY_PATH`: Path to your JWT private key
- `USERNAME`: Integration user username
- `LOGIN_URL`: Salesforce login URL (production or sandbox)

## 🎯 Success Criteria

Your implementation should:

- Successfully authenticate using both Web Server Flow and JWT Bearer Token Flow
- Handle token refresh automatically when tokens expire
- Implement proper error handling for authentication failures
- Maintain secure storage of sensitive authentication data
- Pass all authentication test scenarios
- Follow security best practices for OAuth implementation

## 💡 Tips

- Store sensitive data like private keys and consumer secrets securely
- Use Named Credentials when possible for credential management
- Implement retry logic for network-related authentication failures
- Test with both sandbox and production authentication endpoints
- Monitor API limits when implementing token refresh mechanisms
- Use System.debug statements for troubleshooting authentication flows

## 📚 Resources

- [OAuth Authorization Flows](https://help.salesforce.com/s/articleView?id=sf.remoteaccess_oauth_flows.htm)
- [JWT Bearer Token Flow](https://help.salesforce.com/s/articleView?id=sf.remoteaccess_oauth_jwt_flow.htm)
- [Connected App Configuration](https://help.salesforce.com/s/articleView?id=sf.connected_app_create.htm)
- [Experience Cloud Setup](https://help.salesforce.com/s/articleView?id=sf.networks_getting_started.htm)
- [Apex Auth Class Reference](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_namespace_Auth.htm)
- [Certificate and Key Management](https://help.salesforce.com/s/articleView?id=sf.security_keys_about.htm)

## 🏆 Extra Credit - Optional Challenges

Once you've completed the basic implementation, try these challenges:

1. **Node.js JWT Implementation** - Implement JWT token generation using Node.js with your local private key certificates and demonstrate successful authentication against your Salesforce org
2. Implement PKCE (Proof Key for Code Exchange) for enhanced security
3. Create a refresh token rotation mechanism
4. Add support for SAML SSO integration
5. Implement OAuth device flow for IoT scenarios
6. Create a comprehensive logging system for authentication events
7. Build a token management dashboard using Lightning Web Components

## 🛠️ Existing Implementation Files

The following files are already provided and should not require modifications:

- `SFExternalCalloutWithToken.cls` - Handles authenticated callouts (already implemented)
- OAuth LWC components in `/lwc` folder - Pre-built components for Experience Cloud (already implemented)
- Permission sets for integration users

**Files requiring implementation**:

- `SFAuthenticationManager.cls` - Complete all TODO methods for OAuth flows

## ❓ Support

If you need help:

- Review the OAuth 2.0 and JWT documentation
- Check the Salesforce authentication trailhead modules
- Use the provided Node.js demo for JWT testing
- Verify your Connected App configuration
- Reach out to your instructor for guidance

---

Happy coding! 🚀

_This is part of the Cloud Code Academy Integration Developer certification program._

## Copyright

© 2025 Cloud Code. All rights reserved.

This software is provided under the Cloud Code Developer Kickstart Program License (CCDKPL) Version 1.0.
The software is licensed, not sold, and is intended for personal educational purposes only as part of the Cloud Code Developer Kickstart Program.

See the full license terms in LICENSE.md for more details regarding usage restrictions, ownership, warranties, and limitations of liability.
