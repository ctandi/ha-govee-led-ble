meta:
  id: h6199_pact1_effect_upload
  title: H6199 Pact 1 scene and Studio uploads
  endian: le
  imports:
    - ../govee_shared
doc: |
  SPECULATIVE H6199 Pact 1/1, issue #293. Scene/template controllers use
  A3 kinds 01/02. Studio additionally accepts kind 0A after removing its
  source-format prefix. The common RGBIC layer core is structurally shared;
  the extended tail remains preserved without invented field semantics.
  Studio slots 198/402/403 are distinct from catalogue scene selectors.
  Actual owner upload, activation and rendered semantics are unqualified.
seq:
  - id: header
    contents: [0x01]
  - id: chunk_count
    type: u1
  - id: kind
    type: u1
    enum: body_kind
  - id: content
    size-eos: true
    type:
      switch-on: kind
      cases:
        'body_kind::palette': govee_shared::scene_type1_content
        'body_kind::layered': layer_container(false)
        'body_kind::layered_extended': layer_container(true)
instances:
  studio_selector:
    value: 'kind == body_kind::palette ? studio_slot::palette : (kind == body_kind::layered ? studio_slot::layered : studio_slot::layered_extended)'
enums:
  body_kind:
    0x01: palette
    0x02: layered
    0x0a: layered_extended
  studio_slot:
    198: palette
    402: layered
    403: layered_extended
types:
  layer_container:
    params:
      - id: is_extended
        type: bool
    seq:
      - id: num_records
        type: u1
      - id: records
        type: layer_record(is_extended)
        repeat: expr
        repeat-expr: num_records
      - id: unknown_tail
        size-eos: true
  layer_record:
    params:
      - id: is_extended
        type: bool
    seq:
      - id: len_body
        type: u1
      - id: body
        size: len_body
        type: govee_shared::effect_layer
    instances:
      extension:
        io: body._io
        pos: body._io.size - body.excess.size
        size: body.excess.size
        type: extended_tail
        if: is_extended
  extended_tail:
    seq:
      - id: unknown_prefix
        type: u1
      - id: len_unknown_payload
        type: u1
      - id: unknown_payload
        size: len_unknown_payload
      - id: unknown_suffix
        type: u1
      - id: unknown_tail
        size-eos: true
