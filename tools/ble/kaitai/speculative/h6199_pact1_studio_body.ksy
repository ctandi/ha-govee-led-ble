meta:
  id: h6199_pact1_studio_body
  title: H6199 Pact 1 retained RGBIC Studio source body
  endian: le
  imports:
    - h6199_pact1_effect_upload
doc: |
  SPECULATIVE H6199 Pact 1/1, issue #293. The application tries the
  unprefixed RGBIC source layout before its extended alternative. For
  extended Studio, one source byte precedes the layer count and is removed
  by the kind-0A controller. Its value and extended fields stay opaque.
  This is not arbitrary application-effect import or physical qualification.
params:
  - id: is_extended
    type: bool
seq:
  - id: source_prefix
    type: u1
    if: is_extended
  - id: content
    type: h6199_pact1_effect_upload::layer_container(is_extended)
