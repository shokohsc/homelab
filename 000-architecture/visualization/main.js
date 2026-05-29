/* ----------------------------------------------------
 *  1. Fetch the YAML data from an external file
 * ---------------------------------------------------- */
fetch("devices.yaml", {
    headers: { 'Content-Type': 'application/x-yaml' },
    mode: 'no-cors'
  })
  .then((r) => r.text())
  .then((txt) => {
    const data = jsyaml.load(txt);
    const devices = data.devices; // array

    /* ----------------------------------------------------
     *  2. Convert to vis‑network format
     * ---------------------------------------------------- */
    const nodes = [];
    const edges = [];
    const nameToId = {};

    devices.forEach((dev, idx) => {
      const id = idx; // numeric id
      nameToId[dev.name] = id;

      // Grab the first IPv4 that isn’t empty
      const ip = dev.network?.interfaces?.[0]?.ipv4[0] || "-";
      const mac = dev.network?.interfaces?.[0]?.mac[0] || "-";

      const cpuText = dev.cpu?.cores ? `${dev.cpu.cores} cores` : "—";
      const ramText = dev.ram || "—";

      nodes.push({
        id,
        label: `${dev.name}\n${dev.role}\nIPv4: ${ip}\nMAC: ${mac}`,
        title: `OS: ${dev.os || "—"}\nCPU: ${cpuText} • RAM: ${ramText}\n${dev.description}`,
        shape: "box",
        // color: {
        //   background: getColorForRole(dev.role),
        //   border: "#333",
        // },
        group: dev.group
      });
    });

    // Edges: linkTo means “this device connects to those devices”
    devices.forEach((dev, idx) => {
      const source = idx;
      (dev.linkedTo ?? []).forEach((targetName) => {
        const target = nameToId[targetName];
        if (target !== undefined) {
          edges.push({
            from: source,
            to: target,
            arrows: "to",
            title: `${dev.name} → ${targetName}`,
            color: {
              color: getColorForRole(dev.role),
            },
          });
        }
      });
    });

    /* ----------------------------------------------------
     *  3. Render the network
     * ---------------------------------------------------- */
    const container = document.getElementById("network");
    const dataVis = {
      nodes: new vis.DataSet(nodes),
      edges: new vis.DataSet(edges),
    };
    const options = {
      layout: { hierarchical: false },
      physics: {
        solver: "forceAtlas2Based",
        forceAtlas2Based: {
          gravitationalConstant: -200,
          centralGravity: 0.01,
          springLength: 100,
          springConstant: 0.08,
          damping: 0.6,
          avoidOverlap: 0,
        },
      },
      nodes: { font: { multi: "html" } },
      edges: { arrows: { to: { enabled: true } } },
      interaction: { hover: true },
    };
    new vis.Network(container, dataVis, options);
  })
  .catch((error) => {
    console.error("Error loading YAML file:", error);
    // Fallback to show an error message if the file can't be loaded
    document.getElementById("network").innerHTML =
      '<div style="padding: 20px; text-align: center; color: red;">' +
      "Error loading network data. Please check if devices.yaml exists in the same directory." +
      "</div>";
  });

/* ------------------------------------------------------------
 * Helper: map role → color
 * ------------------------------------------------------------ */
function getColorForRole(role) {
  const map = {
    "internet": "#a599ff",
    "gateway": "#ff99e7",
    "router": "#ffcc99",
    "bridge": "#99ff99",
    "control-plane": "#99ccff",
    "worker": "#ff9999",
    "hypervisor": "#cc99ff",
    "management": "#ffeb99",
    "guest": "#e6e6e6",
    "iot": "#ffffcc",
  };
  return map[role] || "#dddddd";
}

