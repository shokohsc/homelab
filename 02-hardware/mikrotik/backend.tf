terraform {
  backend "http" {
    address = "http://localhost:6061/?type=git&repository=https://github.com/shokohsc/tfstate&ref=main&state=02-hardware/mikrotik/state.json"
    lock_address = "http://localhost:6061/?type=git&repository=https://github.com/shokohsc/tfstate&ref=main&state=02-hardware/mikrotik/state.json"
    unlock_address = "http://localhost:6061/?type=git&repository=https://github.com/shokohsc/tfstate&ref=main&state=02-hardware/mikrotik/state.json"
  }
}