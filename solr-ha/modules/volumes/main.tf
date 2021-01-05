data "aws_subnet" "selected" {
  id = var.availability_zone
}

data "aws_ssm_parameter" "snapshot" {
  name = "/alfresco/solr/ebs/snapshot_ids/${data.aws_subnet.selected.availability_zone}"
}

resource "aws_ebs_volume" "data" {
  availability_zone = data.aws_subnet.selected.availability_zone
  encrypted         = true
  snapshot_id       = data.aws_ssm_parameter.snapshot.value != "null" ? data.aws_ssm_parameter.snapshot.value : ""
  type              = var.ebs_data_type
  size              = var.ebs_data_size
  iops              = var.ebs_data_iops
  tags = merge(
    var.tags,
    {
      "Name"               = "${var.prefix}-${data.aws_subnet.selected.availability_zone}-data"
      "CreateSnapshotSolr" = 1
    },
  )
}

resource "aws_ebs_volume" "temp" {
  availability_zone = data.aws_subnet.selected.availability_zone
  encrypted         = true
  type              = var.ebs_temp_type
  size              = var.ebs_temp_size
  iops              = var.ebs_temp_iops
  tags = merge(
    var.tags,
    {
      "Name"               = "${var.prefix}-${data.aws_subnet.selected.availability_zone}-temp"
      "CreateSnapshotSolr" = 1
    },
  )
}
