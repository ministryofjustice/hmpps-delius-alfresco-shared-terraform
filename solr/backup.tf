data "template_file" "solr_backup" {
  template = "${file("../policies/backup_assume_role.tpl")}"
  vars     = {}
}
resource "aws_iam_role" "solr_backup" {
  name               = "${local.common_name}-ebs-bkup"
  assume_role_policy = "${data.template_file.solr_backup.rendered}"
}

resource "aws_iam_role_policy_attachment" "solr_backup" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = "${aws_iam_role.solr_backup.name}"
}

resource "aws_backup_vault" "solr_backup" {
  name = "${local.common_name}-ebs-bkup"
  tags = "${merge(local.tags, map("Name", "${local.common_name}-ebs-bkup"))}"
}

resource "aws_backup_plan" "solr_backup" {
  name = "${local.common_name}-ebs-bkup"

  rule {
    rule_name         = "${local.common_name}-ebs-bkup"
    target_vault_name = "${aws_backup_vault.solr_backup.name}"
    schedule          = "${var.alf_solr_config["schedule"]}"

    lifecycle = {
      cold_storage_after = "${var.alf_solr_config["cold_storage_after"]}"
      delete_after       = "${var.alf_solr_config["delete_after"]}"
    }
  }

  tags = "${merge(local.tags, map("Name", "${local.common_name}-ebs-bkup"))}"
}

resource "aws_backup_selection" "solr_backup" {
  iam_role_arn = "${aws_iam_role.solr_backup.arn}"
  name         = "${local.common_name}-ebs-bkup"
  plan_id      = "${aws_backup_plan.solr_backup.id}"

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "${var.alf_solr_config["snap_tag"]}"
    value = "1"
  }
}
