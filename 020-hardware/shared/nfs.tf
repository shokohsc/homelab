resource "proxmox_storage_nfs" "proxmox" {
  id     = "nfs-proxmox"
  nodes  = ["roadhog", "hanzo", "genji"]
  server = "10.42.60.50"
  export = "/content"

  content          = ["backup", "import", "iso", "snippets", "vztmpl"]
  create_base_path = true
  create_subdirs   = true
  options= "vers=4.2"
}
