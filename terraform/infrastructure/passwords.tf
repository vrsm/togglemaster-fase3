resource "random_password" "auth_db" {
  length  = 24
  special = true
}

resource "random_password" "flag_db" {
  length  = 24
  special = true
}

resource "random_password" "targeting_db" {
  length  = 24
  special = true
}
