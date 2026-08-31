output "name_servers" {
  description = "Nameservers handling the zone"
  value       = aws_route53_zone.main.name_servers
}
