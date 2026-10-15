meta:
  id: h6199_pact1_status_reply
  title: H6199 Pact 1 status replies
  endian: le
  imports:
    - h6199_pact1_command_write
    - ../govee_shared
    - h6199_control_payload
doc: |
  SPECULATIVE H6199 Pact 1/1, issue #293. Application parsers describe
  register brightness, mode-dependent music and RGB-only A2 segment pages.
  No attributable owner exchange qualifies these layouts or final-page tails.
  Fifteen logical segments occupy four groups. Only the first three RGB
  records of the last group represent segments; remaining bytes stay opaque.
  Static mode replies do not establish RGB, Kelvin or segment brightness.
  Unknown selectors and tails remain bytes rather than invented observations.
seq:
  - id: header
    contents: [0xaa]
  - id: domain
    type: u1
    enum: status_domain
  - id: body
    size: 17
    type:
      switch-on: domain
      cases:
        'status_domain::power': h6199_pact1_command_write::power_body
        'status_domain::brightness': h6199_pact1_command_write::brightness_body
        'status_domain::colour_mode': colour_mode_body
        'status_domain::firmware': version_body
        'status_domain::hardware': hardware_version_body
        'status_domain::subordinate_20': version_body
        'status_domain::subordinate_21': version_body
        'status_domain::segments': segment_body
        'status_domain::strip_direction': h6199_control_payload::write_value
        'status_domain::camera_position': h6199_control_payload::write_value
        'status_domain::camera_status': h6199_control_payload::camera_state
        'status_domain::gradient': h6199_control_payload::write_value
  - id: checksum
    type: u1
enums:
  status_domain:
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
  mode_sel:
    0x00: video
    0x04: scene
    0x0a: diy
    0x0b: static_colour
    0x0c: music
types:
  colour_mode_body:
    seq:
      - id: mode
        type: u1
        enum: mode_sel
      - id: detail
        size: 16
        type:
          switch-on: mode
          cases:
            'mode_sel::music': h6199_pact1_command_write::music_body
            'mode_sel::scene': h6199_pact1_command_write::scene_body
            'mode_sel::diy': h6199_pact1_command_write::diy_body
            'mode_sel::video': h6199_pact1_command_write::video_body
            'mode_sel::static_colour': static_status_body
  static_status_body:
    doc: |
      Current application parsing reads Kelvin after the gradient flag.
      The legacy compatibility parser ignores those bytes. Preserve the
      candidate value without granting a fresh Kelvin observation.
    seq:
      - id: gradient
        type: u1
      - id: kelvin_candidate
        type: u2be
      - id: unknown_tail
        size-eos: true
  segment_body:
    seq:
      - id: group
        type: u1
        valid:
          min: 1
          max: 4
      - id: segments
        type: segment_record
        repeat: expr
        repeat-expr: num_segments
      - id: unknown_tail
        size-eos: true
    instances:
      num_segments:
        value: 'group == 4 ? 3 : 4'
      has_brightness:
        value: false
  segment_record:
    seq:
      - id: colour
        type: govee_shared::rgb
  version_body:
    seq:
      - id: text
        type: strz
        encoding: ASCII
      - id: unknown_tail
        size-eos: true
  hardware_version_body:
    seq:
      - id: prefix
        contents: [0x03]
      - id: text
        type: strz
        encoding: ASCII
      - id: unknown_tail
        size-eos: true
