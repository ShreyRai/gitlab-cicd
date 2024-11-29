output "private_key_pem" {
  value = tls_private_key.cicd-key.private_key_pem
  sensitive = true
}

output "ec2_public_ip" {
  value = aws_instance.cicd-ec2.public_ip
}