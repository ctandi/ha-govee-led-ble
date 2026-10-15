meta:
  id: h6199_pact1_status_query
  title: H6199 Pact 1 status queries
  endian: le
doc: |
  SPECULATIVE H6199 Pact 1/1, issue #293. The legacy application requests
  RGB-only segment groups through A2, not the newer A5 brightness/RGB pages.
  Basic and identity query forms follow shared application controllers.
  Exact owner query/response exchanges remain outstanding. No AA14 startup
  requirement is inferred. Installation controls remain independently declared.
seq:
  - id: header
    contents: [0xaa]
  - id: domain
    type: u1
    enum: query_domain
  - id: body
    size: 17
    type:
      switch-on: domain
      cases:
        'query_domain::power': zero_body
        'query_domain::brightness': zero_body
        'query_domain::colour_mode': colour_mode_query_body
        'query_domain::firmware': zero_body
        'query_domain::hardware': hardware_query_body
        'query_domain::subordinate_20': zero_body
        'query_domain::subordinate_21': zero_body
        'query_domain::segments': segment_query_body
        'query_domain::strip_direction': zero_body
        'query_domain::camera_position': zero_body
        'query_domain::camera_status': zero_body
        'query_domain::gradient': zero_body
  - id: checksum
    type: u1
enums:
  query_domain:
    0x01: power
    0x04: brightness
    0x05: colour_mode
    0x06: firmware
    0x07: hardware
    0x20: subordinate_20
    0x21: subordinate_21
    0xa2: segments
    0x30: strip_direction
    0x31: camera_position
    0x32: camera_status
    0xa3: gradient
types:
  colour_mode_query_body:
    seq:
      - id: selector
        contents: [0x01]
      - id: zeros
        type: u1
        valid: 0
        repeat: eos
  zero_body:
    seq:
      - id: zeros
        type: u1
        valid: 0
        repeat: eos
  hardware_query_body:
    seq:
      - id: selector
        contents: [0x03]
      - id: zeros
        type: u1
        valid: 0
        repeat: eos
  segment_query_body:
    seq:
      - id: group
        type: u1
        valid:
          min: 1
          max: 4
      - id: zeros
        type: u1
        valid: 0
        repeat: eos
