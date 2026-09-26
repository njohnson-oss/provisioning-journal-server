variable "domain" {
  description = "Domain whose Infomaniak-hosted DNS zone is managed, e.g. \"example.com\"."
  type        = string

  validation {
    condition     = can(regex("^([a-z0-9]([a-z0-9-]*[a-z0-9])?\\.)+[a-z]{2,}$", var.domain))
    error_message = "domain must be a lowercase FQDN without trailing dot, e.g. \"example.com\"."
  }
}

variable "ipv4" {
  description = "Public IPv4 address of the server, or null for no A record. At least one of ipv4 and ipv6 must be set."
  type        = string
  default     = null

  validation {
    # The regex rejects IPv6-shaped input (colons, hex letters) that cidrhost would otherwise accept as a /32.
    condition     = var.ipv4 == null || can(regex("^[0-9.]+$", var.ipv4)) && can(cidrhost("${var.ipv4}/32", 0))
    error_message = "ipv4 must be a valid IPv4 address, or null."
  }

  validation {
    condition     = var.ipv4 != null || var.ipv6 != null
    error_message = "At least one of ipv4 and ipv6 must be set."
  }
}

variable "ipv6" {
  description = "Public IPv6 address of the server, or null for no AAAA record. At least one of ipv4 and ipv6 must be set."
  type        = string
  default     = null

  validation {
    condition     = var.ipv6 == null || can(cidrhost("${var.ipv6}/128", 0))
    error_message = "ipv6 must be a valid IPv6 address, or null."
  }
}

variable "ttl" {
  description = "TTL in seconds for all managed records."
  type        = number
  default     = 3600
}
