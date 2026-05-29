# terraform {
#   backend "http" {
#     address = "http://localhost:6061/?type=git&repository=https://github.com/shokohsc/tfstate&ref=main&state=02-hardware/tplink/state.json"
#     lock_address = "http://localhost:6061/?type=git&repository=https://github.com/shokohsc/tfstate&ref=main&state=02-hardware/tplink/state.json"
#     unlock_address = "http://localhost:6061/?type=git&repository=https://github.com/shokohsc/tfstate&ref=main&state=02-hardware/tplink/state.json"
#   }
# }

# terraform {
#   backend "pg" {
#     conn_str = "postgres://postgres:opentofu@localhost:5432/opentofu?sslmode=disable"
#   }
# }

terraform {
  backend "local" {
    path = "./tplink.tfstate"
  }
}
