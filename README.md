# DevSecOps: secret generator
> Secure way to generate secret for local development.

## Objective
1. Avoid having predefined password on local testing and staging environment.
2. Generate secret with decent strength.
3. Avoid everyone reinventing it.

## Use Case
This script will assume the secret to be localed on a .env style file, which can be consumed directly by:
1. dotenv
2. docker
3. kubernetes

An example .env.in will looks like this:
```
# This is an example of .env file
REDIS_PASS=GENERATE_SECRET

PG_USER=pguser
PG_PASS=GENERATE_SECRET[pg]
PG_URL=postgresql://pguser:GENERATE_SECRET[pg]@db/app?sslmode=disable
```

## Usage
WIP
