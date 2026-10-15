meta:
  id: h6199_pact1_dreamview_frame
  title: H6199 original DreamView commands and individual reads
  endian: be
doc: |
  SPECULATIVE H6199 Pact 1/1, issue #293. Original group controllers use
  direct command envelopes, unlike MovieFeastV2's module-60 envelopes.
  Same-brightness alone uses module 60, command 04, through the shared
  feast controller. Replacement uses A3 type 50 and the shared membership
  record layout; it is not membership readback. Product capacity is five.
  Read slot arrays remain fixed raw bytes, without authored identity mapping.
  Query and write tails, slot occupancy, timing, group restoration and exact
  owner revision compatibility remain unqualified. This root is not an ACK
  parser, and does not authorise deletion or replacement.
params:
  - id: is_query
    type: bool
seq:
  - id: header
    type: u1
    enum: header
  - id: command
    type: u1
    enum: command
  - id: module
    contents: [0x04]
    if: command == command::same_brightness
  - id: body
    size: body_size
    type:
      switch-on: 'is_query ? 0 : header.to_i'
      cases:
        0: query_body
        0x33: write_body
        0xaa: status_body
  - id: checksum
    type: u1
instances:
  body_size:
    value: 'command == command::same_brightness ? 16 : 17'
  module_value:
    value: 0x04
  discriminator_size:
    value: 0
types:
  query_body:
    seq:
      - id: unknown
        size-eos: true
  write_body:
    seq:
      - id: enabled
        type: u1
        if: _root.command == command::switch_group or _root.command == command::same_brightness or _root.command == command::sound
      - id: level
        type: u1
        if: _root.command == command::member_brightness
      - id: index
        type: u1
        if: _root.command == command::member_brightness or _root.command == command::member_connect
      - id: connected
        type: u1
        if: _root.command == command::member_connect
      - id: saturation
        type: u1
        if: _root.command == command::saturation
      - id: sample_first
        type: u1
        if: _root.command == command::sample
      - id: sample_second
        type: u1
        if: _root.command == command::sample
      - id: softness
        type: u1
        if: _root.command == command::sound
      - id: unknown
        size-eos: true
  status_body:
    seq:
      - id: enabled
        type: u1
        if: _root.command == command::switch_group or _root.command == command::same_brightness or _root.command == command::sound
      - id: brightness_bytes
        size: 17
        if: _root.command == command::member_brightness
      - id: connection_bytes
        size: 10
        if: _root.command == command::member_connect
      - id: saturation
        type: u1
        if: _root.command == command::saturation
      - id: sample_first
        type: u1
        if: _root.command == command::sample
      - id: sample_second
        type: u1
        if: _root.command == command::sample
      - id: softness
        type: u1
        if: _root.command == command::sound
      - id: unknown
        size-eos: true
enums:
  header:
    0x33: write
    0xaa: read
  command:
    0x43: member_connect
    0x50: member_brightness
    0x51: saturation
    0x52: sample
    0x53: sound
    0x54: switch_group
    0x56: delete_group
    0x60: same_brightness
