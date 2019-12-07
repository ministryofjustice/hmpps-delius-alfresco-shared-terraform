data "template_file" "ami" {
  template = "${file("scripts/data.conf")}"

  vars {
    image_id = "${local.image_id}"
  }
}
