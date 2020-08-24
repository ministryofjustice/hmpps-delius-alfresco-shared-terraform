resource "aws_resourcegroups_group" "alf" {
  name = local.common_name
  resource_query {
    query = file("./files/resource_group.json")
  }
}

