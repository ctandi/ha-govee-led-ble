meta:
  id: h6199_pact1_command_write
  title: H6199 Pact 1 command writes
  endian: le
  imports:
    - ../govee_shared
    - h6199_control_payload
doc: |
  SPECULATIVE H6199 Pact 1/1, issue #293. Application producers describe
  register brightness 20..254, static selector 0B and music selector 0C.
  These layouts are not owner-qualified on HW 1.00.01 / FW 1.07.02.
  Native scene selection is separate from uploaded effect activation.
  Unknown tails are preserved; their required write values need captures.
  Video inline brightness has independent identity gates, not implied support.
seq:
  - id: header
    contents: [0x33]
  - id: opcode
    type: u1
    enum: command_op
  - id: body
    size: 17
    type:
      switch-on: opcode
      cases:
        'command_op::power': power_body
        'command_op::brightness': brightness_body
        'command_op::mode': mode_body
        'command_op::strip_direction': h6199_control_payload::write_value
        'command_op::camera_position': h6199_control_payload::write_value
        'command_op::gradient': h6199_control_payload::write_value
  - id: checksum
    type: u1
enums:
  command_op:
    0x01: power
    0x04: brightness
    0x05: mode
    0x30: strip_direction
    0x31: camera_position
    0xa3: gradient
  mode_sel:
    0x00: video
    0x04: scene
    0x0a: diy
    0x0b: static_colour
    0x0c: music
  music_mode:
    0x00: energetic
    0x02: rolling
    0x03: spectrum
    0x05: rhythm
  video_region:
    0x00: part
    0x01: all
  video_source:
    0x00: movie
    0x01: game
types:
  power_body:
    seq:
      - id: is_on
        type: u1
      - id: unknown_tail
        size-eos: true
  brightness_body:
    seq:
      - id: register
        type: u1
      - id: unknown_tail
        size-eos: true
  mode_body:
    seq:
      - id: sub_mode
        type: u1
        enum: mode_sel
      - id: detail
        size: 16
        type:
          switch-on: sub_mode
          cases:
            'mode_sel::static_colour': static_colour_body
            'mode_sel::music': music_body
            'mode_sel::scene': scene_body
            'mode_sel::diy': diy_body
            'mode_sel::video': video_body
  static_colour_body:
    seq:
      - id: rgb
        type: govee_shared::rgb
      - id: kelvin
        type: u2be
      - id: segment_mask
        type: u2le
      - id: unknown_tail
        size-eos: true
  music_body:
    seq:
      - id: mode
        type: u1
        enum: music_mode
      - id: sensitivity
        type: u1
      - id: is_calm
        type: u1
        if: mode == music_mode::rhythm
      - id: has_fixed_colour
        type: u1
        if: mode == music_mode::rhythm or mode == music_mode::rolling or mode == music_mode::spectrum
      - id: fixed_colour
        type: govee_shared::rgb
        if: (mode == music_mode::rhythm or mode == music_mode::rolling or mode == music_mode::spectrum) and has_fixed_colour == 1
      - id: unknown_tail
        size-eos: true
  scene_body:
    seq:
      - id: scene_id
        type: u2le
      - id: unknown_tail
        size-eos: true
  diy_body:
    seq:
      - id: code
        type: u2le
      - id: unknown_tail
        size-eos: true
  video_body:
    seq:
      - id: region
        type: u1
        enum: video_region
      - id: source
        type: u1
        enum: video_source
      - id: saturation
        type: u1
      - id: sound_effects
        type: u1
      - id: softness
        type: u1
      - id: inline_brightness
        type: u1
      - id: unknown_tail
        size-eos: true
