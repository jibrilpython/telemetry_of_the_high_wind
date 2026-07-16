enum ImplementationClass {
  plugAndFeatherSet('Plug-and-Feather Set'),
  tracingChisel('Tracing Chisel'),
  coreBoringRig('Core Boring Rig'),
  moldingTemplate('Molding Template'),
  levelingArc("Mason's Leveling Arc"),
  profileGauge('Zinc Profile Gauge'),
  other('Other');

  const ImplementationClass(this.label);
  final String label;
}

enum StoneType {
  granite('Granite'),
  limestone('Limestone'),
  marble('Marble'),
  sandstone('Sandstone'),
  slate('Slate'),
  basalt('Basalt'),
  unknown('Unclassified Stone');

  const StoneType(this.label);
  final String label;
}

enum StructuralSoundness {
  operational('Operational / Complete'),
  displayOnly('Display / Missing Components'),
  edgeDulling('Edge Dulling Present'),
  mushrooming('Striking-Head Mushrooming'),
  microFracture('Micro-Fracture Presence'),
  unknown('Condition Unverified');

  const StructuralSoundness(this.label);
  final String label;
}
