#!/usr/bin/env python3

import jwt
import argparse
import base64


# Example: generate_token.py jmeter@agg.com --key $KC_KEY -i 'https://kc18.test1.dcp.bm.dev.aggregion.com/realms/test1' -o 'https://test1.dcp.bm.dev.aggregion.com'

parser = argparse.ArgumentParser(
                    prog = 'generate_kc_access',
                    description = 'Generate JWT token to access front-end and GraphQL API')

parser.add_argument('-k', '--key')
parser.add_argument('-i', '--issuer')
parser.add_argument('-o', '--origin')
parser.add_argument('-r', '--realm')
parser.add_argument('login')

args = parser.parse_args()

key = f"-----BEGIN RSA PRIVATE KEY-----\n{args.key}\n-----END RSA PRIVATE KEY-----"


encoded_jwt = jwt.encode({
  "exp": 1984828903,
  "iat": 1669209703,
  "auth_time": 1669209703,
  "jti": "8e18e895-68ed-4c5d-987a-c9b1df56bbb4",
  "iss": args.issuer,
  "aud": [
    "broker",
    "account"
  ],
  "sub": "2c3339ea-eb5a-4d1b-86da-9b18b87baae6",
  "typ": "Bearer",
  "azp": "dcp",
  "session_state": "b8ebda80-1bfc-43ef-a4bf-6e860cd885d8",
  "acr": "0",
  "allowed-origins": [
    args.origin
  ],
  "realm_access": {
    "roles": [
      "offline_access",
      "uma_authorization",
      "default-roles-test1"
    ]
  },
  "resource_access": {
    "broker": {
      "roles": [
        "read-token"
      ]
    },
    "account": {
      "roles": [
        "manage-account",
        "manage-account-links",
        "view-profile"
      ]
    }
  },
  "scope": "openid profile email",
  "sid": "b8ebda80-1bfc-43ef-a4bf-6e860cd885d8",
  "email_verified": True,
  "name": "Apache Jmeter",
  "preferred_username": args.login,
  "given_name": "Apache",
  "family_name": "Jmeter",
  "email": args.login
}, key, algorithm="RS256")

print(str(encoded_jwt))
