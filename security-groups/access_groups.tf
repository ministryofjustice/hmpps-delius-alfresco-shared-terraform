resource "aws_security_group" "content_clients" {
  name        = format("%s-content-clients", local.common_name)
  description = format("security group for %s-content-traffic", local.common_name)
  vpc_id      = local.vpc_id
  tags = merge(
    local.tags,
    {
      "Name" = format("%s-content-clients", local.common_name)
    },
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "share_clients" {
  name        = format("%s-share-clients", local.common_name)
  description = format("security group for %s-share-clients-traffic", local.common_name)
  vpc_id      = local.vpc_id
  tags = merge(
    local.tags,
    {
      "Name" = format("%s-share-clients", local.common_name)
    },
  )

  lifecycle {
    create_before_destroy = true
  }
}

output "alf_access_groups" {
  value = {
    content = aws_security_group.content_clients.id
    share   = aws_security_group.share_clients.id
  }
}
