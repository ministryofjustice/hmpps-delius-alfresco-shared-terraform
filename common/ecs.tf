############################################
# CREATE ECS CLUSTER
############################################

module "ecs_cluster" {
  source       = "../modules/ecs/ecs_cluster"
  cluster_name = local.short_name

  tags = local.tags
}
