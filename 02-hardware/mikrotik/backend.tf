terraform {
  backend "local" {
    path = var.terraform_state_path
  }
}
