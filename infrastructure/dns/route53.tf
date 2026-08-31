resource "aws_route53_zone" "main" {
  name = var.domain_name
}

# Main A record
resource "aws_route53_record" "root_a" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 300
  records = [var.server_ip]
}

# WWW A record
resource "aws_route53_record" "www_a" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [var.server_ip]
}

# Staging A record
resource "aws_route53_record" "staging_a" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "staging.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [var.server_ip]
}

# DELIBERATE SECURITY WEAKNESSES: EMAIL SECURITY

# Weak SPF Record (Neutral)
resource "aws_route53_record" "txt_root" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "TXT"
  ttl     = 300
  records = ["v=spf1 ?all"]
}

# Weak DMARC Record (p=none)
resource "aws_route53_record" "dmarc" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "_dmarc.${var.domain_name}"
  type    = "TXT"
  ttl     = 300
  records = ["v=DMARC1; p=none;"]
}

# Intentionally omitting DKIM records

# Intentionally omitting CAA records

# Note: DNSSEC must be manually enabled in Route53, so by omitting a configuration
# here it defaults to disabled, matching the deliberately weak requirement.
