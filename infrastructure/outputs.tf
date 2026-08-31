output "server_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.web_ip.public_ip
}

output "nameservers" {
  description = "Nameservers for the domain"
  value       = module.dns.name_servers
}
