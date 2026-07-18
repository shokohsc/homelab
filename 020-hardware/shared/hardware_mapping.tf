resource "proxmox_hardware_mapping_dir" "tank" {
  name    = "tank"
  comment = "NFS tank directory mapping"

  map = [
    # {
    #   node = "roadhog"
    #   path = "/mnt/tank"
    # },
    {
      node = "hanzo"
      path = "/mnt/tank"
    },
    {
      node = "genji"
      path = "/mnt/tank"
    },
  ]
}
