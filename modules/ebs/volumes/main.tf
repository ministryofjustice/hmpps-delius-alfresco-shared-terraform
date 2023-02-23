data "aws_subnet" "selected" {
  id = var.availability_zone
}

data "aws_ssm_parameter" "snapshot" {
  name = "/alfresco/solr/ebs/snapshot_id"
}

resource "aws_ebs_volume" "data" {
  count             = var.create
  availability_zone = data.aws_subnet.selected.availability_zone
  encrypted         = true
  snapshot_id       = data.aws_ssm_parameter.snapshot.value != "null" ? data.aws_ssm_parameter.snapshot.value : ""
  type              = var.ebs_data_type
  size              = var.ebs_data_size
  iops              = var.ebs_data_iops
  kms_key_id        = var.kms_key_id
  tags = merge(
    var.tags,
    {
      "Name"               = var.prefix
      "CreateSnapshotSolr" = 1
    },
  )
}
