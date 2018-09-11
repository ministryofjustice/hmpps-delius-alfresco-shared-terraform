terragrunt = {
  include {
    path = "${find_in_parent_folders()}"
  }

  dependencies {
    paths = ["../common"]
  }
}

alb_backend_port = "443"

alb_http_port = "80"

alb_https_port = "443"

# Alfresco ports 21 137 138 139 445 7070 8009 8080
alb_backend_port = "8080"

alfresco_ftp_port = "21"

alfresco_smb_port_start = "137"

"alfresco_smb_port_end" = "139"

"alfresco_smb_port" = "445"

"alfresco_arcp_port" = "7070"

"alfresco_apache_jserv" = "8009"
