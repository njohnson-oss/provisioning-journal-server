# provisioning-journal-server

[![CI](https://github.com/njohnson-oss/provisioning-journal-server/actions/workflows/ci.yml/badge.svg)](https://github.com/njohnson-oss/provisioning-journal-server/actions/workflows/ci.yml)

OpenTofu configuration for the DNS records of the journal server's
domain, hosted on Infomaniak. It points the domain and its `www` / `git`
subdomains at a server and publishes records declaring that the domain
handles no email.

Only DNS is managed here because the provider does not offer VPS
configuration. The server can be hosted anywhere; its public addresses
are passed in as variables.

## Records managed

| Name                   | Type  | Value                                             | Purpose                              |
| ---------------------- | ----- | ------------------------------------------------- | ------------------------------------ |
| `example.com`          | A     | `ipv4`                                            | Point the domain at the server (only if `ipv4` is set) |
| `example.com`          | AAAA  | `ipv6`                                            | Point the domain at the server (only if `ipv6` is set) |
| `www.example.com`      | CNAME | `example.com.`                                    | Alias to the apex                    |
| `git.example.com`      | CNAME | `example.com.`                                    | Alias to the apex                    |
| `example.com`          | CAA   | `0 issue "letsencrypt.org"`                       | Only Let's Encrypt may issue certificates |
| `example.com`          | MX    | `0 .`                                             | Null MX: accept no mail (RFC 7505)   |
| `example.com`          | TXT   | `v=spf1 -all`                                     | SPF: no host may send mail           |
| `_dmarc.example.com`   | TXT   | `v=DMARC1; p=reject; sp=reject; adkim=s; aspf=s`  | Reject mail spoofing the domain      |

The DNS zone itself is not managed: it must already exist at Infomaniak
(it does if the domain is registered there, or once you add the domain's
DNS in the Manager). This keeps `tofu destroy` from deleting the zone.

## Prerequisites

- [OpenTofu](https://opentofu.org/docs/intro/install/) 1.9 or newer.
- The domain's DNS zone hosted at Infomaniak.
- The server's public IPv4 address, IPv6 address, or both.
- An Infomaniak API token with the `dns:read` and `dns:write` scopes,
  created at <https://manager.infomaniak.com/v3/ng/accounts/token/list>.

## Usage

1. Fill in the variables:

   ```sh
   cp terraform.tfvars.example terraform.tfvars
   $EDITOR terraform.tfvars
   ```

   | Variable   | Required | Description                                          |
   | ---------- | -------- | ---------------------------------------------------- |
   | `domain`   | yes      | Lowercase domain without trailing dot, e.g. `example.com` |
   | `ipv4`     | see below | Server's public IPv4 address; omit or `null` for no A record |
   | `ipv6`     | see below | Server's public IPv6 address; omit or `null` for no AAAA record |
   | `ttl`      | no       | TTL in seconds for every record (default `3600`)     |

   At least one of `ipv4` and `ipv6` must be set; `tofu plan` fails
   if both are missing.

2. Provide the API token through the environment, never in a file:

   ```sh
   export INFOMANIAK_TOKEN=...
   ```

3. Remove conflicting records. A new Infomaniak zone often ships with
   default records (MX, A, `www`, SPF/autodiscover for Infomaniak Mail).
   These are not managed here and will not be replaced. Delete any at the
   names above in the Manager's DNS zone view, or adopt them (see
   [Adopting existing records](#adopting-existing-records)).
   In particular, `www` / `git` must have no other records, or the
   CNAME cannot be created.

4. Apply:

   ```sh
   tofu init
   tofu plan
   tofu apply
   ```

## Adopting existing records

To bring a record that already exists into management instead of
deleting it, find its ID with the API:

```sh
curl -s -H "Authorization: Bearer $INFOMANIAK_TOKEN" \
  https://api.infomaniak.com/2/zones/example.com/records
```

then import it into the matching resource:

```sh
tofu import 'infomaniak_record.alias["www"]' example.com,123456
```

## State

State is kept locally in `terraform.tfstate` (git-ignored). It holds no
secrets, but it is the only record of which DNS records this
configuration owns, so keep it backed up or configure a
[remote backend](https://opentofu.org/docs/language/settings/backends/configuration/)
if more than one machine will run this.
