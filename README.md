# DevSecOps: secret generator
> Secure way to generate secret for local development.

## Objective
1. Avoid having predefined password on local testing and staging environment.
2. Generate secret with decent strength.
3. Avoid everyone reinventing it.

## Usage
```
./generate-secret.sh -i .env.example -o .env
```

##### Pull & Run
```
curl -s https://raw.githubusercontent.com/oursky/devsecops-secret/master/generate-secret.sh \
  | bash -s -- \
  -i .env.example -o .env
```

##### Advanced Usage
```
./generate-secret.sh -h

usage: generate-secret.sh [-i infile] [-o outfile] [-k keyword] [-s strength]
  -i infile      Input template file, default to stdin
  -o outfile     Output file, default to stdout
  -k keyword     Keyword for secret, default to GENERATE_SECRET
  -s strength    Secret strength, default 48 bytes before base64, might be less due to removing special characters.
```

## Use Case
This script will assume the secret to be located on a .env style file, which can be consumed directly by:
1. dotenv
2. docker (e.g. `docker run -it --rm --env-file .env my-image`)
3. kubernetes (e.g. `kubectl -n ns create secret generic app-secret --from-env-file=.env`)

An .env.example will looks like this:
```
# This is an example of .env file
REDIS_PASS=GENERATE_SECRET
ANOTHER_SECRET=GENERATE_SECRET

PG_USER=pguser
PG_PASS=GENERATE_SECRET[pg]
PG_URL=postgresql://pguser:GENERATE_SECRET[pg]@db/app?sslmode=disable

SECRET=GENERATE_SECRET[test]
SAME_SECRET=GENERATE_SECRET[test];abc=def
```
Expected output:
```
# This is an example of .env file
REDIS_PASS=xqqKeh3VDv9c9vsdN3EIZsPAHZPsqcC7jBD98rQlawIkrSuprBzTdej5QITXIq
ANOTHER_SECRET=7qNcrldepDpBRcUKDCkX8GRXhWiv9Kz8JhLGA9URBTdVlsOwyNZjcoQk7lm82

PG_USER=pguser
PG_PASS=mBKxUNJ3HK3JakIoG1nPWl6qmHxoEHAWEzs3b5ulx4fdGJ8h803FrnNgRqcCvF
PG_URL=postgresql://pguser:mBKxUNJ3HK3JakIoG1nPWl6qmHxoEHAWEzs3b5ulx4fdGJ8h803FrnNgRqcCvF@db/app?sslmode=disable

SECRET=JZpMvY8DcuhrCPhGaMM4gTcp7gUv5mk6sm9n8XBQKYEpSvqhnbbaG2TdWE9MZWnS
SAME_SECRET=JZpMvY8DcuhrCPhGaMM4gTcp7gUv5mk6sm9n8XBQKYEpSvqhnbbaG2TdWE9MZWnS;abc=def
```
> If .env file already exists, the script shall keep all values modified by user and only replaces `GENERATE_SECRET`.
