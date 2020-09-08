output "elk_service" {
  value = {
    es_sg_id = aws_security_group.es.id
  }
}
