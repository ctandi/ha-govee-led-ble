meta:
  id: h6125_wire_write
  title: Govee H6125 speculative wire writes that differ from the shared logical frames
  endian: le
  imports:
    - ../govee_shared
doc: |
  SPECULATIVE H6125, issue #117.
  Evidence source class: reachable Android 7.6.01 producer code; no official-app
  BLE capture of an identified H6125 is available.
  Compatibility hypothesis: pact 1 firmware 1.07.00 or newer uses the shared
  H617A logical frames for everything except two registers.  The brightness byte
  is a device register on a scaled range, and the music selector uses submode
  0x11 with its own effect numbering.  dreamcolorlightv1/pact/Support.getBrightnessRange,
  base2light/util/NumUtil.calculateProgress and BrightnessController.q give the
  register write; dreamcolorlightv1/ble/SubModeMusicV2.getWriteBytes gives the
  music selector.  The semantic builders in the adapter derive both frames from the
  shared logical H617A frames, so this schema owns only the wire layout.
  Unresolved assumptions: the register range for each hardware revision, whether
  later firmware still accepts submode 0x13, unused bytes of every frame, and
  whether the device echoes these writes.  The final byte is the XOR of bytes 0
  through 18.
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
        'command_op::brightness': brightness_body
        'command_op::mode': mode_body
  - id: checksum
    type: u1
enums:
  command_op:
    0x04: brightness
    0x05: mode
  mode_sub:
    0x11: music
  music_mode:
    0x10: energetic
    0x11: rhythm
    0x12: spectrum
    0x13: rolling
    0x30: bloom
    0x31: shiny
    0x32: separation
    0x33: hopping
    0x34: piano_keys
    0x35: fountain
    0x37: day_and_night
types:
  brightness_body:
    seq:
      - id: register
        type: u1
      - id: padding
        size-eos: true
  mode_body:
    seq:
      - id: sub
        type: u1
        enum: mode_sub
      - id: sub_body
        size: 16
        type:
          switch-on: sub
          cases:
            'mode_sub::music': music_selector
  music_selector:
    seq:
      - id: mode_id
        type: u1
        enum: music_mode
      - id: sensitivity
        type: u1
      - id: settings
        size: 14
        type:
          switch-on: mode_id
          cases:
            'music_mode::rhythm': rhythm_settings
            'music_mode::spectrum': colour_settings
            'music_mode::rolling': colour_settings
            _: opaque_settings
  rhythm_settings:
    seq:
      - id: style
        doc: Zero is Dynamic and nonzero is Calm.
        type: u1
      - id: has_fixed_colour
        type: u1
      - id: rgb
        type: govee_shared::rgb
        if: has_fixed_colour != 0
      - id: padding
        size-eos: true
  colour_settings:
    seq:
      - id: has_fixed_colour
        type: u1
      - id: rgb
        type: govee_shared::rgb
        if: has_fixed_colour != 0
      - id: padding
        size-eos: true
  opaque_settings:
    seq:
      - id: padding
        size-eos: true
