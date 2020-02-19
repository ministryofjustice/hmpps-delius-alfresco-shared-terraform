module "solr" {
  source                   = "../modules/iam"
  common_name              = "${local.common_name}-solr"
  tags                     = "${local.tags}"
  ec2_policy_file          = "ec2_policy.json"
  ec2_internal_policy_file = "${file("../policies/ec2_solr_policy.json")}"
  remote_iam_role          = "${local.remote_iam_role}"
  remote_config_bucket     = "${local.remote_config_bucket}"
  storage_s3bucket         = "${local.alfresco-storage_s3bucket}"
  s3-config-bucket         = "${local.config-bucket}"
  alf_backups_bucket_arn   = "${local.alf_backups_bucket_arn}"
  s3bucket_kms_arn         = "${local.alfresco_kms_arn}"
  asg_ssm_arns_map = {
    db_user                = "${data.aws_ssm_parameter.db_user.arn}"
    db_password            = "${data.aws_ssm_parameter.db_password.arn}"
    remote_broker_username = "${data.aws_ssm_parameter.spg_mq_user.arn}"
    remote_broker_password = "${data.aws_ssm_parameter.spg_mq_password.arn}"
  }
}
