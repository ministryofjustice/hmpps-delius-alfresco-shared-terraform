resource "aws_security_group" "content" {
  name        = format("%s-content", local.common_name)
  description = format("security group for %s-content-traffic", local.common_name)
  vpc_id      = local.vpc_id
  tags = merge(
    local.tags,
    {
      "Name" = format("%s-content", local.common_name)
    },
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "share" {
  name        = format("%s-share", local.common_name)
  description = format("security group for %s-share-traffic", local.common_name)
  vpc_id      = local.vpc_id
  tags = merge(
    local.tags,
    {
      "Name" = format("%s-share", local.common_name)
    },
  )

  lifecycle {
    create_before_destroy = true
  }
}

output "alf_access_groups" {
  value = {
    content = aws_security_group.content.id
    share   = aws_security_group.share.id
  }
}
