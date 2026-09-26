locals {
  # Record source for the zone apex, as the Infomaniak API writes it.
  apex = "."

  # Subdomains aliased to the apex.
  aliases = toset(["www", "git"])
}

# --- Point the domain and its subdomains at the server ----------------------

resource "infomaniak_record" "a" {
  count = var.ipv4 == null ? 0 : 1

  zone_fqdn = var.domain
  type      = "A"
  source    = local.apex
  target    = var.ipv4
  ttl       = var.ttl
}

resource "infomaniak_record" "aaaa" {
  count = var.ipv6 == null ? 0 : 1

  zone_fqdn = var.domain
  type      = "AAAA"
  source    = local.apex
  target    = var.ipv6
  ttl       = var.ttl
}

# Lookups of any type (A, AAAA, MX, TXT, CAA) follow the alias to the
# apex, so the apex records below cover them too.
resource "infomaniak_record" "alias" {
  for_each = local.aliases

  zone_fqdn = var.domain
  type      = "CNAME"
  source    = each.value
  target    = "${var.domain}."
  ttl       = var.ttl
}

# --- Restrict certificate issuance -------------------------------------------

# CAA (RFC 8659): only Let's Encrypt may issue certificates for the
# domain and its subdomains, wildcards included.
resource "infomaniak_record" "caa" {
  zone_fqdn = var.domain
  type      = "CAA"
  source    = local.apex
  target    = "0 issue \"letsencrypt.org\""
  ttl       = var.ttl
}

# --- Declare that the domain neither sends nor receives email ---------------

# Null MX (RFC 7505): the domain accepts no mail. Without it, senders
# would fall back to delivering to the A/AAAA records (RFC 5321).
resource "infomaniak_record" "null_mx" {
  zone_fqdn = var.domain
  type      = "MX"
  source    = local.apex
  target    = "0 ."
  ttl       = var.ttl
}

# SPF: no server is authorised to send mail for the domain.
resource "infomaniak_record" "spf" {
  zone_fqdn = var.domain
  type      = "TXT"
  source    = local.apex
  target    = "v=spf1 -all"
  ttl       = var.ttl
}

# DMARC: reject all mail claiming to come from the domain or any subdomain.
resource "infomaniak_record" "dmarc" {
  zone_fqdn = var.domain
  type      = "TXT"
  source    = "_dmarc"
  target    = "v=DMARC1; p=reject; sp=reject; adkim=s; aspf=s"
  ttl       = var.ttl
}
