provider "cloudflare" {
  # api_token = var.cloudflare_api_token
}

provider "aws" {
  region = "ap-northeast-1"
}

# Example: Manage a DNS record
# resource "cloudflare_record" "home" {
#   zone_id = var.cloudflare_zone_id
#   name    = "home"
#   value   = "192.168.1.1" # Dynamic IP handling needed?
#   type    = "A"
#   proxied = false
# }
