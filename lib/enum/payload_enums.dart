enum PayloadClassification {
  barosonde('Barosonde'),
  chronometricRadiosonde('Chronometric Radiosonde'),
  audioModulatedSonde('Audio-Modulated Sonde'),
  radarTargetReflector('Radar Target Reflector'),
  transosondeSystem('Transosonde System');

  const PayloadClassification(this.label);
  final String label;
}

enum PreservationSoundness {
  complete('Complete / Signal path intact'),
  moistureCorrosion('Stratospheric moisture corrosion'),
  impactDistortion('Impact distortion'),
  wiringContinuity('Complete internal wiring continuity'),
  displayOnly('Display specimen / incomplete');

  const PreservationSoundness(this.label);
  final String label;
}

enum AtmosphericLayer {
  troposphere('Troposphere', '0–12 km'),
  tropopause('Tropopause', '8–18 km'),
  stratosphere('Stratosphere', '12–50 km'),
  upperStratosphere('Upper Stratosphere', '35–50 km'),
  nearSpace('Near Space', '50 km+');

  const AtmosphericLayer(this.label, this.range);
  final String label;
  final String range;
}
