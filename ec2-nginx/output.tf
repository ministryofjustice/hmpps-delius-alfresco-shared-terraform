# # LB
output "ecs_nginx_lb_id" {
  value = "${module.ecs-nginx.lb_id}"
}

output "ecs_nginx_lb_arn" {
  value = "${module.ecs-nginx.lb_arn}"
}

output "ecs_nginx_lb_dns_name" {
  value = "${module.ecs-nginx.lb_dns_name}"
}

output "ecs_nginx_lb_dns_alias" {
  value = "${module.ecs-nginx.lb_dns_alias}"
}

output "ecs_nginx_lb_zone_id" {
  value = "${module.ecs-nginx.lb_zone_id}"
}

# LOG GROUPS
output "ecs_nginx_loggroup_arn" {
  value = "${module.ecs-nginx.loggroup_arn}"
}

output "ecs_nginx_loggroup_name" {
  value = "${module.ecs-nginx.loggroup_name}"
}

# Launch config
output "ecs_nginx_launch_id" {
  value = "${module.ecs-nginx.launch_id}"
}

output "ecs_nginx_launch_name" {
  value = "${module.ecs-nginx.launch_name}"
}

# ASG
output "autoscale_id" {
  value = "${module.ecs-nginx.autoscale_id}"
}

output "ecs_nginx_autoscale_arn" {
  value = "${module.ecs-nginx.autoscale_arn}"
}

output "ecs_nginx_autoscale_name" {
  value = "${module.ecs-nginx.autoscale_name}"
}
